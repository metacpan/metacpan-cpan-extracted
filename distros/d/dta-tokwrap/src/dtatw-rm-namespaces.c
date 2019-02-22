#include "dtatwCommon.h"
#include "dtatwExpat.h"

/*======================================================================
 * Globals
 */

const char colon_out  = '_'; //-- replaces ':' in output element, attribute names
const char *xmlns_out = "_xmlns"; //-- replaces literal 'xmlns' attributes

typedef struct {
  XML_Parser xp;        //-- expat parser
  FILE *f_out;          //-- output file
} ParseData;

/*======================================================================
 * Utils
 */

//--------------------------------------------------------------
void put_hacked_string(ParseData *data, const XML_Char *str, int len, int doEscape)
{
  int i;
  for (i=0; str[i] && (len < 0 || i < len); i++) {
    if (str[i]==':'
	&& (i!=3 || strncmp(str,"xml:",3)!=0) 	//-- only hack non-"xml:" namespaces
	)
      {
	fputc(colon_out, data->f_out);
      }
    else if (doEscape) { put_escaped_char(data->f_out, str[i]); }
    else { fputc(str[i], data->f_out); }
  }
}


/*======================================================================
 * Handlers
 */

//--------------------------------------------------------------
void cb_start(ParseData *data, const XML_Char *name, const XML_Char **attrs)
{
  int i;
  int clen;
  const char *cbuf = get_event_context(data->xp, &clen);
  fputc('<', data->f_out);
  put_hacked_string(data, name, -1, 1);
  for (i=0; attrs[i]; i += 2) {
    fputc(' ', data->f_out);
    if (strcmp(attrs[i],"xmlns")==0) { fputs(xmlns_out,data->f_out); }
    else { put_hacked_string(data, attrs[i], -1, 1); }
    fputs("=\"", data->f_out);
    put_escaped_str(data->f_out, attrs[i+1], -1);
    fputc('"', data->f_out);
  }
  if (cbuf[clen-2] == '/') { fputs("/>",data->f_out); }
  else { fputc('>', data->f_out); }
}

//--------------------------------------------------------------
void cb_end(ParseData *data, const XML_Char *name)
{
  int clen;
  const char *cbuf = get_event_context(data->xp, &clen);
  put_hacked_string(data, cbuf, clen, 0);
}

//--------------------------------------------------------------
void cb_default(ParseData *data, const XML_Char *s, int len)
{
  fwrite(s,1,len,data->f_out);
}

/*======================================================================
 * MAIN
 */
int main(int argc, char **argv)
{
  ParseData data;
  XML_Parser xp;
  char *filename_in  = "-";
  char *filename_out = "-";
  FILE *f_in  = stdin;   //-- input file
  FILE *f_out = stdout;  //-- output file

  //-- initialize: globals
  prog = file_basename(NULL,argv[0],"",-1,0);

  //-- command-line: usage
  if (argc <= 1) {
    fprintf(stderr, "(%s version %s / %s)\n", PACKAGE, PACKAGE_VERSION, PACKAGE_SVNID);
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, " %s INFILE [OUTFILE]\n", prog);
    fprintf(stderr, " + INFILE  : XML source file with namespaces\n");
    fprintf(stderr, " + OUTFILE : XML output file, will have pseudo-namespaces\n");
    exit(1);
  }
  //-- command-line: input file
  if (argc > 1) {
    filename_in = argv[1];
    if ( strcmp(filename_in,"-")!=0 && !(f_in=fopen(filename_in,"rb")) ) {
      fprintf(stderr, "%s: open failed for input file `%s': %s\n", prog, filename_in, strerror(errno));
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
      fprintf(stderr, "%s: open failed for output file `%s': %s\n", prog, filename_out, strerror(errno));
      exit(1);
    }
  }

  //-- setup expat parser
  xp = XML_ParserCreate("UTF-8");
  if (!xp) {
    fprintf(stderr, "%s: XML_ParserCreate failed", prog);
    exit(1);
  }
  XML_SetUserData(xp, &data);
  XML_SetElementHandler(xp, (XML_StartElementHandler)cb_start, (XML_EndElementHandler)cb_end);
  XML_SetDefaultHandler(xp, (XML_DefaultHandler)cb_default);

  //-- setup callback data
  memset(&data,0,sizeof(data));
  data.xp  = xp;
  data.f_out = f_out;

  //-- parse input file
  expat_parse_file(xp, f_in, filename_in);

  //-- cleanup
  if (f_in)  fclose(f_in);
  if (f_out) fclose(f_out);
  if (xp) XML_ParserFree(xp);

  return 0;
}
