#ifndef  __TOKENS_H
#define  __TOKENS_H

#include <context.h>

typedef struct token_struct token;
typedef struct token_struct *token_p;

typedef struct token_group_struct token_group;
typedef struct token_group_struct *token_group_p;

#define TOKEN_TYPE_NONE       0
#define TOKEN_TYPE_TEXT       1
#define TOKEN_TYPE_TAG        2
#define TOKEN_TYPE_TAG_PARSED 3

#define TOKEN_GROWFACTOR      20

struct token_group_struct
{
    /* array of tokens */
    token_p tokens;

    /* number of tokens allocated for */
    int max_token;

    /* index of the first token */
    unsigned int first;

    /* index of the last token */
    unsigned int last;

    /* index of the current token */
    unsigned int current;
};

struct token_struct
{
    /* the token itself */
    char *t;

    /* if the token is a tag, this is its argument vector */
    char **tag_argv;

    /* if the token is a tag, this is the size of its argument vector */
    int  tag_argc;

    /* the length of the token */
    unsigned long length;

    /* the type of token (TOKEN_TYPE_*) */
    unsigned char type;
};

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

void          append_output(char **output, char *append, int append_length,
                            int *current_size, int *current_length);
int           tokenize(context_p ctx, char *input, token_group_p tgroup);

token_group_p token_group_init(void);
token_group_p token_subgroup_init(token_group_p tgroup, unsigned int first,
                                  unsigned int last);
void          token_group_destroy(token_group_p tgroup);
void          token_subgroup_destroy(token_group_p tgroup);
void          token_rewind(token_group_p tgroup);
token_p       token_next(context_p ctx, token_group_p tgroup,
                         unsigned int *position);
void          token_parsetag(context_p ctx, token_p token);
int           token_push(token_group_p tgroup, char *t, unsigned long length,
                         unsigned char type);
void          token_parsearg(context_p ctx, char *inarg, int size,
                             char **outarg);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __TOKENS_H */
