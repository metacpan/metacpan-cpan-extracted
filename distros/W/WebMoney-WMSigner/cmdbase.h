#include "crypto.h"
#include "md4.h"

#ifndef _INC_STDIO
#include <stdio.h>
#endif 

#include "string.h"

#ifndef NULL
#ifdef __cplusplus
#define NULL    0
#else
#define NULL    ((void *)0)
#endif
#endif
typedef unsigned long       DWORD;
typedef int                 BOOL;
typedef unsigned char       BYTE;
typedef unsigned short      SWORD;


#define EBITS     (48)
#define KEYBITS   (528)

#define MAX_BIT_PRECISION (2048)
#define MAX_UNIT_PRECISION (MAX_BIT_PRECISION/(sizeof(unsigned short)*8))

#define _CMDLOAD_ERR_CMD_CRIPTION_  1
#define _CMDLOAD_ERR_CMD_CRC_       2
#define _CMDLOAD_ERR_BUF_LEN_       3
#define _CMDLOAD_ERR_CMD_DECODE_    4
#define _CMDLOAD_ERR_CMD_CODE_      5
#define _CMDLOAD_ERR_NULL_KEY_      6

class szptr
{
  char *sz;

public:
  szptr() { sz = NULL; }
  szptr(const char *csz);
  szptr(const szptr& cszptr);
  ~szptr();

  char* operator = (char *csz);
  szptr& operator = (const szptr& cszptr);
  szptr& operator += (const szptr& cszptr);
  inline void ReplaceIncluding(char *szp) { if(sz) delete sz; sz = szp; }
  inline char operator*() { return sz ? *sz : '\0'; }
  inline char operator[](int i) const { return sz ? *(sz+i) : '\0'; }
  inline operator char const * const () const { return sz; } 
  int strlen() const {
    if (sz) return (int)::strlen(sz);
    else return 0;
  }
  inline bool operator==(const szptr& s) const { return (sz && s.sz) ? (strcmp(s.sz,sz)==0) : (sz == s.sz); }
  inline bool operator!=(const szptr& s) const { return (sz && s.sz) ? (strcmp(s.sz,sz)!=0) : (sz != s.sz); }

  szptr& TrimLeft();
  szptr& TrimRight();
};


struct KeyFileFormat
{
  enum {sizeof_header = sizeof(SWORD)*2 + sizeof(DWORD)*5, sizeof_crc = (sizeof(DWORD)*4)};
  SWORD  wReserved1; 
  SWORD  wSignFlag;
  DWORD dwCRC[4];
  DWORD dwLenBuf;  
  char  ptrBuffer[1];
};

struct Keys
{
  DWORD dwReserv;
  SWORD arwEKey[MAX_UNIT_PRECISION];
  SWORD arwNKey[MAX_UNIT_PRECISION];
  SWORD wEKeyBase;
  SWORD wNKeyBase;

  Keys();
  Keys(const Keys& keysFrom);
  Keys& operator=(const Keys& KeysFrom);
  virtual DWORD GetMembersSize();
  virtual char*  LoadMembers(char *BufPtr);
  virtual int LoadFromBuffer(const char *Buf, DWORD dwBufLen);
  virtual char*  SaveMembers(char *BufPtr);
  virtual int SaveIntoBuffer(char **ptrAllocBuf, DWORD *dwBufLen);

  static bool CountCrcMD4(DWORD *dwCRC, const char *Buf, DWORD dwBufLenBytes);
  void RecalcBase();
};


bool us2sz(const unsigned short *buf, int len, char *szBuffer);
char stohb(char s);
bool sz2us(const char *szBuffer, unsigned short *usBuf);
