#include "dtatwCommon.h"
#include "dtatwExpat.h"

/*======================================================================
 * Globals
 */

typedef struct {
  XML_Parser xp;        //-- expat parser
  unsigned d_cur;
  unsigned d_max;
} ParseData;

/*======================================================================
 * Handlers
 */

//--------------------------------------------------------------
void cb_start(ParseData *data, const XML_Char *name, const XML_Char **attrs)
{
  ++data->d_cur;
  if (data->d_cur > data->d_max) data->d_max = data->d_cur;
}

//--------------------------------------------------------------
void cb_end(ParseData *data, const XML_Char *name)
{
  --data->d_cur;
}

/*======================================================================
 * Utils
 */

void cb_reset(XML_Parser xp, ParseData *data)
{
  XML_ParserReset(xp, "UTF-8");
  XML_SetUserData(xp, data);
  XML_SetElementHandler(xp, (XML_StartElementHandler)cb_start, (XML_EndElementHandler)cb_end);
  data->xp    = xp;
  data->d_cur = 0;
  data->d_max = 0;
}

/*======================================================================
 * MAIN
 */
int main(int argc, char **argv)
{
  ParseData data;
  XML_Parser xp;
  char*  infile_default = "-";
  char** infilesv;
  int    infilesc;
  int    filei;

  //-- initialize: globals
  prog = file_basename(NULL,argv[0],"",-1,0);

  //-- command-line: usage
  if (argc <= 1) {
    fprintf(stderr, "(%s version %s / %s)\n", PACKAGE, PACKAGE_VERSION, PACKAGE_SVNID);
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, " %s INFILE(s)...\n", prog);
    fprintf(stderr, " + INFILE  : XML source file(s)\n");
    exit(1);
  }
  //-- command-line: input file
  if (argc > 1) {
    infilesv = (argv+1);
    infilesc = argc-1;
  }
  else {
    infilesv = &infile_default;
    infilesc = 1;
  }

  //-- setup expat parser
  xp = XML_ParserCreate("UTF-8");
  if (!xp) {
    fprintf(stderr, "%s: XML_ParserCreate failed", prog);
    exit(1);
  }
  
  //-- ye olde loope
  for (filei=0; filei < infilesc; ++filei) {
    char *filename_in = infilesv[filei];
    FILE *f_in = stdin;
    if ( strcmp(filename_in,"-")!=0 && !(f_in=fopen(filename_in,"rb")) ) {
      fprintf(stderr, "%s: open failed for input file `%s': %s\n", prog, filename_in, strerror(errno));
      exit(1);
    }

    //-- parse input file
    cb_reset(xp, &data);
    expat_parse_file(xp, f_in, filename_in);
    if (f_in && f_in != stdin) fclose(f_in);

    //-- report & cleanup
    printf("%u\t%s\n", data.d_max, filename_in);
  }

  //-- cleanup
  if (xp) XML_ParserFree(xp);

  return 0;
}
