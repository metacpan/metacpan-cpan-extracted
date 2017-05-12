#ifndef METAPHONE_UTIL__H
#define METAPHONE_UTIL__H


typedef struct
{
    unsigned char *str;
    int length;
    int bufsize;
    int free_string_on_destroy;
}
metastring;      

metastring *
NewMetaString(unsigned char *init_str);

void
DestroyMetaString(metastring * s);

unsigned char
GetAt(metastring * s, int pos);

void
SetAt(metastring * s, int pos, unsigned char c);

int
StringAt(metastring * s, int start, int length, ...);

void
MakeUpper(metastring * s);

void
MetaphAdd(metastring * s, unsigned char *new_str);

#endif /* METAPHONE_UTIL__H */
