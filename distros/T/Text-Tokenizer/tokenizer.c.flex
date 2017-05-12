/***************************************************************************
 *   Simple text tokenizer (flex based)					   *
 *   Features:								   *
 *  	- parses text to tokens taking mind on quotes & escape characters  *
 *	- specialy developed for config files reading			   *
 *	- escaped quotes inside quotes are auto-unescaped (can be disabled)*
 *	- `' quotation strings optional support (as subtype of `` strings) *
 *	- DOS/UNIX/MAC end of lines support				   *
 *	- enhanced error reporting					   *
 *	- very fast ?-)							   *
 *	- internal line count (for multiple buffers)			   *
 *	- bash style comments (can be disabled)				   *
 *	- optional C/C++ style comments					   *
 *	- avaible one generic & one configurable interface for in-memory   *
 *		tokens storage						   *
 *	- bad call (segfault) prevention				   *
 *									   *
 *   Copyright (C) 2001-2011 by Samuel Behan (http://devel.dob.sk)         *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

%{

#include <stdio.h>
#include <stdlib.h>

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <tokenizer.h>

/*
 * definitions -- max abstraction level
 */

/*buffer handlings*/
#ifdef HAVE_CALLBACK_BUFFER

/* #warning BUFFER: using callback */
/*buffer*/
static struct tok_buffer *tok_text	= NULL;
#define TOKEN_TEXT		tok_text
#define BUFFER_DECLARE(buf)	struct tok_buffer *(buf)	= NULL
#define BUFFER_READY(buf)	((buf) != NULL)
#define BUFFER_NEW(buf)		buf = TOKEN_TEXT->ts_new(TOKEN_TEXT->ts_context)
#define BUFFER_CLEAR(buf)	TOKEN_TEXT->ts_clear(TOKEN_TEXT->ts_context, (buf))
#define BUFFER_PUT(buf,str,len) TOKEN_TEXT->ts_put(TOKEN_TEXT->ts_context ,(buf), (str), (len))
#define BUFFER_GET(buf)		(buf)
#define BUFFER_DESTROY(buf)	TOKEN_TEXT->ts_del(TOKEN_TEXT->ts_context ,(buf))

#endif

#if (defined(HAVE_LTEXT_BUFFER) && !defined(BUFFER_DECLARE)) || !defined(BUFFER_DECLARE)

/* #warning BUFFER: using ltext (dynamicaly realloced text buffer) */
#include <ltext.h>
#define BUFFER_DECLARE(buf)	LText *(buf)	= NULL
#define BUFFER_READY(buf)	((buf) != NULL)
#define BUFFER_NEW(buf)		buf = ltextnew()
#define BUFFER_CLEAR(buf)	ltextclear((buf))
#define BUFFER_PUT(buf,str,len) ltextput((buf), (str), (len))
#define BUFFER_GET(buf)		ltextget((buf))
#define BUFFER_DESTROY(buf)	ltextdestroy((buf))

#endif

#ifndef BUFFER_DECLARE
#error Missing buffer handling functions...
#endif

/*line count & errors*/
#define ERROR_GET()		error_type
#define ERROR_SET(s)		error_type = s
#define ERROR_LINE()		error_line = curr_line
#define ERROR_LINE_SET(s)	error_line = s
#define ERROR_LINE_GET()	error_line
#define LINE_GET()		curr_line
#define LINE_SET(s)		curr_line  = s
#define LINE_INC()		curr_line++

/*tokenizing*/
#define TOKEN_BEGIN(con, buf)	{	\
			BEGIN((con));	\
			ERROR_LINE();	\
			BUFFER_CLEAR((buf));	}
#define TOKEN_RETURNS(tok)	{	\
			BEGIN(INITIAL); \
			ERROR_LINE_SET(0);	\
			return (tok);		}
#define TOKEN_RETURN(tok)	\
			return (tok);
#define	TOKEN_LOOSE(buf)	{	\
			BUFFER_CLEAR((buf));	\
			BEGIN(INITIAL);		\
			ERROR_LINE_SET(0);	}
#define TOKEN_ERROR(q)		{	\
			ERROR_SET((q));	\
			return TOK_ERROR;	}

/*flex definitions*/
#define YY_DECL	static tok_type yylex( void )

/*global  variables*/
static BUFFER_DECLARE(buffer);
static tok_line  curr_line	= 1;			/*line position*/
static tok_line  error_line	= 0;			/*error line number*/
static tok_error error_type	= NOERR;		/*only used on TOK_ERROR*/
static int 	 token_opts	= TOK_OPT_DEFAULT;	/*tokenizer options*/
static tok_id	 tokid_counter	= 1;			/*tokenizer counter*/

%}

/*identificators (flex always matches biggest chunk it can)*/
BLANK		[[:blank:]]
TEXT		([^\t\n\r\"\'\`[:blank:]#\/]|\\(\"|\'|\`)|\/)
EOL		([\r\n]|\r\n)

/*options*/
%option prefix="tokenizer_yy"
%option noyywrap
%option 8bit
%option full
%option align

/*conditions (exclusive)*/
%x d_quote
%x s_quote
%x i_quote
%x bash_comment
%x c_comment
%x cc_comment

%%
	/* -- prepare text buffer -- */
	if(!BUFFER_READY(buffer))
		BUFFER_NEW(buffer);
	BUFFER_CLEAR(buffer);

	/* -- double quoted text -- */
\"	TOKEN_BEGIN(d_quote, buffer);
<d_quote>{
	\"									TOKEN_RETURNS(TOK_DQUOTE);
	[^\\\n\"]+			BUFFER_PUT(buffer, yytext, yyleng);
	\\\"				BUFFER_PUT(buffer, yytext + (!(token_opts & TOK_OPT_NOUNESCAPE) ? 1 : 0), (!(token_opts & TOK_OPT_NOUNESCAPE) ? 1 : yyleng ));
	\\.				BUFFER_PUT(buffer, yytext + ((token_opts & TOK_OPT_UNESCAPE_CHARS) ? 1 : 0), ((token_opts & TOK_OPT_UNESCAPE_CHARS) ? 1 : yyleng ));
	<<EOF>>									TOKEN_ERROR(UNCLOSED_DQUOTE);
}

	/* -- simple quoted text -- */
\'	TOKEN_BEGIN(s_quote, buffer);
<s_quote>{
	\'									TOKEN_RETURNS(TOK_SQUOTE);
	[^\\\n\']+			BUFFER_PUT(buffer, yytext, yyleng);
	\\\'				BUFFER_PUT(buffer, yytext + (!(token_opts & TOK_OPT_NOUNESCAPE) ? 1 : 0), (!(token_opts & TOK_OPT_NOUNESCAPE) ? 1 : yyleng ));
	\\.				BUFFER_PUT(buffer, yytext, yyleng);
	<<EOF>>									TOKEN_ERROR(UNCLOSED_SQUOTE);
}

	/* -- inverse quoted text -- */
\`	{  if(!(token_opts & TOK_OPT_NO_IQUOTE))
	   {	TOKEN_BEGIN(i_quote, buffer);		}
	   else
	   {	BUFFER_PUT(buffer, yytext, yyleng);	}	}
<i_quote>{
	\`									TOKEN_RETURNS(TOK_IQUOTE);
	[^\\\n\`\']+			BUFFER_PUT(buffer, yytext, yyleng);
	\'		{	if(token_opts & TOK_OPT_SIQUOTE)
				{						TOKEN_RETURNS(TOK_SIQUOTE);	}
				else
				{	BUFFER_PUT(buffer, yytext, yyleng);					}	}
	\\\`				BUFFER_PUT(buffer, yytext + (!(token_opts & TOK_OPT_NOUNESCAPE) ? 1 : 0), (!(token_opts & TOK_OPT_NOUNESCAPE) ? 1 : yyleng ));
	\\.				BUFFER_PUT(buffer, yytext, yyleng);
	<<EOF>>									TOKEN_ERROR(UNCLOSED_IQUOTE);
}

	/* -- shared rules -- */
<d_quote,s_quote,i_quote>{
	\\{EOL}		LINE_INC();	if(!(token_opts & TOK_OPT_UNESCAPE_LINES))	BUFFER_PUT(buffer, yytext, yyleng);
	{EOL}		LINE_INC();	BUFFER_PUT(buffer, yytext, 1);
}

	/* -- BASH comment -- */
#	{  if(!(token_opts & TOK_OPT_NO_BASH_COMMENT))
	   {	TOKEN_BEGIN(bash_comment, buffer);	}
	   else
	   {	BUFFER_PUT(buffer, yytext, yyleng);	}	}
<bash_comment>{
	[^\r\n]+			BUFFER_PUT(buffer, yytext, yyleng);
	{EOL}		{ LINE_INC();	BUFFER_PUT(buffer, yytext, yyleng);
					if(token_opts & TOK_OPT_PASS_COMMENT)
					{					TOKEN_RETURNS(TOK_BASH_COMMENT);	}
					else
					{					TOKEN_LOOSE(buffer);		}	}
}

	/* -- C comment -- */
\/\*	{  if(token_opts & TOK_OPT_CC_COMMENT)
	   {	TOKEN_BEGIN(c_comment, buffer);		}
	   else
	   {	BUFFER_PUT(buffer, yytext, yyleng);	}	}
<c_comment>{
	{EOL}		LINE_INC();	BUFFER_PUT(buffer, yytext, yyleng);
	\*\/				{  if(token_opts & TOK_OPT_PASS_COMMENT)
					   {					TOKEN_RETURNS(TOK_C_COMMENT);	}
					   else
					   {					TOKEN_LOOSE(buffer);	}	}
	[^\r\n\*]+			BUFFER_PUT(buffer, yytext, yyleng);
	<<EOF>>									TOKEN_ERROR(UNCLOSED_C_COMMENT);
}

	/* -- C++ comment -- */
\/\/	{  if(token_opts & TOK_OPT_C_COMMENT)
	   {	TOKEN_BEGIN(cc_comment, buffer);	}
	   else
	   {	BUFFER_PUT(buffer, yytext, yyleng);	}	}
<cc_comment>{
	[^\r\n]+			BUFFER_PUT(buffer, yytext, yyleng);
	{EOL}		{ LINE_INC();	BUFFER_PUT(buffer, yytext, yyleng);
					if(token_opts & TOK_OPT_PASS_COMMENT)
					{					TOKEN_RETURNS(TOK_CC_COMMENT);	}
					else
					{					TOKEN_LOOSE(buffer);	}	}
}

	/* -- standalone text -- */
<INITIAL>{
	{EOL}		LINE_INC();	BUFFER_PUT(buffer, yytext, yyleng);	TOKEN_RETURN(TOK_EOL);
	{TEXT}+				BUFFER_PUT(buffer, yytext, yyleng);	TOKEN_RETURN(TOK_TEXT);
	{BLANK}+			BUFFER_PUT(buffer, yytext, yyleng);	TOKEN_RETURN(TOK_BLANK);
	<<EOF>>				BUFFER_PUT(buffer, yytext, yyleng);	TOKEN_RETURN(TOK_EOF);
}

%%

/* ---------------------------------------
   Tokenizer outer interface
   --------------------------------------- */ 

#define TOKEN_BUFFER Input_Buffer
typedef struct Input_Buffer {
	tok_id			id;	/*might be replaced by yy_buffer_state->yy_input_buffer*/
	tok_line		line;
	YY_BUFFER_STATE 	state;
	struct Input_Buffer	*child;
} Input_Buffer;


tok_bool				tok_ready	= 0;
#define TOKEN_READY_SET()		tok_ready	= 1
#define TOKEN_READY_UNSET()		tok_ready	= 0
#define TOKEN_READY()			(tok_ready == 1)
#define TOKEN_SAFE()			if(!TOKEN_READY())	return 0;
#define TOKEN_IS_SAFE()			(tok_ready)
#define TOKEN_BUFFER_CREATE(buf)	buf = (TOKEN_BUFFER *) malloc(sizeof(TOKEN_BUFFER)); \
		if(buf != NULL) {	buf->line = 1; 	\
					buf->id = 0;	\
					buf->state = NULL; \
					buf->child = NULL;	}


/*token buffer*/
static TOKEN_BUFFER *tokb	= NULL;		/*token buffer top parent*/
static TOKEN_BUFFER *tokb_curr	= NULL;		/*current token buffer*/

/*
 *	set tokenizer options
 */
int tokenizer_options(int opt)
{
	return (token_opts = opt);
}

#ifdef HAVE_CALLBACK_BUFFER
/*
 *	set tokenizer callback buffer
 */
void tokenizer_setcb(struct tok_buffer *tbuf)
{
	TOKEN_TEXT	= tbuf;
	return;
}
#endif

/*
 *	setup default tokenizer
 */
static tok_id tokenizer_init(FILE *f)
{
    if(f != NULL)
	yyin	= f;				/*init from file*/
    else
	return 0;				/*bad input*/

    /*create initial token buffer (needs to be always presented)*/
    TOKEN_BUFFER_CREATE(tokb);
    tokb_curr	= tokb;
    tokb->id	= tokid_counter++;
    tokb->state	= YY_CURRENT_BUFFER;		/*set state from current*/
    TOKEN_READY_SET();				/*go be ready*/
    return TOKEN_ID(tokb->id);
}

/*
 *	creates new tokenizer context pointing to file
 */
tok_id tokenizer_new(FILE *f)
{
    TOKEN_BUFFER *tb	= tokb;

    if(tb == NULL)				/*not initialized*/
	return tokenizer_init(f);
    				
    while(tb != NULL && tb->child != NULL)	/*else we will look for end of tokenizers list*/
	tb	= tb->child;
    TOKEN_BUFFER_CREATE(tb->child);		/*create new token buffer*/
    if(tb->child == 0)
	return 0;				/*something got wrong*/
    tb		= tb->child;			/*else setup structure*/
    tb->id	= tokid_counter++;
    tb->state	= yy_create_buffer(f, YY_BUF_SIZE);
    tokb_curr	= tb;				/*setup current tokb*/
    return TOKEN_ID(tb->id);
}

/*
 *	creates new tokenizer context pointing to buffer
 */
tok_id tokenizer_new_strbuf(const char *buf, unsigned int len)
{
    TOKEN_BUFFER *tb	= tokb;

    if(tb == NULL)				/*(mad hacker) again auto-init*/
	return 0;
 
    while(tb != NULL && tb->child != NULL)
	tb	= tb->child;
    TOKEN_BUFFER_CREATE(tb->child);
    if(tb->child == NULL)
   	return 0;				/*something got wrong*/
    tb		= tb->child;
    tb->id	= tokid_counter++;
    tb->state	= yy_scan_bytes(buf, len);	/*YY_END_OF_BUFFER_CHAR*/
    tokb_curr		= tb;			/*setup current tokb*/
    return TOKEN_ID(tb->id);
}

/*
 *	scan current tokeniner
 */
TOKEN_STRUCT *tokenizer_scan(TOKEN_STRUCT *tok)
{
    if(!TOKEN_IS_SAFE())		/*(mad hacker) tokenizer context not more exists*/
    {	tok->buffer	= NULL;
	tok->token	= TOK_ERROR; 
	tok->error	= NOCONTEXT;
	tok->line	= tok->error_line	= 0;
  	return NULL; }
	
    tok->token	= yylex();
    tok->buffer	= BUFFER_GET(buffer);
    tok->line	= LINE_GET();
    if(tok->token == TOK_ERROR)	/*setup error*/
    {	tok->error	= ERROR_GET();
  	tok->error_line	= ERROR_LINE_GET();	}
    else
    {	tok->error	= NOERR;
  	tok->error_line	= 0;	}
    return tok;
}

/*
 *	scan with auto switch
 */
TOKEN_STRUCT *tokenizer_scanb(tok_id tk, TOKEN_STRUCT *tok)
{
    if(!tokenizer_switch(tk))			/*switch tokenizer*/
	return NULL;
    return tokenizer_scan(tok);	
}

/*
 *	check if tokenizer exists
 */
tok_bool tokenizer_exists(tok_id tok)
{
    TOKEN_BUFFER *tb	= tokb;

    TOKEN_SAFE();
    while(tb != NULL)
    {	if(TOKEN_ID(tb->id) == tok) return 1;
  	tb	= tb->child;	}
    return 0;
}

/*
 *	switch tokenizer buffer
 */
tok_bool tokenizer_switch(tok_id tok)
{
    TOKEN_BUFFER *tb	= tokb;

    TOKEN_SAFE();				/*(mad hacker) check if token is ready (prevents SIGSEGV)*/
    while(tb != NULL)
    {	if(TOKEN_ID(tb->id) == tok) break;
  	tb	= tb->child;	}
    if(tb == NULL)
  	return 0;
    tokb_curr->line	= LINE_GET();		/*line numbering*/
    LINE_SET(tb->line);
    tokb_curr		= tb;			/*set active tokb*/
    yy_switch_to_buffer( tb->state );
    return 1;
}

/*
 *	delete tokenizer context
 */
tok_bool tokenizer_delete(tok_id tok)
{
    TOKEN_BUFFER *tb	= tokb;
    TOKEN_BUFFER *tbp	= NULL;

    TOKEN_SAFE();				/*(mad hacker))*/
    while(tb != NULL)
    {	if(TOKEN_ID(tb->id) == tok) break;
  	tbp	= tb;
  	tb	= tb->child;	}
    if(tb == NULL)
		return	0;			/*not found*/
    if(tb	== tokb)			/*killing top parent*/
  	tokb	= tb->child;
    else					/*killing child*/
  	tbp->child	= tb->child;
    yy_delete_buffer( tb->state );
    free(tb);
    return 1;
}

/*
 *	clear tokenizer context
 */
tok_bool tokenizer_flush(tok_id tok)
{
    TOKEN_BUFFER *tb	= tokb;

    TOKEN_SAFE();				/*(mad hacker)*/
    while(tb != NULL)
    {	if(TOKEN_ID(tb->id) == tok) break;
  	tb	= tb->child;	}
    if(tb != NULL)
    	yy_flush_buffer( tb->state );
    return 1;
}

/*
 *	completly destroy tokenizer
 */
tok_bool tokenizer_destroy()
{
    TOKEN_BUFFER *tb	= tokb;
    TOKEN_BUFFER *tbp;

    TOKEN_SAFE();  				/*(mad hacker)*/
    while(tb	!= NULL)
    {	yy_delete_buffer(tb->state);
  	tbp	= tb;
  	tb	= tb->child;	
	free(tbp);	}
    BUFFER_DESTROY(buffer);
    TOKEN_READY_UNSET();
    return 1;
}


/*!!! for testing purposes !!!*/

#define HAVE_MAIN
#ifdef HAVE_MAIN

int main()
{
	FILE	*f,*ff;
	TOKEN_STRUCT	ts;

	f	= fopen("input.txt", "r");
/*	ff	= fopen("input2.txt", "r");	*/
	tokenizer_opts(TOK_OPT_NOUNESCAPE|TOK_OPT_SIQUOTE);
	tokenizer_new(f);
/*	tokenizer_new(ff);			*/
/*	tokenizer_switch(TOKEN_ID(ff));		*/
	do {
		tokenizer_scan(&ts);
		if(ts.token == TOK_DQUOTE)
			printf("\"%s\"", (char *) ts.buffer);
		else if(ts.token == TOK_SQUOTE)
			printf("'%s'", (char *) ts.buffer);
		else if(ts.token == TOK_IQUOTE)
			printf("`%s`", (char *) ts.buffer);
		else if(ts.token == TOK_SIQUOTE)
			printf("`%s'", (char *) ts.buffer);
		else if(ts.token == TOK_TEXT || ts.token == TOK_BLANK || ts.token == TOK_EOL)
			printf("%s", (char *) ts.buffer);
	} while(ts.token != TOK_EOF && ts.token != TOK_ERROR);
	if(ts.token	== TOK_ERROR)
	{	fprintf(stderr, "ERROR(line=%d, type=%d)\n", ts.error_line, ts.error);
		exit(1);	}
	return 0;
}

#endif


