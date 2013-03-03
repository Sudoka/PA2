/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

/* to determine if we have handled the eof state or not */
bool eof_state = false;
bool nullchar = false;
int string_len = 0;
int comment_level = 0;


%}

/*
 * Define names for regular expressions here.
 */


CLASS           [cC][lL][aA][sS][sS]
ELSE            [eE][lL][sS][eE]
FI              [fF][iI]
IF              [iI][fF]
IN              [iI][nN]
INHERITS        [iI][nN][hH][eE][rR][iI][tT][sS]
LET             [lL][eE][tT]
LOOP            [lL][oO][oO][pP]
POOL            [pP][oO][oO][lL]
THEN            [tT][hH][eE][nN]
WHILE           [wW][hH][iI][lL][eE]
CASE            [cC][aA][sS][eE]
ESAC            [eE][sS][aA][cC]
OF              [oO][fF]
NEW             [nN][eE][wW]

FALSE           f[aA][lL][sS][eE]
TRUE            t[rR][uU][eE]

ISVOID          [iI][sS][vV][oO][iI][dD]
NOT             [nN][oO][tT]

DIGIT           [0-9]
OBJECTID        [a-z][a-zA-Z0-9_]*
TYPEID          [A-Z][a-zA-Z0-9_]*
WHITESPACE      [ \f\r\t\v]+

%x comment
%x str

%%

 /*
  *  Nested comments
  */

--.*                                /* one line comment */

"(*"                                {
                                        BEGIN(comment);
                                        ++comment_level;
                                    }
<comment>"(*"                       {
                                        ++comment_level;
                                        /* printf("start:%s, comment: %d\n", yytext, comment_level); */
                                    }
<comment>\\.                        /* printf("1:%s\n", yytext); */
<comment>[(\\]                      /* printf("2:%s\n", yytext); */
<comment>[^*\n(\\]*                 /* printf("3:%s\n", yytext); */
<comment>"*"+[^*)\n\\*]*            /* printf("4:%s\n", yytext); */
<comment>\n                         ++curr_lineno;
<comment><<EOF>>                    {
                                        if ( !eof_state ) {
                                            eof_state = true;
                                            cool_yylval.error_msg = "EOF in comment";
                                            return (ERROR);
                                        }
                                        else {
                                            yyterminate();
                                        }
                                    }
<comment>"*"+")"                    {   
                                        --comment_level;
                                        /* printf("comment: %d\n", comment_level); */
                                        if ( comment_level == 0 )
                                            BEGIN(INITIAL);
                                    }
"*)"                                {
                                        /* error handling */
                                        cool_yylval.error_msg = "Unmatched *)";
                                        return (ERROR);
                                    }

 /*
  *  The multiple-character operators.
  */

"=>"	                    { return (DARROW); }
";"                         { return ';'; }
"{"                         { return '{'; }
"}"                         { return '}'; }
","                         { return ','; }
":"                         { return ':'; }
"("                         { return '('; }
")"                         { return ')'; }
"."                         { return '.'; }
"@"                         { return '@'; }
"~"                         { return '~'; }
{ISVOID}                    { return (ISVOID); }
"*"                         { return '*'; }
"/"                         { return '/'; }
"+"                         { return '+'; }
"-"                         { return '-'; }
"<="                        { return (LE); }
"<"                         { return '<'; }
"="                         { return '='; }
{NOT}                       { return (NOT); }
"<-"                        { return (ASSIGN); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}                     { return (CLASS); }
{ELSE}                      { return (ELSE); }
{FI}                        { return (FI); }
{IF}                        { return (IF); }
{IN}                        { return (IN); }
{INHERITS}                  { return (INHERITS); }
{LET}                       { return (LET); }
{LOOP}                      { return (LOOP); }
{POOL}                      { return (POOL); }
{THEN}                      { return (THEN); }
{WHILE}                     { return (WHILE); }
{CASE}                      { return (CASE); }
{ESAC}                      { return (ESAC); }
{NEW}                       { return (NEW); }
{OF}                        { return (OF); }

{TRUE}                      {
                                cool_yylval.boolean = true;
                                return (BOOL_CONST);
                            }

{FALSE}                     {
                                cool_yylval.boolean = false;
                                return (BOOL_CONST);
                            }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\"                          {
                                /* string starts */
                                string_buf_ptr = string_buf;
                                string_len = 0;
                                nullchar = false;
                                BEGIN(str);
                            }

<str>\"                     {
                                /* string ends */
                                BEGIN(INITIAL);
                                if ( nullchar ) {
                                    cool_yylval.error_msg = "String contains null character";
                                    return (ERROR);
                                }
                                else if ( string_len < MAX_STR_CONST ) {
                                    *string_buf_ptr = '\0';
                                    cool_yylval.symbol = stringtable.add_string(string_buf);
                                    return (STR_CONST);
                                }
                                else {
                                    cool_yylval.error_msg = "String constant too long";
                                    return (ERROR);
                                }
                            }

<str>\0                     nullchar = true; /* printf("1 current char: %c, %d\n", *yytext, *yytext); */
<str>\\b                    if ( ++string_len < MAX_STR_CONST ) *string_buf_ptr++ = '\b'; /*printf("2 current char: %c, %d\n", *yytext, *yytext); */
<str>\\t                    if ( ++string_len < MAX_STR_CONST ) *string_buf_ptr++ = '\t'; /*printf("3 current char: %c, %d\n", *yytext, *yytext); */
<str>\\n                    if ( ++string_len < MAX_STR_CONST ) *string_buf_ptr++ = '\n'; /*printf("4 current char: %c, %d\n", *yytext, *yytext); */
<str>\\f                    if ( ++string_len < MAX_STR_CONST ) *string_buf_ptr++ = '\f'; /*printf("5 current char: %c, %d\n", *yytext, *yytext); */
<str>\\.                    {
                                /*printf("6 current char: %c, %x\n", *yytext, *yytext); */
                                if ( *(yytext+1) == '\0' )
                                    nullchar = true;
                                else if ( ++string_len < MAX_STR_CONST ) 
                                    *string_buf_ptr++ = *(yytext+1); 
                            }


<str>\\[^\\\n\"]+$          {
                                /*printf("a: %s\n", yytext);*/
                                BEGIN(INITIAL);
                                cool_yylval.error_msg = "Unterminated string constant";
                                return (ERROR);
                            }

<str>\n                     {
                                /*printf("b: %s\n", yytext);*/
                                BEGIN(INITIAL);
                                ++curr_lineno;
                                cool_yylval.error_msg = "Unterminated string constant";
                                return (ERROR);
                            }

<str>\\\n                   {
                                if ( ++string_len < MAX_STR_CONST )
                                    *string_buf_ptr++ = '\n';
                                ++curr_lineno;
                            }

<str>[^\0\\\n\"]+           {
                                char* ptr = yytext;
                                while (*ptr) {
                                    /* printf("current char: %c, %x\n", *ptr, *ptr); */
                                    if ( ++string_len < MAX_STR_CONST )
                                        *string_buf_ptr++ = *ptr++;
                                    else
                                        *ptr++;
                                }
                            }

<str><<EOF>>                {
                                if ( !eof_state ) {
                                    eof_state = true;
                                    cool_yylval.error_msg = "Unterminated string constant";
                                    /*cool_yylval.error_msg = "EOF in string constant";*/
                                    return (ERROR);
                                }
                                else {
                                    yyterminate();
                                }
                            }

 /*
  * Others
  *
  */

{DIGIT}+                    {
                                cool_yylval.symbol = inttable.add_string(yytext);
                                return (INT_CONST);
                            }
                            
{OBJECTID}                  {
                                cool_yylval.symbol = idtable.add_string(yytext);
                                return (OBJECTID);
                            }
                            
{TYPEID}                    {
                                cool_yylval.symbol = idtable.add_string(yytext);
                                return (TYPEID);
                            }
                            
\n                          ++curr_lineno;
                            
{WHITESPACE}                /* whitespace */
                            
.                           {
                                cool_yylval.error_msg = yytext;
                                return (ERROR);
                            }


%%
