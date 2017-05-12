/*tokenizer.h*/


#ifndef __TOKENIZER_H
#define __TOKENIZER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*fixups for constants export*/
#define	TOK_UNDEF_v		0
#define	TOK_TEXT_v		1
#define	TOK_DQUOTE_v		2
#define	TOK_SQUOTE_v		3
#define	TOK_IQUOTE_v		4
#define	TOK_SIQUOTE_v		5
#define	TOK_BLANK_v		6
#define	TOK_ERROR_v		7
#define	TOK_EOL_v		8
#define	TOK_BASH_COMMENT_v	9
#define TOK_C_COMMENT_v		10
#define TOK_CC_COMMENT_v	11
#define	TOK_EOF_v		EOF

#define	NOERR_v			0
#define	UNCLOSED_DQUOTE_v	1
#define	UNCLOSED_SQUOTE_v	2
#define	UNCLOSED_IQUOTE_v	3
#define	NOCONTEXT_v		4
#define UNCLOSED_C_COMMENT_v	5

/*token types*/
typedef enum {
   TOK_UNDEF		= TOK_UNDEF_v,
   TOK_TEXT		= TOK_TEXT_v,
   TOK_DQUOTE		= TOK_DQUOTE_v,
   TOK_SQUOTE		= TOK_SQUOTE_v,
   TOK_IQUOTE		= TOK_IQUOTE_v,
   TOK_SIQUOTE		= TOK_SIQUOTE_v,
   TOK_BLANK		= TOK_BLANK_v,
   TOK_ERROR		= TOK_ERROR_v,
   TOK_EOL		= TOK_EOL_v,
   TOK_COMMENT		= TOK_BASH_COMMENT_v,
   TOK_BASH_COMMENT	= TOK_BASH_COMMENT_v,
   TOK_C_COMMENT	= TOK_C_COMMENT_v,
   TOK_CC_COMMENT	= TOK_CC_COMMENT_v,
   TOK_EOF		= TOK_EOF_v
} tok_type;

/*error types*/
typedef enum {
  NOERR			= NOERR_v,
  UNCLOSED_DQUOTE	= UNCLOSED_DQUOTE_v,
  UNCLOSED_SQUOTE	= UNCLOSED_SQUOTE_v,
  UNCLOSED_IQUOTE	= UNCLOSED_IQUOTE_v,
  NOCONTEXT		= NOCONTEXT_v,
  UNCLOSED_C_COMMENT	= UNCLOSED_C_COMMENT_v
} tok_error;

/*tokenizer options*/
#define TOK_OPT_NONE			0UL
#define TOK_OPT_UNESCAPE_CHARS		(1UL<<1)
#define TOK_OPT_UNESCAPE_LINES		(1UL<<2)
#define TOK_OPT_UNESCAPE		(TOK_OPT_UNESCAPE_CHARS | TOK_OPT_UNESCAPE_LINES)
#define TOK_OPT_NOUNESCAPE		(1UL<<3)
#define TOK_OPT_SIQUOTE			(1UL<<4)
#define TOK_OPT_UNESCAPE_NQ_LINES	(1UL<<5)
#define TOK_OPT_PASSCOMMENT		(1UL<<6)
#define TOK_OPT_PASS_COMMENT		TOK_OPT_PASSCOMMENT
#define TOK_OPT_NO_BASH_COMMENT		(1UL<<7)
#define TOK_OPT_C_COMMENT		(1UL<<8)
#define TOK_OPT_CC_COMMENT		(1UL<<9)
#define TOK_OPT_NO_IQUOTE		(1UL<<10)

/*default options*/
#define TOK_OPT_DEFAULT			(TOK_OPT_NOUNESCAPE)

/*typedefs*/
typedef unsigned int	tok_id;
typedef unsigned int	tok_line;
typedef short int	tok_bool;
typedef void		tok_buf;

typedef struct {
	tok_buf 	*buffer;	/*readed string ptr (don't know what's holding)*/
	tok_type 	token;		/*string type*/
	tok_line 	line;		/*current position*/
	tok_error 	error;		/*error type*/
	tok_line 	error_line;	/*error start position*/
} tok_retval;

struct tok_buffer {
	tok_buf		*(*ts_new)(void *);		/*create new buffer*/
	void		(*ts_clear)(void *, tok_buf *);	/*clear buffer*/
	void		(*ts_put)(void *,   tok_buf *, char *, unsigned int);
	void		(*ts_del)(void *,   tok_buf *);
	void		*ts_context;		/*context buffer (if used)*/
};

/*def*/
#define TOKEN_STRUCT tok_retval

/*functions*/
#define TOKEN_ID(d) (tok_id) (d)

/*tokenizer options*/
int	tokenizer_options(int);
#define tokenizer_opts(opt)	tokenizer_options((opt))
#define tokenizer_opt(opt)	tokenizer_options((opt))
#ifdef HAVE_CALLBACK_BUFFER
void tokenizer_setcb(struct tok_buffer *);
#else
#define tokenizer_setcb(junk)
#endif

/* tokenizer initialization*/
static tok_id	tokenizer_init(FILE *);
/* create new scan buffer from passed file*/
tok_id	tokenizer_new(FILE *);
/* crate new scan buffer from passed array of bytes*/
tok_id	tokenzier_new_strbuf(const char *, unsigned int);
/* perform scan and return values*/
TOKEN_STRUCT *tokenizer_scan(TOKEN_STRUCT *);
/* perform scan and return values with buffer auto switch*/
TOKEN_STRUCT *tokenizer_scanb(tok_id, TOKEN_STRUCT *);
/* find wheter scan buffer exists*/
tok_bool tokenizer_exists(tok_id);
/* switch scan buffer*/
tok_bool tokenizer_switch(tok_id);
/* delete scan buffer*/
tok_bool tokenizer_delete(tok_id);
/* flush scan buffer*/
tok_bool tokenizer_flush(tok_id);
/* destroy whole tokenizer*/
tok_bool tokenizer_destroy();


#ifdef __cplusplus
}
#endif

#endif
