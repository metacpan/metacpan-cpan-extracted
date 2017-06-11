#include "mypuny.h"

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
void ex_mycarp(const char *msg)
{
  fprintf(stderr, "%s",  msg);
}

char *ex_u8pny_realloc(char *all, char *set, int len, const char *msg)
{
  if((all = (char*)realloc(all, (len + 1))) == NULL){
    free(set); free(all);
    ex_mycarp(msg);
    return NULL;
  }
  return all;
}

#ifdef STRINGPREP_H

////////////////////////////////
// Punycode Encode (libidn)
////////////////////////////////

char *_puny_enc(char *i)
{
  size_t lu, lp;
  uint32_t *q;
  char *p;
  int r;
  q = stringprep_utf8_to_ucs4(i, -1 ,&lu);
  if(!q){
    ex_mycarp("failed stringprep_utf8_to_ucs4");
    return NULL;
  }
  if((p = (char *)malloc(BUFSIZ+5)) == NULL){ return NULL; }
  p += 4;
  lp = BUFSIZ - 1;
  r = punycode_encode(lu, q, NULL, &lp, p);
  free(q);
  if(r != PUNYCODE_SUCCESS){
    ex_mycarp(punycode_strerror(r));
    return NULL;
  }
  p[lp] = '\0'; p -= 4; p[0] = 'x'; p[1] = 'n'; p[2] = '-'; p[3] = '-';
  return p;
}

////////////////////////////////
// Punycode Decode (libidn)
////////////////////////////////

char *_puny_dec(char *i)
{
  size_t lp;
  uint32_t *q;
  char *p;
  int r;
  lp = BUFSIZ;
  if((q = (uint32_t *)malloc((lp*sizeof(q[0]))+1)) == NULL){
    ex_mycarp("failed malloc");
    return NULL;
  }
  r = punycode_decode(ex_strlen(i), i, &lp, q, NULL);
  if (r != PUNYCODE_SUCCESS){
    free (q);
    ex_mycarp(punycode_strerror(r));
    return NULL;
  }
  q[lp] = 0;
  p = stringprep_ucs4_to_utf8(q, -1, NULL, NULL);
  free(q);
  if(!p){ return NULL; }
  return p;
}

#endif

////////////////////////////////
// Punycode Encode (XS)
////////////////////////////////

char *puny_enc(char *str)
{
  char *set;
  char *tok;
  char *all;
   int  len = 1;
  char *tmp;
  if((set = (char*)malloc(strlen(str)+1)) == NULL){
    ex_mycarp("failure malloc in puny_enc()");
    return NULL;
  }
  if((all = (char*)malloc(1)) == NULL){
    free(set);
    ex_mycarp("failure malloc in puny_enc()");
    return NULL;
  }
  all[0] = '\0';
  strcpy(set, str);
  tok = strtok(set, ".");
  while(tok != NULL){
    if(! is_domain_name(tok)){
      if((tmp = _puny_enc(tok)) != NULL){
        len += strlen(tmp) + 1;
        if((all = ex_u8pny_realloc(all, set, len, "failure realloc in puny_enc()")) == NULL) return NULL;
        strcat(all, tmp);
        free(tmp);
      } else{
        free(set); free(all);
        ex_mycarp("failure encode in puny_enc()");
        return NULL;
      }
    } else{
      len += strlen(tok) + 1;
      if((all = ex_u8pny_realloc(all, set, len, "failure realloc in puny_enc()")) == NULL) return NULL;
      strcat(all, tok);
    }
    strcat(all, ".");
    tok = strtok(NULL, ".");
  }
  free(set);
  all[(len - 2)] = '\0';
  return all;
}

////////////////////////////////
// Punycode Decode (XS)
////////////////////////////////

char *puny_dec(char *str)
{
  char *set;
  char *tok;
  char *all;
   int  len = 1;
  char *cpy;
  char *tmp;
  if((set = (char*)malloc(strlen(str)+1)) == NULL){
    ex_mycarp("failure malloc in puny_dec()");
    return NULL;
  }
  if((all = (char*)malloc(1)) == NULL){
    free(set);
    ex_mycarp("failure malloc in puny_dec()");
    return NULL;
  }
  all[0] = '\0';
  strcpy(set, str);
  tok = strtok(set, ".");
  while(tok != NULL){
    if(is_domain_name(tok) && strncmp(tok, "xn--", 4) == 0){
      if((tmp = _puny_dec(tok + 4)) != NULL){
        len += strlen(tmp) + 1;
        if((all = ex_u8pny_realloc(all, set, len, "failure realloc in puny_dec()")) == NULL) return NULL;
        strcat(all, tmp);
        free(tmp);
      } else{
        free(set); free(all);
        ex_mycarp("failure decode in puny_dec()");
        return NULL;
      }
    } else{
      len += strlen(tok) + 1;
      if((all = ex_u8pny_realloc(all, set, len, "failure realloc in puny_dec()")) == NULL) return NULL;
      strcat(all, tok);
    }
    strcat(all, ".");
    tok = strtok(NULL, ".");
  }
  free(set);
  all[(len - 2)] = '\0';
  return all;
}

/* Main function */
int main(int argc,char *argv[],char *envp[])
{

  char *r;

  int i;
  int c = 0;
  int m = 0;

  if(argc < 2){
    exit(1);
  }

  for(i=1; i<argc; i++){
    if(strcasecmp(argv[i], "-v") == 0){
      printf("%s\n%s", (char*)PNY_APPLOGO, (char*)PNY_VERSION);
      return 0;
    } else if(strcasecmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0){
      printf("%s%s\n%s", (char*)PNY_OPTIONS, (char*)PNY_APPLOGO, (char*)PNY_VERSION);
      return 0;
    } else if(strcasecmp(argv[i],"-e") == 0){
      m = 0;
    } else if(strcasecmp(argv[i],"-d") == 0){
      m = 1;
    } else if(m == 0){
      r = puny_enc(argv[i]);
      if(r == NULL){
        continue;
      } else{
        printf("%s\n",r);
        free(r);
      }
    } else if(m == 1){
      r = puny_dec(argv[i]);
      if(r == NULL){
        continue;
      } else{
        printf("%s\n",r);
        free(r);
      }
    }
  }

  return 0;

}
