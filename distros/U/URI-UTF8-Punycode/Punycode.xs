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

int is_domain_name(char *chk)
{
  int i;
  int l = strlen(chk);
  char t;
  for(i=0;i<l;i++){
    t = chk[i];
    if(! isalnum(t) && t != '-'){
      return 0;
    }
  }
  return 1;
}

/* fake carp */
void ex_mycarp(pTHX_ const char *msg)
{
  //Perl_croak(aTHX_ "%s",  msg);
  Perl_warn(aTHX_ "%s",  msg);
}

char *ex_u8pny_realloc(char *all, char *set, int len, const char *msg)
{
  if((all = (char*)realloc(all, (len + 1))) == NULL){
    free(set); free(all);
    ex_mycarp(aTHX_ msg);
    return NULL;
  }
  return all;
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
    char *tok;
    char *all;
     int  len = 1;
    char *tmp;
      SV *u8n;
    if((set = (char*)malloc(strlen(str)+1)) == NULL){
      ex_mycarp(aTHX_ "failure malloc in puny_enc()");
      XSRETURN_UNDEF;
    }
    if((all = (char*)malloc(1)) == NULL){
      free(set);
      ex_mycarp(aTHX_ "failure malloc in puny_enc()");
      XSRETURN_UNDEF;
    }
    all[0] = '\0';
    strcpy(set, str);
    tok = strtok(set, ".");
    while(tok != NULL){
      if(! is_domain_name(tok)){
        if((tmp = _puny_enc(aTHX_ tok)) != NULL){
          len += strlen(tmp) + 1;
          if((all = ex_u8pny_realloc(all, set, len, "failure realloc in puny_enc()")) == NULL) XSRETURN_UNDEF;
          strcat(all, tmp);
          free(tmp);
        } else{
          free(set); free(all);
          ex_mycarp(aTHX_ "failure encode in puny_enc()");
          XSRETURN_UNDEF;
        }
      } else{
        len += strlen(tok) + 1;
        if((all = ex_u8pny_realloc(all, set, len, "failure realloc in puny_enc()")) == NULL) XSRETURN_UNDEF;
        strcat(all, tok);
      }
      strcat(all, ".");
      tok = strtok(NULL, ".");
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
    char *tok;
    char *all;
     int  len = 1;
    char *cpy;
    char *tmp;
      SV *u8s;
    if((set = (char*)malloc(strlen(str)+1)) == NULL){
      ex_mycarp(aTHX_ "failure malloc in puny_dec()");
      XSRETURN_UNDEF;
    }
    if((all = (char*)malloc(1)) == NULL){
      free(set);
      ex_mycarp(aTHX_ "failure malloc in puny_dec()");
      XSRETURN_UNDEF;
    }
    all[0] = '\0';
    strcpy(set, str);
    tok = strtok(set, ".");
    while(tok != NULL){
      if(is_domain_name(tok) && strncmp(tok, "xn--", 4) == 0){
        if((tmp = _puny_dec(aTHX_ tok + 4)) != NULL){
          len += strlen(tmp) + 1;
          if((all = ex_u8pny_realloc(all, set, len, "failure realloc in puny_dec()")) == NULL) XSRETURN_UNDEF;
          strcat(all, tmp);
          free(tmp);
        } else{
          free(set); free(all);
          ex_mycarp(aTHX_ "failure decode in puny_dec()");
          XSRETURN_UNDEF;
        }
      } else{
        len += strlen(tok) + 1;
        if((all = ex_u8pny_realloc(all, set, len, "failure realloc in puny_dec()")) == NULL) XSRETURN_UNDEF;
        strcat(all, tok);
      }
      strcat(all, ".");
      tok = strtok(NULL, ".");
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
