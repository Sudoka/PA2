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


%}

/*
 * Define names for regular expressions here.
 */

COMMENT_START   "(*"
COMMENT_END     "*)"


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

DOT             "."
AT              "@"
TILD            "~"
ISVOID          [iI][sS][vV][oO][iI][dD]
MULTIDIVIDE     "*"|"/"
PLUSMINUS       "+"|"-"
LESSEQUAL       "<="|"<"|"="
NOT             [nN][oO][tT]
ASSIGN          <-

DARROW          =>

DIGIT           [0-9]
OBJECTID        [a-z][a-zA-Z0-9_]*
TYPEID          [A-Z][a-zA-Z0-9_]*
WHITESPACE      [ \f\r\t\v]+

STRING          \"[^\b\t\n\f]+\"

%%

 /*
  *  Nested comments
  */

--.*--      printf("comment\n");

{COMMENT_START} printf("comment start\n");

{COMMENT_END}   printf("comment start\n");

 /*
  *  The multiple-character operators.
  */

{DARROW}		{ return (DARROW); }
{ASSIGN}        { return (ASSIGN); }


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}         { return (CLASS); }
{ELSE}          { return (ELSE); }
{FI}            { return (FI); }
{IF}            { return (IF); }
{IN}            { return (IN); }
{INHERITS}      { return (INHERITS); }
{ISVOID}        { return (ISVOID); }
{LET}           { return (LET); }
{LOOP}          { return (LOOP); }
{POOL}          { return (POOL); }
{THEN}          { return (THEN); }
{WHILE}         { return (WHILE); }
{CASE}          { return (CASE); }
{ESAC}          { return (ESAC); }
{NEW}           { return (NEW); }
{OF}            { return (OF); }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

{STRING}        {
                    printf("A string: %s\n", yytext);
                    cool_yylval.symbol = stringtable.add_string(yytext);
                    return STR_CONST;
                }

{DIGIT}+        {
                    printf("An integer: %s (%d)\n", yytext, atoi(yytext));
                    cool_yylval.symbol = inttable.add_string(yytext);
                    return INT_CONST;
                }

{OBJECTID}      printf("An identifier: %s\n", yytext);

{TYPEID}        printf("An identifier: %s\n", yytext);

\n              ++curr_lineno;

{WHITESPACE}    /* whitespace */

.               printf("Unrecognized character: %s\n", yytext);



%%
