#include "dtatwCommon.h"

/*======================================================================
 * Globals
 */
char *prog = "dtatwCommon"; //-- used for error reporting

char *CX_FORMULA_TEXT  = " FORMULA ";

//char *xmlid_name = "xml:id";
char *xmlid_name = "id";

//-- foward decl (lives in string.h)
extern char *basename(const char *path);

//-- suppress gcc warnings of the form "ignoring return value of `fread', declared with attribute warn_unused_result [-Wunused-result]"
#pragma GCC diagnostic ignored "-Wunused-result"

/*======================================================================
 * Utils: basename
 */
char *file_basename(char *dst, const char *src, const char *suff, int srclen, int dstlen)
{
  const char *b = basename(src);
  int blen = strlen(b);
  int suflen = suff ? strlen(suff) : 0;
  if (suff && blen >= suflen && strcmp(suff,b+blen-suflen)==0) { blen -= suflen; }

  //-- maybe allocate dst
  if (dst==NULL) {
    if (dstlen <= 0) dstlen  = blen+1;
    else             dstlen += blen+1;
    dst = (char*)malloc(dstlen);
    assert(dst != NULL /* malloc error */);
  }

  //-- copy
  assert(dstlen > blen /* buffer overflow */);
  memcpy(dst, b, blen);
  dst[blen] = '\0';

  return dst;
}

/*======================================================================
 * Utils: slurp
 */

//--------------------------------------------------------------
off_t file_size(FILE *f)
{
  struct stat st;
  if (fstat(fileno(f), &st) != 0) {
    fprintf(stderr, "file_size(): ERROR: %s\n", strerror(errno));
    exit(255);
  }
  return st.st_size;
}

//--------------------------------------------------------------
size_t file_slurp(FILE *f, char **bufp, size_t buflen)
{
  size_t nread=0;
  if (buflen==0) {
    size_t nwanted = file_size(f) - ftello(f);
    *bufp = (char*)malloc(nwanted);
    assert2(*bufp != NULL, "malloc failed");
    buflen = nwanted;
  }
  assert2(bufp != NULL && *bufp != NULL, "bad buffer for file_slurp()");
  nread = fread(*bufp, sizeof(char), buflen, f);
  return nread;
}

/*======================================================================
 * Utils: cx: packed: flags
 */

//-- cx: packed: flags
const uchar cxfTypeMask = 0x7;
const uchar cxfHasXmlOffset = 0x8;
const uchar cxfHasTxtLength = 0x10;
const uchar cxfHasAttrs = 0x20;
const uchar cxfUnused1 = 0x40;
const uchar cxfUnused2 = 0x80;

const  char *cxTypeNames[8] = {"c","lb","pb","formula","EOF","#5","#6","#7"};

/*======================================================================
 * Utils: cx: packed: header
 */

//-- cx: packed: header
const char *cxhMagic   = PACKAGE " cx bin\n";
const char *cxhVersion = PACKAGE_VERSION; 
const char *cxhVersionMinR = "0.40";
const char *cxhVersionMinW = "0.40";

//--------------------------------------------------------------
int cx_version_cmp(const char *v1, const char *v2)
{
  unsigned long int u1, u2;
  char *tail1=NULL, *tail2=NULL;
  while (v1 && v2 && *v1 && *v2) {
    u1 = strtoul(v1,&tail1,10);
    u2 = strtoul(v2,&tail2,10);
    if      (u1 < u2) return -1;
    else if (u1 > u2) return  1;

    v1 = tail1 && *tail1 ? (tail1+1) : NULL;
    v2 = tail2 && *tail2 ? (tail2+1) : NULL;
  }
  if      (! v1 &&   v2) return -1;
  else if (  v1 && ! v2) return  1;
  else if (! v1 && ! v2) return  0;
  else if (!*v1 &&  *v2) return -1;
  else if ( *v1 && !*v2) return  1;
  return 0;
}

//--------------------------------------------------------------
void cx_put_header(FILE *f)
{
  cxHeader h;
  memset(&h, 0, sizeof(cxHeader));
  strncpy(h.magic,       cxhMagic,       CXH_MAGIC_LEN);
  strncpy(h.version,     cxhVersion,     CXH_VERSION_LEN);
  strncpy(h.version_min, cxhVersionMinW, CXH_VERSION_LEN);
  fwrite(&h, sizeof(cxHeader), 1, f);
}


//--------------------------------------------------------------
cxHeader* cx_get_header(FILE *f, const char *filename, cxHeader *h)
{
  const char *file = filename ? filename : "(null)";
  if (!h)
    h = (cxHeader*)malloc(sizeof(cxHeader));
  
  memset(h, 0, sizeof(cxHeader));
  if (fread(h, sizeof(cxHeader), 1, f) != 1) {
    fprintf(stderr, "%s: failed to read header from binary cx-file %s\n", prog, file);
    exit(1);
  }
  h->magic[CXH_MAGIC_LEN-1] = '\0';
  h->version[CXH_VERSION_LEN-1] = '\0';
  h->version_min[CXH_VERSION_LEN-1] = '\0';
  return h;
}

//--------------------------------------------------------------
int cx_check_header(const cxHeader *h, const char *filename)
{
  const char *file = filename ? filename : "(null)";

  //-- check: magic
  if (strcmp(h->magic,cxhMagic) != 0) {
    fprintf(stderr, "%s: bad magic `%s' from cx-file %s\n", prog, h->magic, file);
    return 0;
  }

  //-- check: version
  if (cx_version_cmp(h->version_min, cxhVersion) > 0) {
    fprintf(stderr, "%s: cx file %s requires v%s, but we have only v%s\n", prog, file, h->version_min, cxhVersion);
    return 0;
  }
  if (cx_version_cmp(h->version, cxhVersionMinR) < 0) {
    fprintf(stderr, "%s: cx file %s is only v%s, but we require >= v%s\n", prog, file, h->version, cxhVersionMinR);
    return 0;
  }

  //-- all ok
  return 1;
}

/*======================================================================
 * Utils: cx: packed: i/o
 */

//--------------------------------------------------------------
void cx_put_record(FILE *f, const cxStoredRecord *cxr)
{
  fputc(cxr->flags,f);
  if (cxr->flags & cxfHasXmlOffset)
    fwrite(&cxr->xoff,4,1,f);
  fputc(cxr->xlen,f);
  if (cxr->flags & cxfHasTxtLength)
    fputc(cxr->tlen,f);
  if (cxr->flags & cxfHasAttrs) {
    switch (cxr->flags&cxfTypeMask) {
    case cxrChar: fwrite(cxr->attrs,4,4,f); break;
    case cxrPb:   fwrite(cxr->attrs,4,1,f); break;
    default: break;
    }
  }
}

//--------------------------------------------------------------
int cx_get_record(FILE *f, cxStoredRecord *cxr, uint32_t xmlOffset)
{
  int i = fgetc(f);
  if (i==EOF || feof(f)) {
    cxr->flags = cxrEOF;
    return cxrEOF;
  }
  cxr->flags = i;

  if (cxr->flags & cxfHasXmlOffset)
    fread(&cxr->xoff,4,1,f);
  else
    cxr->xoff = xmlOffset;

  cxr->xlen = fgetc(f);

  if (cxr->flags & cxfHasTxtLength)
    cxr->tlen = fgetc(f);
  else
    cxr->tlen = cxr->xlen;

  if (cxr->flags & cxfHasAttrs) {
    switch (cxr->flags&cxfTypeMask) {
    case cxrChar: fread(cxr->attrs,4,4,f); break;
    case cxrPb:   fread(cxr->attrs,4,1,f); break;
    default: break;
    }
  }

  return (cxr->flags&cxfTypeMask);
}

//--------------------------------------------------------------
void put_packed_w(FILE *f, ByteOffset i)
{
  for (; i >= 0x80; i >>= 7) {
    fputc( (0x80 | (i&0x7f)), f );
  }
  fputc( (i&0x7f), f );
}

//--------------------------------------------------------------
ByteOffset get_packed_w(FILE *f)
{
  int c;
  ByteOffset i;
  for (i=0, c=fgetc(f); (c&0x80); c=fgetc(f)) {
    i = (i<<7) | (c & 0x7f);
  }
  return (i<<7) | (c & 0x7f);
}


/*======================================================================
 * Utils: .cx file(s)
 */

//--------------------------------------------------------------
cxData *cxDataInit(cxData *cxd, size_t size)
{
  if (size==0) {
    size = CXDATA_DEFAULT_ALLOC;
  }
  if (!cxd) {
    cxd = (cxData*)malloc(sizeof(cxData));
    assert(cxd != NULL /* malloc failed */);
  }
  cxd->data = (cxRecord*)malloc(size*sizeof(cxRecord));
  assert(cxd->data != NULL /* malloc failed */);
  cxd->len   = 0;
  cxd->alloc = size;
  return cxd;
}

//--------------------------------------------------------------
cxRecord *cxDataPush(cxData *cxd, cxRecord *cx)
{
  if (cxd->len+1 >= cxd->alloc) {
    //-- whoops: must reallocate
    cxd->data = (cxRecord*)realloc(cxd->data, cxd->alloc*2*sizeof(cxRecord));
    assert(cxd->data != NULL /* realloc failed */);
    cxd->alloc *= 2;
  }
  //-- just push copy raw data, pointers & all
  memcpy(&cxd->data[cxd->len], cx, sizeof(cxRecord));
  return &cxd->data[cxd->len++];
}


//--------------------------------------------------------------
cxData *cxDataLoad(cxData *cxd, FILE *f, const char *filename)
{
  const char *file = filename ? filename : "(null)";
  cxHeader hdr;
  cxStoredRecord cxr;
  uint32_t xmlOffset = 0; //-- current xml byte offset
  uint32_t txOffset = 0; //-- current tx-file offset
  cxRecord cx;

  //-- initialize data
  if (cxd==NULL || cxd->data==NULL) cxd=cxDataInit(cxd,0);
  assert(f!=NULL /* require .cx file */);

  //-- get & check header
  cx_get_header(f, file, &hdr);
  if (!cx_check_header(&hdr,file)) exit(1);

  //-- initialize temporaries
  memset(&cx, 0,sizeof(cx));
  memset(&cxr,0,sizeof(cxr));

  //-- churn cx-records
  while (f && !feof(f) && cx_get_record(f, &cxr, xmlOffset) != cxrEOF) {
    cx.typ  = (cxr.flags & cxfTypeMask);
    cx.xoff = cxr.xoff;
    cx.xlen = cxr.xlen;
    cx.toff = txOffset;
    cx.tlen = cxr.tlen;
    cxDataPush(cxd, &cx);

    //-- update position globals
    xmlOffset = cxr.xoff + cxr.xlen;
    txOffset += cxr.tlen;
  }

  return cxd;
}


/*======================================================================
 * Utils: .bx file(s)
 */

//--------------------------------------------------------------
bxData *bxDataInit(bxData *bxd, size_t size)
{
  if (size==0) size = BXDATA_DEFAULT_ALLOC;
  if (!bxd) {
    bxd = (bxData*)malloc(sizeof(bxData));
    assert(bxd != NULL /* malloc failed */);
  }
  bxd->data = (bxRecord*)malloc(size*sizeof(bxRecord));
  assert(bxd->data != NULL /* malloc failed */);
  bxd->len   = 0;
  bxd->alloc = size;
  return bxd;
}

//--------------------------------------------------------------
bxRecord *bxDataPush(bxData *bxd, bxRecord *bx)
{
  if (bxd->len+1 >= bxd->alloc) {
    //-- whoops: must reallocate
    bxd->data = (bxRecord*)realloc(bxd->data, bxd->alloc*2*sizeof(bxRecord));
    assert(bxd->data != NULL /* realloc failed */);
    bxd->alloc *= 2;
  }
  //-- just push copy raw data, pointers & all
  memcpy(&bxd->data[bxd->len], bx, sizeof(bxRecord));
  return &bxd->data[bxd->len++];
}

//--------------------------------------------------------------
#define INITIAL_BX_LINEBUF_SIZE 1024
bxData *bxDataLoad(bxData *bxd, FILE *f)
{
  bxRecord bx;
  char *linebuf=NULL, *s0, *s1;
  size_t linebuf_alloc=0;
  ssize_t linelen;

  if (bxd==NULL || bxd->data==NULL) bxd=bxDataInit(bxd,0);
  assert(f!=NULL /* require .bx file */);

  //-- init line buffer
  linebuf = (char*)malloc(INITIAL_BX_LINEBUF_SIZE);
  assert(linebuf != NULL /* malloc failed */);
  linebuf_alloc = INITIAL_BX_LINEBUF_SIZE;

  while ( (linelen=getline(&linebuf,&linebuf_alloc,f)) >= 0 ) {
    char *tail;
    if (linebuf[0]=='%' && linebuf[1]=='%') continue;  //-- skip comments

    //-- key
    s0  = linebuf;
    s1  = next_tab_z(s0);
    bx.key = strdup(s0);

    //-- elt
    s0 = s1+1;
    s1 = next_tab_z(s0);
    bx.elt = strdup(s0);

    //-- xoff
    s0 = s1+1;
    s1 = next_tab(s0);
    bx.xoff = strtoul(s0,&tail,0);

    //-- xlen
    s0 = s1+1;
    s1 = next_tab(s0);
    bx.xlen = strtoul(s0,&tail,0);

    //-- toff
    s0 = s1+1;
    s1 = next_tab(s0);
    bx.toff = strtoul(s0,&tail,0);

    //-- tlen
    s0 = s1+1;
    s1 = next_tab(s0);
    bx.tlen = strtol(s0,&tail,0);

    //-- otoff
    s0 = s1+1;
    s1 = next_tab(s0);
    bx.otoff = strtoul(s0,&tail,0);

    //-- otlen
    s0 = s1+1;
    s1 = next_tab(s0);
    bx.otlen = strtol(s0,&tail,0);

    bxDataPush(bxd, &bx);
  }

  //-- cleanup & return
  if (linebuf) free(linebuf);
  return bxd;
}

/*======================================================================
 * Utils: indexing
 */

//--------------------------------------------------------------
/* tx2cxIndex()
 *  + allocates & populates tb2ci lookup vector: cxRecord *cx = tx2cx->data[tx_byte_index]
 *  + requires loaded, non-empty cxdata
 */
Offset2CxIndex  *tx2cxIndex(Offset2CxIndex *txo2cx, cxData *cxd)
{
  cxRecord *cx;
  ByteOffset ntxb, cxi, txi, t_end;
  assert(cxd != NULL && cxd->data != NULL /* require loaded cx data */);
  /*assert(cxd->len > 0 "require non-empty cx index"); */

  //-- maybe allocate top-level index struct
  if (txo2cx==NULL) {
    txo2cx = (Offset2CxIndex*)malloc(sizeof(Offset2CxIndex));
    assert(txo2cx != NULL /* malloc failed */);
    txo2cx->data = NULL;
    txo2cx->len  = 0;
  }

  //-- get number of required records, maybe (re-)allocate index vector
  cx   = cxd->len > 0 ? (&cxd->data[cxd->len-1]) : NULL;
  ntxb = cx           ? (cx->toff + cx->tlen)    : 0;
  if (txo2cx->len < ntxb) {
    if (txo2cx->data) free(txo2cx->data);
    txo2cx->data = (cxRecord**)malloc(ntxb*sizeof(cxRecord*));
    assert(txo2cx->data != NULL /* malloc failed for tx-byte to cx-record lookup vector */);
    memset(txo2cx->data, 0, ntxb*sizeof(cxRecord*)); //-- zero the block
    txo2cx->len = ntxb;
  }

  //-- ye olde loope
  for (cxi=0; cxi < cxd->len; cxi++) {
    //-- map ALL tx-bytes generated by this 'c' to a pointer (may cause token overlap (which is handled later))
    cx = &cxd->data[cxi];
    t_end = cx->toff+cx->tlen;
    for (txi=cx->toff; txi < t_end; txi++) {
      txo2cx->data[txi] = cx;
    }
  }

  return txo2cx;
}

//--------------------------------------------------------------
/* txt2cxIndex()
 *  + allocates & populates txtb2cx lookup vector: cxRecord *cx = txtb2cx[txt_byte_index]
 *  + also sets cx->bxp to point to block from bxd
 *  + requires:
 *    - populated bxdata[] vector (see loadBxFile())
 *    - populated txb2ci[] vector (see init_txb2ci())
 */
Offset2CxIndex *txt2cxIndex(Offset2CxIndex *txto2cx, bxData *bxd, Offset2CxIndex *txb2cx)
{
  bxRecord *bx;
  ByteOffset ntxtb, bxi, txti;
  assert(bxd != NULL && bxd->data != NULL /* require loaded bx data */);
  assert(bxd->len > 0    /* require non-empty bx index */);

  //-- maybe allocate top-level index struct
  if (txto2cx==NULL) {
    txto2cx = (Offset2CxIndex*)malloc(sizeof(Offset2CxIndex));
    assert(txto2cx != NULL /* malloc failed */);
    txto2cx->data = NULL;
    txto2cx->len  = 0;
  }

  //-- get number of required records, maybe (re-)allocate index vector
  bx      = &bxd->data[bxd->len-1];
  ntxtb   = bx->otoff + bx->otlen;
  if (txto2cx->len < ntxtb) {
    if (txto2cx->data) free(txto2cx->data);
    txto2cx->data = (cxRecord**)malloc(ntxtb*sizeof(cxRecord*));
    assert(txto2cx->data != NULL /* malloc failed for tx-byte to cx-record lookup vector */);
    memset(txto2cx->data, 0, ntxtb*sizeof(cxRecord*)); //-- zero the block
    txto2cx->len = ntxtb;
  }

  //-- ye olde loope
  for (bxi=0; bxi < bxd->len; bxi++) {
    bx = &bxd->data[bxi];
    if (bx->tlen > 0) {
      //-- "normal" text which SHOULD have corresponding cx records
      for (txti=0; txti < bx->otlen; txti++) {
	cxRecord *cx = txb2cx->data[bx->toff+txti];
	txto2cx->data[bx->otoff+txti] = cx;
	if (cx != NULL) cx->bxp = bx; //-- cache block pointer for cx
      }
    }
    //-- hints and other pseudo-text with NO cx records are mapped to NULL (via memset(), above)
  }

  return txto2cx;
}

//--------------------------------------------------------------
int cx_is_adjacent(const cxRecord *cx1, const cxRecord *cx2) {
  if (!cx1 || !cx2) return 0;				//-- NULL records block adjacency
  if (cx1->xoff+cx1->xlen == cx2->xoff) return 1;	//-- immediate XML adjaceny at byte-level
  if (cx1->bxp==cx2->bxp && cx2==(cx1+1)) return 1;	//-- immediate adjacency in .cx-file within a single block from .bx-file
  return 0;
}

