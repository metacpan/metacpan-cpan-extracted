#include "text-cabocha.h"
#ifndef  __TEXT_CABOCHA_CHUNK_C__
#define  __TEXT_CABOCHA_CHUNK_C__

int
TextCaboCha_Chunk_link(TextCaboCha_Chunk *chunk)
{
    return CABOCHA_CHUNK_LINK(chunk);
}

size_t
TextCaboCha_Chunk_head_pos(TextCaboCha_Chunk *chunk)
{
    return CABOCHA_CHUNK_HEAD_POS(chunk);
}

size_t
TextCaboCha_Chunk_func_pos(TextCaboCha_Chunk *chunk)
{
    return CABOCHA_CHUNK_FUNC_POS(chunk);
}

size_t
TextCaboCha_Chunk_token_size(TextCaboCha_Chunk *chunk)
{
    return CABOCHA_CHUNK_TOKEN_SIZE(chunk);
}

size_t
TextCaboCha_Chunk_token_pos(TextCaboCha_Chunk *chunk)
{
    return CABOCHA_CHUNK_TOKEN_POS(chunk);
}

float
TextCaboCha_Chunk_score(TextCaboCha_Chunk *chunk)
{
    return CABOCHA_CHUNK_SCORE(chunk);
}

SV *
TextCaboCha_Chunk_feature_list(TextCaboCha_Chunk *chunk)
{
    const char ** feature_list;
    feature_list = CABOCHA_CHUNK_FEATURE_LIST(chunk);
    AV* ary = newAV();
    while (feature_list && (*feature_list) != 0) {
        av_push(ary, newSVpv(*feature_list, 0));
        feature_list++;
    }
    return newRV_noinc((SV *)ary);
}

const char *
TextCaboCha_Chunk_additional_info(TextCaboCha_Chunk *chunk)
{
    return CABOCHA_CHUNK_ADDITIONAL_INFO(chunk);
}

unsigned short int
TextCaboCha_Chunk_list_size(TextCaboCha_Chunk *chunk)
{
    return CABOCHA_CHUNK_FEATURE_LIST_SIZE(chunk);
}

#endif /* __TEXT_CABOCHA_CHUNK_C__ */