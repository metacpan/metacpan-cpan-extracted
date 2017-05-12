#ifndef __SOUNDEX_H__
#define __SOUNDEX_H__

#ifdef __GNUC__
void Soundex (char *Name, char *Key);
void Phonix (char *Name, char *Key);
#else
extern void Soundex ();
extern void Phonix ();
#endif

#endif /* __SOUNDEX_H__ */
