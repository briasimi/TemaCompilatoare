%{
#include <stdio.h>
     #include <string.h>

	extern int yylex(); //returneaza numele unui atom lexical
	int yyerror(const char *msg);

        int read_write=0;
     	int EsteCorecta = 0;
	char msg[500];
class TVAR
	{
	     char* nume;
	     int valoare;
	     TVAR* next;
	  
	  public:
	     static TVAR* head;
	     static TVAR* tail;

	     TVAR(char* n, int v = -1);
	     TVAR();
	     int exists(char* n);
             void add(char* n, int v = -1);
             int getValue(char* n);
	     void setValue(char* n, int v);
	};

	TVAR* TVAR::head;
	TVAR* TVAR::tail;

	TVAR::TVAR(char* n, int v)
	{
	 this->nume = new char[strlen(n)+1];
	 strcpy(this->nume,n);
	 this->valoare = v;
	 this->next = NULL;
	}

	TVAR::TVAR()
	{
	  TVAR::head = NULL;
	  TVAR::tail = NULL;
	}

	int TVAR::exists(char* n)
	{
	  TVAR* tmp = TVAR::head;
	  while(tmp != NULL)
	  {
	    if(strcmp(tmp->nume,n) == 0)
	      return 1;
            tmp = tmp->next;
	  }
	  return 0;
	 }

         void TVAR::add(char* n, int v)
	 {
	   TVAR* elem = new TVAR(n, v);
	   if(head == NULL)
	   {
	     TVAR::head = TVAR::tail = elem;
	   }
	   else
	   {
	     TVAR::tail->next = elem;
	     TVAR::tail = elem;
	   }
	 }

         int TVAR::getValue(char* n)
	 {
	   TVAR* tmp = TVAR::head;
	   while(tmp != NULL)
	   {
	     if(strcmp(tmp->nume,n) == 0)
	      return tmp->valoare;
	     tmp = tmp->next;
	   }
	   return -1;
	  }

	  void TVAR::setValue(char* n, int v)
	  {
	    TVAR* tmp = TVAR::head;
	    while(tmp != NULL)
	    {
	      if(strcmp(tmp->nume,n) == 0)
	      {
		tmp->valoare = v;
	      }
	      tmp = tmp->next;
	    }
	  }

	TVAR* ts = NULL;
%}
%union { char* sir; int val; } //pentru variabila yylval
    
%token TOK_PROGRAM TOK_VAR TOK_BEGIN TOK_END TOK_INTEGER TOK_DIV TOK_READ TOK_WRITE TOK_FOR TOK_DO TOK_TO
%token TOK_PLUS TOK_MINUS TOK_MULTIPLY TOK_ERROR TOK_LEFT TOK_RIGHT TOK_ATRIB

%token <sir> TOK_IDENTIFIER
%token <val> TOK_INT

%type<sir> idList
%type<val> EXP TERM FACTOR

%start P

%left TOK_PLUS TOK_MINUS
%left TOK_MULTIPLY TOK_DIV //precedenta si asociativitatea

%%

P : TOK_PROGRAM pName TOK_VAR DECLIST TOK_BEGIN SL TOK_END { EsteCorecta = 1; };
  
pName : TOK_IDENTIFIER;

DECLIST : D
     |
     DECLIST ';' D;

D : idList ':' type;

type : TOK_INTEGER;

idList :  idList ',' TOK_IDENTIFIER
{      
		if (ts != NULL)
	{
		if (ts->exists($3) == 0)
		{
			ts->add($3);
		}
		else if(ts->exists($1) ==1 && read_write==0)
		{
		  sprintf(msg, "%d:%d Eroare semantica: Variabila %s a mai fost declarata!", @1.first_line, @1.first_column, $3);
			yyerror(msg);
			YYERROR;
		}
	}
	else
	{
		ts = new TVAR();
		ts->add($3);
	}
}
	|
        TOK_IDENTIFIER
{
	if (ts != NULL)
	{
		if (ts->exists($1) == 0)
		{
			ts->add($1);
		}
		else if(ts->exists($1) ==1 && read_write==0)
		{
		  sprintf(msg, "%d:%d Eroare semantica: Variabila %s a mai fost declarata !", @1.first_line, @1.first_column, $1);
			yyerror(msg);
			YYERROR;
		}
	}
	else
	{
		ts = new TVAR();
		ts->add($1);
	}




};
	
SL : S
     |
     SL ';' S;
S : Assign	
    |
    Read
    |
    Write
    |
    For;
Assign : TOK_IDENTIFIER TOK_ATRIB EXP
{
	  if(ts != NULL)
	{
	  if(ts->exists($1)==1)
	  {
	    ts->setValue($1, $3);
	  }
	  else
	  {
	    sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $1);
	    yyerror(msg);
	    YYERROR;
	  }
	}
	
 };
EXP : TERM 
       |
      EXP TOK_PLUS TERM
       |
      EXP TOK_MINUS TERM;
TERM : FACTOR
       |
       TERM TOK_MULTIPLY FACTOR
       |
       TERM TOK_DIV FACTOR
{
 	if($3 == 0) 
	  { 
 sprintf(msg,"%d:%d Eroare semantica:Avem destule probleme in universul nostru nu mai avem nevoie de altul!", @1.first_line, @1.first_column);
	      yyerror(msg);
	      YYERROR;
	  } 
};
FACTOR : TOK_IDENTIFIER
 {      
              if(ts != NULL)
		{
	        if(ts->exists($1) ==1)
		{
			     if(ts->getValue($1) == -1)
	               		{
	      sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost initializata!", @1.first_line, @1.first_column, $1);
	      yyerror(msg);
	      YYERROR;
	              		 }
		}
			  else
			  {
              sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $1);
	    yyerror(msg);
	    YYERROR;  
			  }
		}
}
          |
        TOK_INT
          |
       TOK_LEFT EXP TOK_RIGHT;
Read : TOK_READ TOK_LEFT{read_write=1;} idList TOK_RIGHT{read_write=0;}
{

  
		if(ts!=NULL)
		{
 			if( ts->exists($4)==0)
			{
				
	sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $4);
	    yyerror(msg);
	    YYERROR;  
			}
			
		}
	
};
Write : TOK_WRITE TOK_LEFT{read_write=1;} idList TOK_RIGHT{read_write=0;}
{

  
	
		if(ts!=NULL)
		{
 			if( ts->exists($4)==0)
			{
				
	sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", @1.first_line, @1.first_column, $4);
	    yyerror(msg);
	    YYERROR;  
			}
			
		}
	
    
};
For : TOK_FOR IEXP TOK_DO Body;

IEXP : TOK_IDENTIFIER TOK_ATRIB EXP TOK_TO EXP;

Body : S
       |
      TOK_BEGIN SL TOK_END;

%%



int yyerror(const char *msg)
{
	printf("Error: %s\n", msg);
	return 1;
}

int main()
{




	yyparse();
	if(EsteCorecta == 1)
	{
		printf("\nCORECTA\n");		
	}
	else
	{
		printf("\nGRESITA\n");		
	}
	
       return 0;
}










