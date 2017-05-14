
/* Below is a fragment of code for using FS_example.pl with C. */

  char file_select_cmd[] =
"/u/somebody/lib/MyPerl/Tk/FS_example.pl -startdir /u/somebody/VOLVIZ/data/ -filter \\*.hdr.ascii";

  int i;
  char filename[256];
  char opcode[32];
  char *string_match;

  FILE *popen(); /* IBM xlc thinks popen is an integer */
  FILE *pipe;

  pipe = popen(file_select_cmd,"r");
  fscanf(pipe,"%s %s", opcode, filename);
  pclose(pipe);
  /*
   * Below is for the specific case that "Read" is expect.  Other
   * opcode cases could be "Write" or "Cancel".
   */
  i = strcmp(opcode,"Read");
  if(i != 0){
    fprintf(stderr," Error, File Select did not return Read request\n");
    return 2;
  }
  /*
   * That's all folks.  The rest is a particular usage of the filename.
   */
  string_match = strstr(filename,".hdr.ascii");
  if(string_match == NULL){
    fprintf(stderr," Error, did not find suffix .hdr.ascii\n");
    return 3;
  }
  /*
   * The VrReadHdrDotAscii program does not want the suffix part,
   * so insert a string ending null where the suffix begins.
   */
  *string_match = 0;

  istatus = VrReadHdrDotAscii(filename,
                              dim, VoxSize,
                              BoundboxMin, BoundboxMax,
                              &Min_tmp, &Max_tmp);

