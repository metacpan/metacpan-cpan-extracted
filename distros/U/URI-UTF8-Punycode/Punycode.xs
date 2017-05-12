#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "idnfkc.c"
#include "strerr.c"
#include "pcodes.c"

int ex_strlen(void *ptr)
{
  char *chr = (char *)ptr;
  if(chr == NULL){ return 0; }
  else if(chr[0] == '\0'){ return 0 ; }
  return strlen(chr);
}

char *_puny_enc(pTHX_ char *i)
{
  size_t lu, lp;
  uint32_t *q;
  char *p;
  int r;
  q = stringprep_utf8_to_ucs4(i, -1 ,&lu);
  if(!q){
    Perl_warn(aTHX_ "failed stringprep_utf8_to_ucs4");
    return NULL;
  }
  if((p = (char *)malloc(BUFSIZ+5)) == NULL){ return NULL; }
  p += 4;
  lp = BUFSIZ - 1;
  r = punycode_encode(lu, q, NULL, &lp, p);
  free(q);
  if(r != PUNYCODE_SUCCESS){
    Perl_warn(aTHX_ "%s", punycode_strerror(r));
    return NULL;
  }
  p[lp] = '\0'; p -= 4; p[0] = 'x'; p[1] = 'n'; p[2] = '-'; p[3] = '-';
  return p;
}

char *_puny_dec(pTHX_ char *i)
{
  size_t lp;
  uint32_t *q;
  char *p;
  int r;
  lp = BUFSIZ;
  if((q = (uint32_t *)malloc((lp*sizeof(q[0]))+1)) == NULL){
    Perl_warn(aTHX_ "failed malloc");
    return NULL;
  }
  r = punycode_decode(ex_strlen(i), i, &lp, q, NULL);
  if (r != PUNYCODE_SUCCESS){
    free (q);
    Perl_warn(aTHX_ "%s", punycode_strerror(r));
    return NULL;
  }
  q[lp] = 0;
  p = stringprep_ucs4_to_utf8(q, -1, NULL, NULL);
  free(q);
  if(!p){ return NULL; }
  return p;
}

MODULE = URI::UTF8::Punycode    PACKAGE = URI::UTF8::Punycode

SV*
puny_enc(str)
  char *str;
  CODE:
    char *set;
     int  lpc;
    char *tok;
    char *all;
     int  len = 1;
    char *tmp;
      SV *u8n;
    if((set = (char*)malloc(strlen(str)+1)) == NULL){
      Perl_croak(aTHX_ "failure malloc in puny_enc()");
    }
    if((all = (char*)malloc(1)) == NULL){
      free(set);
      Perl_croak(aTHX_ "failure malloc in puny_enc()");
    }
    all[0] = '\0';
    strcpy(set, str);
    for(lpc=0;;) {
      tok = strtok((lpc++==0)? set : NULL, ".");
      if(tok != NULL){
        if((tmp = _puny_enc(aTHX_ tok)) != NULL){
          len += strlen(tmp) + 1;
          if((all = (char*)realloc(all, (len + 1))) == NULL){
            free(set); free(all);
            Perl_croak(aTHX_ "failure realloc in puny_enc()");
          }
          strcat(all, tmp);
          free(tmp);
          strcat(all, ".");
        } else{
          free(set); free(all);
          Perl_croak(aTHX_ "subroutine puny_enc()");
        }
      } else{ break; }
    }
    free(set);
    all[(len - 2)] = '\0';
    u8n = newSVpv(all, 0);
    free(all);
    //SvUTF8_off(u8n);
    SvTAINTED_on(u8n);
    RETVAL = u8n;
  OUTPUT:
    RETVAL

SV*
puny_dec(str)
  char *str;
  CODE:
    char *set;
     int  lpc;
    char *tok;
    char *all;
     int  len = 1;
    char *tmp;
      SV *u8s;
    if((set = (char*)malloc(strlen(str)+1)) == NULL){
      Perl_croak(aTHX_ "failure malloc in puny_enc()");
    }
    if((all = (char*)malloc(1)) == NULL){
      free(set);
      Perl_croak(aTHX_ "failure malloc in puny_enc()");
    }
    all[0] = '\0';
    strcpy(set, str);
    for(lpc=0;;) {
      tok = strtok((lpc++==0)? set : NULL, ".");
      if(tok != NULL){
        if(strncmp(tok, "xn--", 4) == 0){ tok += 4; }
        if((tmp = _puny_dec(aTHX_ tok)) != NULL){
          len += strlen(tmp) + 1;
          if((all = (char*)realloc(all, (len + 1))) == NULL){
            free(set); free(all);
            Perl_croak(aTHX_ "failure realloc in puny_enc()");
          }
          strcat(all, tmp);
          free(tmp);
          strcat(all, ".");
        } else{
          free(set); free(all);
          Perl_croak(aTHX_ "subroutine puny_enc()");
        }
      } else{ break; }
    }
    free(set);
    all[(len - 2)] = '\0';
    u8s = newSVpv(all, 0);
    free(all);
    sv_utf8_upgrade(u8s);
    SvTAINTED_on(u8s);
    RETVAL = u8s;
  OUTPUT:
    RETVAL
