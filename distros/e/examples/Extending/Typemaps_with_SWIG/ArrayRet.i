%module ArrayRet

%{
char **
test (){
    static char * argv[] = {"abc", "def", "ghi", NULL};
    return argv;
}
%}



%typemap(perl5,out) char ** { /* All functions returning char **  */
                              /* get this typemap                 */
    /* $source is of type char **
     * $target is of type RV (referring to an AV)
     */

    AV *myav;
    SV **svs;
    int i = 0,len = 0;
    /* Figure out how many elements we have */
    while ($source[len])
       len++;
    svs = (SV **) malloc(len*sizeof(SV *));
    for (i = 0; i < len ; i++) {
        svs[i] = sv_newmortal();
        sv_setpv((SV*)svs[i],$source[i]);
    };
    myav =    av_make(len,svs);
    free(svs);
    $target = newRV((SV*)myav);
    sv_2mortal($target);
    argvi++;                      /* IMPORTANT !! */
}


char **test();