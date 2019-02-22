#include "dtatwCommon.h"

/*======================================================================
 * Globals
 */

// VERBOSE_IO : whether to print progress messages for load/save
//#define VERBOSE_IO 1
#undef VERBOSE_IO

// WARN_ON_OVERLAP : whether to output warnings when token overlap is detected
//  + whether or not this is defined, tokens where overlap was detected will be commented out
#define WARN_ON_OVERLAP 1
//#undef WARN_ON_OVERLAP

// WARN_ON_NOCX : whether to output warnings when token without cx record is detected
//  + whether or not this is defined, tokens with no cx records will be commented out
#define WARN_ON_NOCX 1
//#undef WARN_ON_NOCX

//-- want_profile: if true, some profiling information will be printed to stderr
//int want_profile = 1;
int want_profile = 0;
//
ByteOffset nxbytes = 0; //-- for profiling: approximate number of xml bytes in original input (from .cx file)
ByteOffset ntoks   = 0; //-- for profiling: number of tokens (from .t file)

/*======================================================================
 * Utils: .cx, .bx file, indexing
 *  + now in dtatwCommon.[ch]
 */
cxData cxdata = {NULL,0,0};       //-- cxRecord *cx = &cxdata->data[c_index]
bxData bxdata = {NULL,0,0};       //-- bxRecord *bx = &bxdata->data[block_index]

Offset2CxIndex txb2cx  = {NULL,0};  //-- cxRecord *cx =  txb2cx->data[ tx_byte_index]
Offset2CxIndex txtb2cx = {NULL,0};  //-- cxRecord *cx = txtb2cx->data[txt_byte_index]

/*======================================================================
 * Utils: .tt
 */

static const ByteLen CX_CLAIMED = (ByteLen)-1;

//--------------------------------------------------------------
// bool = cx_claimed(cx)
//  + returns true iff cx has been claimed by some token
//  + hack tests cx->tlen==(ByteLen)-1
static inline int cx_claimed(const cxRecord *cx)
{
  return cx && cx->tlen==CX_CLAIMED;
}

//--------------------------------------------------------------
// undef = cx_claim(cx)
//  + claims cx record cx by setting cx->xlen=0
//  + hack sets cx->tlen=(ByteLen)-1
static inline void cx_claim(cxRecord *cx)
{
  if (cx) cx->tlen = CX_CLAIMED;
}

//--------------------------------------------------------------
/* bool = cx_elt_ok(cx)
 *  + returns true iff cx is a "real" character record with a valid element name, etc.
 *  + bad names: none
 *  + see dtatwCommon.h for id constants
 */
static inline int cx_elt_ok(const cxRecord *cx)
{
  return (cx != NULL
	  //&& cx->elt
	  //&& cx->elt[0]
	  //&& strcmp(cx->id,CX_NIL_ID) !=0
	  //&& strncmp(cx->id,CX_FORMULA_PREFIX,strlen(CX_FORMULA_PREFIX)) !=0
	  //&& strcmp(cx->id,CX_LB_ID) !=0
	  //&& strcmp(cx->id,CX_PB_ID) !=0
	  );
}


//--------------------------------------------------------------
/* Typedef(s) for .tt "word buffer"
 */
#define WORDBUF_TEXT_LEN 8192
#define WORDBUF_CX_LEN   8192
#define WORDBUF_REST_LEN 8192

//-- flags for ttWordBuffer
typedef enum {
  ttwNone  = 0x0000,    //-- no special flags
  ttwSB    = 0x0001,    //-- whether we saw a sentence boundary before this word
  ttwOver  = 0x0004,    //-- did this word overlap?
  ttwNoCx  = 0x0008,	//-- is this word missing any cx-record?
  ttwAll   = 0x000f,    //-- all flags
} ttWordFlags;


typedef struct {
  unsigned int w_flags;                //-- mask of ttWordFlags flags
  ByteOffset w_off;                    //-- .txt byte offset, as reported by tokenizer
  ByteOffset w_len;                    //-- .txt byte length, as reported by tokenizer
  char       w_text[WORDBUF_TEXT_LEN]; //-- word text buffer
  char       w_rest[WORDBUF_REST_LEN]; //-- word analyses buffer (TAB-separated)
  cxRecord  *w_cx  [WORDBUF_CX_LEN];   //-- word .cx buffer
} ttWordBuffer;

//--------------------------------------------------------------
// global temps for output construction
#define WORD_XMLPOS_LEN 8192
char w_xmlpos[WORD_XMLPOS_LEN];

//--------------------------------------------------------------
/* tt_dump_word(f_out, w1)
 *  + checks for pathological conditions on word boundaries
 *  + s_open is a flag indicating whether a sentence-element is currently open
 */
unsigned int tt_linenum = 1;
const char *tt_filename = "(?)";
static void tt_dump_word(FILE *f_out, ttWordBuffer *w)
{
  int i,j;
  char     *xmlpos   = w_xmlpos;
  ByteOffset xmlend  = (ByteOffset)-1;
  cxRecord *icx, *jcx, *jcx_prev;

  //-- compute xml-bytes
  *xmlpos = '\0';
  for (i=0; i < w->w_len; i=j+1) {
    icx    = jcx_prev = txtb2cx.data[w->w_off+i];
    xmlend = icx ? (icx->xoff + icx->xlen) : (ByteOffset)-1;

    for (j=i; j<w->w_len; j++) {
      jcx = txtb2cx.data[w->w_off+j];
      if (jcx && jcx->claimed > 1) {
#if WARN_ON_OVERLAP
	if ( !(w->w_flags&ttwOver) )
	  fprintf(stderr, "%s: WARNING: `%s' line %u: overlapping word `%s' at XML-byte %u (elt=%s)\n",
		  prog, tt_filename, tt_linenum, w->w_text,
		  (uint)(jcx ? jcx->xoff : 0),
		  (jcx ? cxTypeNames[jcx->typ] : "?"));
#endif
	w->w_flags |= ttwOver;
	break;
      }
      if (jcx==jcx_prev) continue; //-- ignore word-internal duplicates
      if (!cx_elt_ok(jcx) || !cx_is_adjacent(jcx_prev,jcx)) {
	--j;
	break;
      }

      jcx->claimed = 1;
      jcx_prev = jcx;
      xmlend   = jcx->xoff + jcx->xlen;
    }

    //-- append to position buffer
    if (!icx) {
      //-- null character: ignore
      continue;
    } else if (icx->claimed <= 1) {
      //-- append: unclaimed initial character
      xmlpos += sprintf(xmlpos, " %u+%d", (uint)icx->xoff, (int)(xmlend - icx->xoff));
    } else if (icx->claimed > 1) {
      //-- append: claimed character
      xmlpos += sprintf(xmlpos, " %u+%d", (uint)icx->xoff, 0);
    }
  }
  if (w_xmlpos[0]) w_xmlpos[0] = '~';
  else {
#if WARN_ON_NOCX
    fprintf(stderr, "%s: WARNING: `%s' line %u: no cx-records for word `%s' at txt-byte %u\n",
	    prog, tt_filename, (uint)tt_linenum, w->w_text, (uint)w->w_off);
#endif
    w->w_flags |= ttwNoCx; //-- no cx-record(s) for this word: wtf?
  }

  //-- claim all characters
  for (i=0; i < w->w_len; ++i) {
    if ((icx = txtb2cx.data[w->w_off+i])) icx->claimed = 2;
#ifdef DTATW_DEBUG_OVERLAP
    //-- "CLAIM" "\t" xoff xlen "\t" wtext "\t" txtoff txtlen "\n"
    fprintf(stderr, "CLAIM\t%u %u\t%s\t%u %u\n",
	    (uint)(icx ? icx->xoff : 0), (uint)(icx ? icx->xlen : 0),
	    (w ? w->w_text : ""),
	    (uint)(w ? w->w_off : 0), (uint)(w ? w->w_len : 0));
#endif
  }

  //-- dump: bad-flag (comment)
  if      (w->w_flags & ttwOver) fputs("%%$OVERLAP\t", f_out);
  else if (w->w_flags & ttwNoCx) fputs("%%$NOCX\t", f_out);

  //-- dump: text
  fputs(w->w_text, f_out);

  //-- dump: byte offsets: "TOFF TLEN @ XOFF1+XLEN1 XOFF2+XLEN2 ... XOFFn+XLENn"
  fprintf(f_out, "\t%u %u%s", (uint)w->w_off, (uint)w->w_len, w_xmlpos);

  //-- dump: rest
  if (w->w_rest[0]) {
    fputc('\t', f_out);
    fputs(w->w_rest, f_out);
  }
  fputc('\n',f_out);

  //-- update: profiling information
  ++ntoks;

  //-- update: clear word
  memset(w, 0, sizeof(ttWordBuffer));
#if 0
  w->w_flags = ttwNone;
  w->w_off   = 0;
  w->w_len   = 0;
  w->w_text[0] = '\0';
  w->w_rest[0] = '\0';
  w->w_cx[0]   = NULL;
#endif
}

//--------------------------------------------------------------
/* process_tt_file()
 *  + requires:
 *    - populated cxdata struct (see cxDataLoad() in dtatwCommon.c)
 *    - populated txtb2cx struct (see txt2cxIndex() in dtatwCommon.c)
 */
#define INITIAL_TT_LINEBUF_SIZE 8192
static void process_tt_file(FILE *f_in, FILE *f_out, char *filename_in, char *filename_out)
{
  char *linebuf=NULL; //, *s0, *s1;
  size_t linebuf_alloc=0;
  ssize_t linelen;
  int last_was_eos = 1;          //-- bool: was the last line read an EOS?
  char *w_text, *w_loc, *w_loc_tail, *w_rest;  //-- temps for input parsing
  ttWordBuffer w;     //-- word buffer(s);

  //-- sanity checks
  assert(f_in != NULL /* no .tt input file? */);
  assert(f_out != NULL /* no .xml output file? */);
  assert(cxdata.data != NULL /* require .cx data */);
  assert(txtb2cx.data != NULL /* require txt-byte -> cx-pointer lookup vector */);

  //-- init line buffer
  linebuf = (char*)malloc(INITIAL_TT_LINEBUF_SIZE);
  assert(linebuf != NULL /* malloc failed */);
  linebuf_alloc = INITIAL_TT_LINEBUF_SIZE;

  //-- init error reporting globals
  tt_linenum = 0;
  tt_filename = filename_in;

  //-- init word buffer(s)
  memset(&w, 0, sizeof(ttWordBuffer));

  //-- ye olde loope
  while ( (linelen=getline(&linebuf,&linebuf_alloc,f_in)) >= 0 ) {
    ++tt_linenum;
    if (linebuf[0]=='%' && linebuf[1]=='%') {
	//-- comment: just dump
	fwrite(linebuf, linelen, 1, f_out);
	continue;
    }

    //-- chomp newline (and maybe carriage return)
    if (linelen>0 && linebuf[linelen-1]=='\n') linebuf[--linelen] = '\0';
    if (linelen>0 && linebuf[linelen-1]=='\r') linebuf[--linelen] = '\0';

    //-- check for EOS (blank line)
    if (linebuf[0]=='\0') {
      if (!last_was_eos) fputc('\n',f_out);
      last_was_eos = 1;
      continue;
    }
    last_was_eos = 0;

    //-- word: inital parse into strings (w_text, w_loc, w_rest)
    w_text = linebuf;
    w_loc  = next_tab_z(w_text)+1;
    w_rest = next_tab_z(w_loc)+1;
    assert(w_loc-w_text < WORDBUF_TEXT_LEN /* buffer overflow */);
    assert(linelen-(w_rest-w_text) < WORDBUF_REST_LEN /* buffer overflow */);

    //-- word: parse to buffer 'w'
    w.w_off = strtoul(w_loc,      &w_loc_tail, 0);
    w.w_len = strtoul(w_loc_tail, NULL,        0);
    strcpy(w.w_text, w_text);
    strcpy(w.w_rest, w_rest);

    //-- word: populate w.w_cx[] buffer
    assert(w.w_len < WORDBUF_CX_LEN /* buffer overflow */);
    assert(w.w_off+w.w_len <= txtb2cx.len /* positioning error would cause segfault */);
    memcpy(w.w_cx, txtb2cx.data+w.w_off, w.w_len*sizeof(cxRecord*));
    w.w_cx[w.w_len] = NULL;

    //-- word: delegate output to boundary-condition checker
    tt_dump_word(f_out, &w);
  }
  if (!last_was_eos) fputc('\n',f_out);

  //-- cleanup
  if (linebuf) free(linebuf);
}

/*======================================================================
 * MAIN
 */
int main(int argc, char **argv)
{
  char *filename_in  = "-";
  char *filename_cx  = NULL;
  char *filename_bx  = NULL;
  char *filename_out = "-";
  char *xmlbase = NULL;  //-- root @xml:base attribute (or basename)
  char *xmlsuff = "";    //-- additional suffix for root @xml:base
  FILE *f_in  = stdin;   //-- input .t file
  FILE *f_cx  = NULL;    //-- input .cx file
  FILE *f_bx  = NULL;    //-- input .tx file
  FILE *f_out = stdout;  //-- output .xml file
  int i;

  //-- initialize: globals
  prog = file_basename(NULL,argv[0],"",-1,0);

  //-- command-line: usage
  if (argc <= 3) {
    fprintf(stderr, "(%s version %s / %s)\n", PACKAGE, PACKAGE_VERSION, PACKAGE_SVNID);
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, " %s TFILE CXFILE BXFILE [OUTFILE [XMLBASE]]\n", prog);
    fprintf(stderr, " + TFILE   : raw tokenizer output file\n");
    fprintf(stderr, " + CXFILE  : character index file as created by dtatw-mkindex\n");
    fprintf(stderr, " + BXFILE  : block index file as created by dta-tokwrap.perl\n");
    fprintf(stderr, " + OUTFILE : output tokensizer file with xml-byte offsets instead of text-bytes (default=stdout)\n");
    fprintf(stderr, " + XMLBASE : root xml:base attribute value for output file\n");
    fprintf(stderr, " + \"-\" may be used in place of any filename to indicate standard (in|out)put\n");
    exit(1);
  }
  //-- command-line: input file
  if (argc > 1) {
    filename_in = argv[1];
    if (strcmp(filename_in,"-")==0) f_in = stdin;
    else if ( !(f_in=fopen(filename_in,"rb")) ) {
      fprintf(stderr, "%s: open failed for input .t file `%s': %s\n", prog, filename_in, strerror(errno));
      exit(1);
    }
  }
  //-- command-line: .cx file
  if (argc > 2) {
    filename_cx = argv[2];
    if (strcmp(filename_cx,"-")==0) f_cx = stdin;
    else if ( !(f_cx=fopen(filename_cx,"rb")) ) {
      fprintf(stderr, "%s: open failed for input .cx file `%s': %s\n", prog, filename_cx, strerror(errno));
      exit(1);
    }
  }
  //-- command-line: .bx file
  if (argc > 3) {
    filename_bx = argv[3];
    if (strcmp(filename_bx,"-")==0) f_bx = stdin;
    else if ( !(f_bx=fopen(filename_bx,"rb")) ) {
      fprintf(stderr, "%s: open failed for input .bx file `%s': %s\n", prog, filename_bx, strerror(errno));
      exit(1);
    }
  }
  //-- command-line: output file
  if (argc > 4) {
    filename_out = argv[4];
    if (strcmp(filename_out,"")==0) {
      f_out = NULL;
    }
    else if ( strcmp(filename_out,"-")==0 ) {
      f_out = stdout;
    }
    else if ( !(f_out=fopen(filename_out,"wb")) ) {
      fprintf(stderr, "%s: open failed for output XML file `%s': %s\n", prog, filename_out, strerror(errno));
      exit(1);
    }
  }
  //-- command-line: xmlbase
  if (argc > 5) {
    xmlbase = argv[5];
    xmlsuff = "";
  } else if (filename_cx && filename_cx[0] && strcmp(filename_cx,"-") != 0) {
    xmlbase = file_basename(NULL, filename_cx, ".cx", -1,0);
    xmlsuff = ".xml";
  } else if (filename_bx && filename_bx[0] && strcmp(filename_bx,"-") != 0) {
    xmlbase = file_basename(NULL, filename_bx, ".bx", -1,0);
    xmlsuff = ".xml";
  } else if (filename_in && filename_in[0] && strcmp(filename_in,"-") != 0) {
    xmlbase = file_basename(NULL, filename_in, ".t", -1,0);
    xmlsuff = ".xml";
  } else if (filename_out && filename_out[0] && strcmp(filename_out,"-") != 0) {
    xmlbase = file_basename(NULL, filename_out, ".t.xml", -1,0);
    xmlsuff = ".xml";
  } else {
    xmlbase = NULL; //-- couldn't guess xml:base
  }

  //-- load .cx data
  cxDataLoad(&cxdata, f_cx, filename_cx);
  if (f_cx != stdin) fclose(f_cx);
  f_cx = NULL;
#ifdef VERBOSE_IO
  fprintf(stderr, "%s: parsed %zu records from .cx file '%s'\n", prog, (size_t)cxdata.len, filename_cx);
#endif
  

  //-- load .bx data
  bxDataLoad(&bxdata, f_bx);
  if (f_bx != stdin) fclose(f_bx);
  f_bx = NULL;
#ifdef VERBOSE_IO
  fprintf(stderr, "%s: parsed %zu records from .bx file '%s'\n", prog, (size_t)bxdata.len, filename_bx);
  assert(cxdata != NULL && cxdata->data != NULL /* require cxdata */);
  assert(cxdata.len > 0 /* require non-empty cxdata */);
  fprintf(stderr, "%s: number of source XML-bytes ~= %zu\n", prog, (size_t)(cxdata->data[cxdata.len-1].xoff+cxdata->data[cxdata.len-1].xlen));
#endif

  //-- create (tx_byte_index => cx_record) lookup vector
  tx2cxIndex(&txb2cx, &cxdata);
#ifdef VERBOSE_IO
  fprintf(stderr, "%s: initialized %zu-element .tx-byte => .cx-record index\n", prog, (size_t)txb2cx.len);
#endif

  //-- create (txt_byte_index => cx_record_or_NULL) lookup vector
 txt2cxIndex(&txtb2cx, &bxdata, &txb2cx);
#ifdef VERBOSE_IO
 fprintf(stderr, "%s: initialized %zu-element .txt-byte => .cx-record index\n", prog, (size_t)txtb2cx.len);
#endif

  //-- doc header: comments
  fprintf(f_out, "%%%% File created by %s (%s version %s)\n", prog, PACKAGE, PACKAGE_VERSION);
  fprintf(f_out, "%%%% Command-line: %s", argv[0]);
  for (i=1; i < argc; i++) {
    fprintf(f_out, " '%s'", (argv[i][0] ? argv[i] : ""));
  }
  fprintf(f_out, "\n%%%%\n");

  //-- doc header: xmlbase
  if (xmlbase && *xmlbase) {
    fprintf(f_out, "%%%% base=%s%s\n", xmlbase, xmlsuff);
  }


  //-- process .tt-format input data
  process_tt_file(f_in,f_out, filename_in,filename_out);

  //-- show profile?
  if (want_profile) {
    double elapsed = ((double)clock()) / ((double)CLOCKS_PER_SEC);
    if (elapsed <= 0) elapsed = 1e-5;

    assert(cxdata.data != NULL/* profile: require cxdata */);
    assert(cxdata.len > 0 /* profile: require non-empty cxdata */);
    
    //-- approximate number of original source XML bytes
    nxbytes = cxdata.data[cxdata.len-1].xoff + cxdata.data[cxdata.len-1].xlen;

    fprintf(stderr, "%s: processed %.1f%s tok ~ %.1f%s XML bytes in %.3f sec: %.1f %stok/sec ~ %.1f %sbyte/sec\n",
	    prog,
	    si_val(ntoks), si_suffix(ntoks),
	    si_val(nxbytes), si_suffix(nxbytes),
	    elapsed,
	    si_val(ntoks/elapsed), si_suffix(ntoks/elapsed),
	    si_val(nxbytes/elapsed), si_suffix(nxbytes/elapsed)
	    );
  }

  //-- cleanup
  if (f_in)  fclose(f_in);
  if (f_cx)  fclose(f_cx);
  if (f_bx)  fclose(f_bx);
  if (f_out) fclose(f_out);

  return 0;
}
