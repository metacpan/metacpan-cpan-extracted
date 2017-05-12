#ifndef _INC_MD4
#define _INC_MD4

typedef unsigned long Word32Type;

typedef struct {
  Word32Type   buffer[4];  
  unsigned char count[8];
  unsigned int done;     
} MDstruct, *MDptr;

#ifdef __cplusplus
extern "C" {
#endif
extern void MDbegin(MDptr MDp) ;

extern void MDupdate(MDptr MDp, unsigned char *X, Word32Type count) ;

extern void MDprint(MDptr MDp) ;

#ifdef __cplusplus
}
#endif

#endif

