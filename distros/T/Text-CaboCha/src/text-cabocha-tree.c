#include "text-cabocha.h"
#ifndef  __TEXT_CABOCHA_TREE_C__
#define  __TEXT_CABOCHA_TREE_C__

size_t
TextCaboCha_Tree_size(TextCaboCha_Tree *tree)
{
    return tree->size();
}

size_t
TextCaboCha_Tree_token_size(TextCaboCha_Tree *tree)
{
    return tree->token_size();
}

const TextCaboCha_Token *
TextCaboCha_Tree_token(TextCaboCha_Tree *tree, size_t size)
{
    return tree->token(size);
}

SV *
TextCaboCha_Tree_tokens(TextCaboCha_Tree *tree)
{
    AV* ary = newAV();
    size_t token_size = tree->token_size();
    for (size_t i = 0; i < token_size; i++) {
        SV *token;
        token = newSViv(PTR2IV(tree->token(i)));
        token = newRV_noinc(token);
        sv_bless(token, gv_stashpv(TEXT_CABOCHA_TOKEN_KLASS, 1));
        SvREADONLY_on(token);
        av_push(ary, token);
    }
    return newRV_noinc((SV *)ary);
}

size_t
TextCaboCha_Tree_chunk_size(TextCaboCha_Tree *tree)
{
    return tree->chunk_size();
}

const TextCaboCha_Chunk *
TextCaboCha_Tree_chunk(TextCaboCha_Tree *tree, size_t size)
{
    return tree->chunk(size);
}

SV *
TextCaboCha_Tree_chunks(TextCaboCha_Tree *tree)
{
    AV* ary = newAV();
    size_t chunk_size = tree->chunk_size();
    for (size_t i = 0; i < chunk_size; i++) {
        SV *chunk;
        chunk = newSViv(PTR2IV(tree->chunk(i)));
        chunk = newRV_noinc(chunk);
        sv_bless(chunk, gv_stashpv(TEXT_CABOCHA_CHUNK_KLASS, 1));
        SvREADONLY_on(chunk);
        av_push(ary, chunk);
    }
    return newRV_noinc((SV *)ary);
}

const char *
TextCaboCha_Tree_tostr(TextCaboCha_Tree *tree, unsigned int format)
{
    return tree->toString(static_cast<CaboCha::FormatType>(format));
}

#endif /* __TEXT_CABOCHA_TREE_C__ */