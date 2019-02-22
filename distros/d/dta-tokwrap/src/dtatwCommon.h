/*
 * File: dtatwCommon.h
 * Author: Bryan Jurish <configure.ac>
 * Description: DTA tokenizer wrappers: C utilities: common definitions: headers
 */

#ifndef DTATW_COMMON_H
#define DTATW_COMMON_H

#include "dtatwConfig.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <time.h>
#include <inttypes.h>   /* for printf format macros, e.g. PRIu32 */
#if HAVE_SYS_TYPES_H
# include <sys/types.h>  /* for ssize_t */
#endif
#if HAVE_SYS_STAT_H
# include <sys/stat.h>   /* for off_t */
#endif

/*======================================================================
 * Globals
 */

#define FILE_BUFSIZE 8192 //-- file input buffer size
typedef uint32_t ByteOffset;
typedef uint32_t ByteLen;

#define ByteOffsetF PRIu32
#define ByteLenF    PRIu32

extern char *prog;

//-- CX_FORMULA_TEXT : text inserted for <formula/> records
extern char *CX_FORMULA_TEXT; //-- default: " FORMULA "

//-- xmlid_attr : output attribute for (xml:)?id attributes (default="id")
extern char *xmlid_name; 

/*======================================================================
 * utf8 stuff
 */

/** \brief useful alias */
#ifndef HAVE_UINT
#define uint unsigned int
#endif

/** \brief useful alias */
#ifndef HAVE_UCHAR
# define uchar unsigned char
#endif


/*======================================================================
 * Debug
 */

//-- ENABLE_ASSERT : if defined, debugging assertions will be enabled
#define ENABLE_ASSERT 1
//#undef ENABLE_ASSERT

#if !defined(assert)
# if defined(ENABLE_ASSERT)
#  define assert2(test,label) \
     if (!(test)) { \
       fprintf(stderr, "%s: %s:%d: assertion failed: (%s): %s\n", prog, __FILE__, __LINE__, #test, (label)); \
       exit(255); \
     }
#  define assert(test) \
     if (!(test)) { \
       fprintf(stderr, "%s: %s:%d: assertion failed: (%s)\n", prog, __FILE__, __LINE__, #test); \
       exit(255); \
     }
# else  /* defined(ENABLE_ASSERT) -> false */
#  define assert(test)
#  define assert2(test,label)
# endif /* defined(ENABLE_ASSERT) */
#endif /* !defined(assert) */

/*======================================================================
 * Utils: XML-escapes
 */

/*--------------------------------------------------------------
 * put_escaped_char(f,c)
 */
static inline
//void put_escaped_char(FILE *f_out, XML_Char c)
void put_escaped_char(FILE *f_out, char c)
{
  switch (c) {
  case '&': fputs("&amp;", f_out); break;
  case '"': fputs("&quot;", f_out); break;
  case '\'': fputs("&apos;", f_out); break;
  case '>': fputs("&gt;", f_out); break;
  case '<': fputs("&lt;", f_out); break;
    //case '\t': fputs("&#9;", f_out); break;
  case '\n': fputs("&#10;", f_out); break;
  case '\r': fputs("&#13;", f_out); break;
  default: fputc(c, f_out); break;
  }
}

/*--------------------------------------------------------------
 * put_escaped_str(f,str,len)
 */
static inline
//void put_escaped_str(FILE *f, const XML_Char *str, int len)
void put_escaped_str(FILE *f, const char *str, int len)
{
  int i;
  for (i=0; str[i] && (len < 0 || i < len); i++) {
    put_escaped_char(f,str[i]);
  }
}

/*======================================================================
 * Utils: XML-comments
 */

/*--------------------------------------------------------------
 * put_escaped_cmt_str(f,str,len)
 *  + escapes double-hypens "--" as "-\-"
 */
static inline
void put_escaped_cmt_str(FILE *f, const char *str, int len)
{
  int i;
  int last_was_hyphen = 0;
  for (i=0; str[i] && (len < 0 || i < len); i++) {
    if (str[i]=='-') {
      if (last_was_hyphen) fputc('\\', f);
      last_was_hyphen = 1;
    } else {
      last_was_hyphen = 0;
    }
    fputc(str[i], f);
  }
}

/*======================================================================
 * Utils: basename
 */

/*--------------------------------------------------------------
 * file_basename(dst, src, suff, srclen, dstlen)
 *  + removes leading directories (if any) and suffix 'suff' from 'src', writing result to 'dst'
 *  + returns 'dst', allocating if it is passed as a NULL pointer
 *    - if 'dst' is non-NULL, 'dstlen' should contain the allocated length of 'dst'
 *    - otherwise, if 'dst' is NULL, 'dstlen' should be <=0 (basename only) or number of additional bytes to allocate
 */
extern char *file_basename(char *dst, const char *src, const char *suff, int srclen, int dstlen);

/*======================================================================
 * Utils: si
 */

/*--------------------------------------------------------------
 * g = si_g(f)
 */
static inline
double si_val(double g)
{
  if (g >= 1e12) return g / 1e12;
  if (g >= 1e9) return g / 1e9;
  if (g >= 1e6) return g / 1e6;
  if (g >= 1e3) return g / 1e3;
  return g;
}

static inline
const char *si_suffix(double g)
{
  if (g >= 1e12) return "T";
  if (g >= 1e9) return "G";
  if (g >= 1e6) return "M";
  if (g >= 1e3) return "K";
  return "";
}

/*======================================================================
 * Utils: TAB-separated string parsing
 */

//--------------------------------------------------------------
// next_tab()
//  + returns char* to next '\t', '\n', or '\0' in s
inline static char *next_tab(char *s)
{
  for (; *s && *s!='\t' && *s!='\n'; s++) ;
  return s;
}

//--------------------------------------------------------------
// next_tab_z()
//  + returns char* to position of next '\t', '\n', or '\0' in s
//  + sets the character to '\0', so returned string always looks like ""
inline static char *next_tab_z(char *s)
{
  for (; *s && *s!='\t' && *s!='\n'; s++) ;
  *s = '\0';
  return s;
}

//--------------------------------------------------------------
// next_char_z()
//  + returns char* to position of next character c or '\0' in s
//  + sets the matching character to '\0', so returned string always looks like ""
inline static char *next_char_z(char *s, char c)
{
  for (; *s && *s != c; s++) ;
  *s = '\0';
  return s;
}

/*======================================================================
 * Utils: slurp
 */

// size = file_size(f)
//  + get file size; uses fstat()
off_t file_size(FILE *f);

// slurp_file()
//  + slurp file contents into buf
//  + if buflen is zero, *bufp will be a newly allocated buffer
//    which on return contains all the (remaining) bytes of the file
//  + if buflen is nonzero, *bufp should have that many bytes allocated,
//    and only that many bytes will be slurped
//  + return value is number of bytes actually slurped
size_t file_slurp(FILE *f, char **bufp, size_t buflen);

/*======================================================================
 * Utils: cx: binary
 */

/// cxRecordType : enum for binary cx record types
typedef enum {
  cxrChar  = 0,		//-- cxrChar: "normal" character entry (attrs: @bbox = (@ulx @uly @lrx @lry))
  cxrLb    = 1,		//-- cxrLb: line-break (attrs:none)
  cxrPb    = 2,		//-- cxrPb: page-break (attrs:@facs)
  cxrFormula = 3,	//-- cxrFormula: formula (attrs:none)
  cxrEOF = 4		//-- cxrEOF: special type for eof pseudo-records
} cxRecordType;
extern const char *cxTypeNames[8]; //-- for mask-safety

/// cxStoredRecord: mask constants
extern const uchar cxfTypeMask;		//-- cx flag mask: record type
extern const uchar cxfHasXmlOffset;	//-- cx flag: xoff != (xoff[i-1]+xlen[i-1])
extern const uchar cxfHasTxtLength;  	//-- cx flag: xlen != tlen
extern const uchar cxfHasAttrs;		//-- cx flag: attributes present?

/// cxStoredRecord: basic i/o unit
typedef struct {
  uchar   flags;	//-- ((cxRecordType typ) & cxfTypeMask) |cxfHasXmlOffset? |cxfHasTxtLength? |cxfHasAttrs?
  uint32_t xoff;	//-- xml offset (only written if (flags & cxfHasXmlOffset))
  uchar    xlen;	//-- xml length
  uchar    tlen;	//-- text length (only written if (flags & cxfHasTxtLen))
  uint32_t attrs[4];	//-- attributes (only written if (flags & cxfHasAttrs)): pb->@facs, c->(@ulx,@uly,@lrx,@lry)
} cxStoredRecord;

void cx_put_record(FILE *f, const cxStoredRecord *cxr);
int cx_get_record(FILE *f, cxStoredRecord *cxr, uint32_t xmlOffset); //-- returns cxRecordType

//-- cx: packed: header
extern const char *cxhMagic;		//-- cx header: magic
extern const char *cxhVersion;		//-- cx header: current tokwrap version
extern const char *cxhVersionMinR;	//-- cx header: min tokwrap-version of cx-files we can read
extern const char *cxhVersionMinW;	//-- cx header: min tokwrap-version required for cx-files we write

#define CXH_MAGIC_LEN 32
#define CXH_VERSION_LEN 8
typedef struct {
  char magic[CXH_MAGIC_LEN];		//-- cx header: magic
  char version[CXH_VERSION_LEN];	//-- cx header: current tokwrap version
  char version_min[CXH_VERSION_LEN];	//-- cx header: minimum compatible version for loading this file
} cxHeader;
int       cx_version_cmp(const char *v1, const char *v2);
void      cx_put_header(FILE *f);
cxHeader* cx_get_header(FILE *f, const char *filename, cxHeader *h);
int	  cx_check_header(const cxHeader *h, const char *filename);


//-- packed i/o: perl pack('w',$i)
// + BER-compressed integers (unsigned int in base-128, high bit (0x80) set on all but final byte)
// + unused
void       put_packed_w(FILE *f, ByteOffset i);
ByteOffset get_packed_w(FILE *f);


/*======================================================================
 * Utils: .cx file(s): new
 */

/// cxRecord : struct for character-index records as loaded from .cx file
///  + routines should use cxStoredRecord internally
typedef struct {
  cxRecordType typ;	//-- record type (formerly char *elt)
  ByteOffset xoff;      //-- original xml byte offset
  ByteLen    xlen;      //-- original xml byte length
  ByteOffset toff;      //-- .tx byte offset
  ByteLen    tlen;      //-- .tx byte length
  struct bxRecord_t *bxp; //-- pointer to .bx-record (block) containing this <c>, if available
  uchar claimed;	//-- claimed (0:unclaimed, 1: claimed by current word, >1: claimed by other word)
} cxRecord;

// cxData : array of .cx records
typedef struct {
  cxRecord   *data;              //-- vector of cx records
  ByteOffset  len;               //-- number of used cx records (index of 1st unused record)
  ByteOffset  alloc;             //-- number of allocated cx records
} cxData;

// CXDATA_DEFAULT_ALLOC : default original buffer size for cxData.data, in number of records
#ifndef CXDATA_DEFAULT_ALLOC
# define CXDATA_DEFAULT_ALLOC 8192
#endif

cxData   *cxDataInit(cxData *cxd, size_t size);     //-- initializes/allocates *cxd
cxRecord *cxDataPush(cxData *cxd, cxRecord *cx);    //-- append *cx to *cxd->data, re-allocating if required
cxData   *cxDataLoad(cxData *cx, FILE *f, const char *filename);  //-- loads *cxd from file f (filename is for error-reporting)

/*======================================================================
 * Utils: .bx file(s)
 */

// bxRecord : struct for block-index records as loaded from .bx file
typedef struct bxRecord_t {
  char *key;        //-- sort key
  char *elt;        //-- element name
  ByteOffset xoff;  //-- xml byte offset
  ByteOffset xlen;  //-- xml byte length
  ByteOffset toff;  //-- tx byte offset
  ByteOffset tlen;  //-- tx byte length
  ByteOffset otoff; //-- txt byte offset
  ByteOffset otlen; //-- txt byte length
} bxRecord;

// bxData : array of .bx records
typedef struct {
  bxRecord   *data;              //-- vector of bx records
  ByteOffset  alloc;             //-- number of allocated bx records
  ByteOffset  len;               //-- number of used bx records (index of 1st unused record)
} bxData;

// BXDATA_DEFAULT_ALLOC : default buffer size for bxdata[], in number of records
#ifndef BXDATA_DEFAULT_ALLOC
# define BXDATA_DEFAULT_ALLOC 1024
#endif

bxData   *bxDataInit(bxData *bxd, size_t size);   //-- initialize/allocate bxdata
bxRecord *bxDataPush(bxData *bxd, bxRecord *bx);      //-- append *bx to *bxd, re-allocating if required
bxData   *bxDataLoad(bxData *bxd, FILE *f);           //-- loads *bxd from file f


/*======================================================================
 * Utils: .cx + .bx indexing
 */

typedef struct {
  cxRecord **data;     //-- cxRecord_ptr = data[byte_index]
  ByteOffset  len;     //-- number of allocated&used positions in data
} Offset2CxIndex;

// tx2cxIndex(): init/alloc: cxRecord *cx =  txo2cx->data[ tx_byte_index]
Offset2CxIndex  *tx2cxIndex(Offset2CxIndex *txo2cx,  cxData *cxd);

// txt2cxIndex(): init/alloc: cxRecord *cx = txto2cx->data[txt_byte_index]
Offset2CxIndex *txt2cxIndex(Offset2CxIndex *txto2cx, bxData *bxd, Offset2CxIndex *txb2cx);

// cx_is_adjacent(): check whether cx1 immediately follows cx2
int cx_is_adjacent(const cxRecord *cx1, const cxRecord *cx2);

/*======================================================================
 * forward c library decls
 */
extern ssize_t getline (char **LINEPTR, size_t *N, FILE *STREAM);

#endif /* DTATW_COMMON_H */
