//-*- Mode: C; c-basic-offset: 2; -*-
#include "dtatwCommon.h"

/*======================================================================
 * Globals
 */

// VERBOSE_IO : whether to print progress messages for load/save
//#define VERBOSE_IO 1
#undef VERBOSE_IO

// SUPPRESS_HEADER_COMMENTS : define this to suppress header comments into output file
//  + non-suppression can lead to errors of the form:
//     :10: parser error : Double hyphen within comment:
//      <!-- base=1949%_%27%_%wenn-zelluloidgoetter-reden
//      <!-- base=1949%_%27%_%wenn-zelluloidgoetter-reden--_TEIexport.xml -->
//    in subsequent processing steps (example from dwds)
//  + errors should disappear now with put_escaped_cmt_str() in dta-tokwrap v0.55
#undef SUPPRESS_HEADER_COMMENTS

//-- want_profile: if true, some profiling information will be printed to stderr
//int want_profile = 1;
int want_profile = 0;
//
ByteOffset nxbytes = 0; //-- for profiling: approximate number of xml-bytes in original input (from location field)
ByteOffset ntoks   = 0; //-- for profiling: number of tokens (from .xt file)

//-- indentation constants (set these to empty strings to output size-optimized XML)
const char *indent_root = "\n"; //-- pre-indentation for root (<sentences>)
const char *indent_s    = "\n"; //-- pre-indentation for <s>, </s>
const char *indent_w    = "\n"; //-- pre-indentation for <w>
const char *indent_alw  = "";	//-- pre-indentation for </w> following non-empty <toka>
const char *indent_al   = "";   //-- pre-indentation for <toka> within <w>
const char *indent_a    = "";   //-- pre-indentation for <a> within <toka>

//-- xml structure constants (should jive with 'mkbx0', 'mkbx')
const char *docElt = "sentences";  //-- output document element
const char *sElt   = "s";          //-- output sentence element
const char *pnAttr = "pn";         //-- output paragraph-number attribute (for sentences)
const char *wElt   = "w";          //-- output token element
const char *alElt  = "toka";	   //-- output token-analyses element
const char *aElt   = "a";          //-- output token-analysis element
const char *tbAttr  = "b";    	   //-- output .txt byte-position attribute ( b="OFFSET LEN")
const char *xbAttr  = "xb";    	   //-- output .xml byte-position attribute (xb="OFFSET_0+LEN_0... OFFSET_N+LEN_N")
const char *textAttr = "t";        //-- output token-text attribute

/*======================================================================
 * Utils: .tt
 */
const char *tt_filename = "(?)";
unsigned int tt_linenum = 1;
unsigned int s_id_ctr = 0;  //-- counter for generated //s/@(xml:)?id
unsigned int w_id_ctr = 0;  //-- counter for generated //w/@(xml:)?id
unsigned int s_pn_ctr = 0;  //-- counter for generated //s/@pn (paragraph number ~ preceding number of $SB$ hints)

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
  int   s_open = 0;          		//-- bool: is an <s> element currently open?
  char *w_text, *w_tloc, *w_xloc, *w_rest, *tail;	//-- temps for input parsing
  ByteOffset w_off,w_len;		//-- location offset, for estimating number of xml bytes

  //-- sanity checks
  assert(f_in != NULL /* no .tt input file? */);
  assert(f_out != NULL /* no .xml output file? */);

  //-- init line buffer
  linebuf = (char*)malloc(INITIAL_TT_LINEBUF_SIZE);
  assert(linebuf != NULL /* malloc failed */);
  linebuf_alloc = INITIAL_TT_LINEBUF_SIZE;

  //-- init error reporting globals
  tt_linenum = 0;
  tt_filename = filename_in;

  //-- ye olde loope
  while ( (linelen=getline(&linebuf,&linebuf_alloc,f_in)) >= 0 ) {
    ++tt_linenum;

    //-- chomp newline (and maybe carriage return)
    if (linelen>0 && linebuf[linelen-1]=='\n') linebuf[--linelen] = '\0';
    if (linelen>0 && linebuf[linelen-1]=='\r') linebuf[--linelen] = '\0';

    //-- check for comments
    if (linebuf[0]=='%' && linebuf[1]=='%') {
      if (strcmp(linebuf+2,"$SB$")==0) {
	//-- tokenizer $SB$ hint: increment paragraph counter
	++s_pn_ctr;
      }
      //-- other comment (e.g "base=\"BASE\"),
      fputs("\n<!--", f_out);
      put_escaped_cmt_str(f_out, linebuf+2, -1);
      if (linebuf[2]==' ') fputc(' ', f_out);		//-- add a trailing space for leading-space tt-comments
      fputs("-->", f_out);
      continue;
    }

    //-- check for EOS (blank line)
    if (linebuf[0]=='\0') {
      if (s_open) {
	fprintf(f_out,"%s</%s>", indent_s, sElt);
	s_open = 0;
      }
      continue;
    }

    //-- word: inital parse into strings (w_text, w_tloc, w_xloc, w_rest)
    w_text = linebuf;
    w_tloc = next_tab_z(w_text)+1;
    w_xloc = next_char_z(w_tloc,'~')+1;
    w_rest = next_tab_z(w_xloc)+1;

    //-- output: BOS
    if (!s_open) {
      fprintf(f_out, "%s<%s %s=\"s%x\" %s=\"p%x\">", indent_s, sElt, xmlid_name, ++s_id_ctr, pnAttr, s_pn_ctr);
      s_open = 1;
    }

    //-- output: w: begin: open <w ...>
    fprintf(f_out, "%s<%s %s=\"w%x\"", indent_w, wElt, xmlid_name, ++w_id_ctr);

    //-- output: w: text
    if (textAttr) {
      fprintf(f_out, " %s=\"", textAttr);
      put_escaped_str(f_out, w_text, -1);
      fputc('"', f_out);
    }

    //-- output: w: location: .txt
    if (tbAttr) {
      fprintf(f_out, " %s=\"%s\"", tbAttr, w_tloc);
    }

    //-- output: w: location: .xml
    if (xbAttr) {
      fprintf(f_out, " %s=\"%s\"", xbAttr, w_xloc);
    }

    //-- output: w: analyses (finishing <w ...>, also writing </w> if required)
    if (*w_rest) {
      fprintf(f_out, ">%s<%s>", indent_al, alElt);
      do {
	tail = next_tab(w_rest);
	fprintf(f_out, "%s<%s>", indent_a, aElt);
	put_escaped_str(f_out, w_rest, tail-w_rest);
	fprintf(f_out, "</%s>", aElt);
	if (tail && *tail) tail++;
	w_rest = tail;
      } while (*w_rest);
      fprintf(f_out, "%s</%s>%s</w>", indent_al, alElt, (*indent_al ? indent_w : ""));
    } else {
      //-- no analyses: empty word
      fputs("/>", f_out);
    }

    //-- profile
    if (want_profile) {
      ++ntoks;
      w_off = strtoul(w_xloc,  &tail, 0);
      w_len = (tail[0] && tail[1] ? strtoul(tail+1, &tail, 0) : 0);
      if (w_off+w_len > nxbytes) nxbytes = w_off+w_len;
    }
  }

  //-- close open sentence if any
  if (s_open) fprintf(f_out, "%s</%s>", indent_s, sElt);

  //-- cleanup
  if (linebuf) free(linebuf);
}

/*======================================================================
 * MAIN
 */
int main(int argc, char **argv)
{
  char *filename_in  = "-";
  char *filename_out = "-";
  char *xmlbase = NULL;  //-- root @xml:base attribute (or basename)
  char *xmlsuff = "";    //-- additional suffix for root @xml:base
  FILE *f_in  = stdin;   //-- input .t file
  FILE *f_out = stdout;  //-- output .xml file

  //-- initialize: globals
  prog = file_basename(NULL,argv[0],"",-1,0);

  //-- command-line: usage
  if (argc <= 1) {
    fprintf(stderr, "(%s version %s / %s)\n", PACKAGE, PACKAGE_VERSION, PACKAGE_SVNID);
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, " %s XTFILE [OUTFILE [XMLBASE]]\n", prog);
    fprintf(stderr, " + XTFILE  : tokenizer output file (including offsets)\n");
    fprintf(stderr, " + OUTFILE : output XML file (default=stdout)\n");
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
  //-- command-line: output file
  if (argc > 2) {
    filename_out = argv[2];
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
  if (argc > 3) {
    xmlbase = argv[3];
    xmlsuff = "";
  } else if (filename_in && filename_in[0] && strcmp(filename_in,"-") != 0) {
    xmlbase = file_basename(NULL, filename_in, ".xt", -1,0);
    xmlsuff = ".xml";
  } else if (filename_out && filename_out[0] && strcmp(filename_out,"-") != 0) {
    xmlbase = file_basename(NULL, filename_out, ".t.xml", -1,0);
    xmlsuff = ".xml";
  } else {
    xmlbase = NULL; //-- couldn't guess xml:base
  }

  //-- print basic XML header
  fprintf(f_out, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
#ifdef VERBOSE_HEADER_COMMENTS
  {
    int i;
    fprintf(f_out, "<!--\n");
    fprintf(f_out, " ! File created by %s (%s version %s)\n", prog, PACKAGE, PACKAGE_VERSION);
    fprintf(f_out, " ! Command-line: %s", argv[0]);
    for (i=1; i < argc; i++) {
      fputs(" '", f_out);
      put_escaped_cmt_string(f_out, (argv[i][0] ? argv[i] : ""), -1);
      fputc('\'', f_out);
    }
    fputs("\n !-->\n", f_out);
  }
#endif

  //-- print XML root element
  fprintf(f_out,"<%s",docElt);
  if (xmlbase && *xmlbase) {
    fputs(" xml:base=\"", f_out);
    put_escaped_str(f_out, xmlbase, -1);
    put_escaped_str(f_out, xmlsuff, -1);
    fputc('"', f_out);
  }
  fputc('>',f_out);

  //-- process .tt-format input data
  process_tt_file(f_in,f_out, filename_in,filename_out);

  //-- print XML footer
  fprintf(f_out, "%s</%s>\n", indent_root, docElt);

  //-- show profile?
  if (want_profile) {
    double elapsed = ((double)clock()) / ((double)CLOCKS_PER_SEC);
    if (elapsed <= 0) elapsed = 1e-5;

    fprintf(stderr, "%s: processed %.1f%s tok ~ %.1f%s t-bytes in %.3f sec: %.1f %stok/sec ~ %.1f %sbyte/sec\n",
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
  if (f_out) fclose(f_out);

  return 0;
}
