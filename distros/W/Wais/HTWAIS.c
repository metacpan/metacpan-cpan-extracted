/*                               -*- Mode: C -*- 
 * $Basename: HTWAIS.c $
 * $Revision: 1.2 $
 * Author          : Brewster Kahle, Thinking Machines, <Brewster@think.com>
 * Created On      : Wed Jun 15 17:07:41 1994
 * Last Modified By: Ulrich Pfeifer
 * Last Modified On: Tue May 13 09:22:17 1997
 * Language        : C
 * Update Count    : 215
 * Status          : Unknown, Use with caution!
 * 
 * (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
 * 
 */

#define BIG 10000

#include "EXTERN.h"
#include "perl.h"

#ifdef WORD
#undef WORD                     /* defined in the perl parser */
#endif
#ifdef _config_h_
#undef _config_h_               /* load the freeWAIS-sf config.h also */
#endif
#include "HTWAIS.h"

#define str_get(A) SvPV(A,na)
#define str_ncat sv_catpvn

#define MAX_MESSAGE_LEN 100000
#define CHARS_PER_PAGE 4096     /* number of chars retrieved in each request */


#define HEX_ESCAPE '%'

extern int WWW_TraceFlag;       /* Control diagnostic output */

#define PRIVATE static
#define PUBLIC
#define CONST
#define BOOL int
#define NO 0
#define YES 1
#define TOASCII(a) a
#define FROMASCII(a) a
#define trim_junk(a) a
PRIVATE char    line[2048];     /* For building strings to display */
                                /* Must be able to take id */

/*
extern int WAISmaxdoc;
extern SV* WAISrecsep;
extern SV* WAISversion;
*/

/*      WorldWideWeb - Wide Area Informaion Server Access       HTWAIS.c
**      ==================================================
**
**      This module allows a WWW server or client to read data from a
**      remote  WAIS
**  server, and provide that data to a WWW client in hypertext form.
**  Source files, once retrieved, are stored and used to provide
**  information about the index when that is acessed.
**
** Authors
**      BK      Brewster Kahle, Thinking Machines, <Brewster@think.com>
**      TBL     Tim Berners-Lee, CERN <timbl@info.cern.ch>
**
** History
**         Sep 91       TBL adapted shell-ui.c (BK) with HTRetrieve.c from WWW.
**         Feb 91       TBL Generated HTML cleaned up a bit (quotes, escaping)
**                          Refers to lists of sources. 
**         Mar 93       TBL   Lib 2.0 compatible module made.   
**
** Bugs
**      Uses C stream i/o to read and write sockets, which won't work
**      on VMS TCP systems.
**
**      Should cache connections.
**
**      ANSI C only as written
**
** Bugs fixed
**      NT Nathan Torkington (Nathan.Torkington@vuw.ac.nz)
**
** WAIS comments:
**
**      1.      Separate directories for different system's .o would help
**      2.      Document ids are rather long!
**
** WWW Address mapping convention:
**
**      /servername/database/type/length/document-id
**
**      /servername/database?word+word+word
*/
/* WIDE AREA INFORMATION SERVER SOFTWARE:
   No guarantees or restrictions.  See the readme file for the full standard
   disclaimer.

   Brewster@think.com
*/
#define STR SV
#define NOARGS ()
#define ARGS1(t,a) (a) \
                t a;
#define ARGS2(t,a,u,b) (a,b) \
                t a; u b;
#define ARGS3(t,a,u,b,v,c) (a,b,c) \
                t a; u b; v c;
#define ARGS4(t,a,u,b,v,c,w,d) (a,b,c,d) \
                t a; u b; v c; w d;
#define ARGS5(t,a,u,b,v,c,w,d,x,e) (a,b,c,d,e) \
                t a; u b; v c; w d; x e;
#define ARGS6(t,a,u,b,v,c,w,d,x,e,y,f) (a,b,c,d,e,f) \
                t a; u b; v c; w d; x e; y f;
#define ARGS7(t,a,u,b,v,c,w,d,x,e,y,f,z,g) (a,b,c,d,e,f,g) \
                t a; u b; v c; w d; x e; y f; z g;
#define ARGS8(t,a,u,b,v,c,w,d,x,e,y,f,z,g,s,h) (a,b,c,d,e,f,g,h) \
                t a; u b; v c; w d; x e; y f; z g; s h;
#define ARGS9(t,a,u,b,v,c,w,d,x,e,y,f,z,g,s,h,r,i) (a,b,c,d,e,f,g,h,i) \
                t a; u b; v c; w d; x e; y f; z g; s h; r i;
#define ARGS10(t,a,u,b,v,c,w,d,x,e,y,f,z,g,s,h,r,i,q,j) (a,b,c,d,e,f,g,h,i,j) \
                t a; u b; v c; w d; x e; y f; z g; s h; r i; q j;

#define STRCAT(A,B) sv_catpvn(A,B,strlen(B))
#define STRSEP(A)   sv_catsv(A,perl_get_sv ("Wais::fldsep", FALSE))
#define STREND(A)   sv_catsv(A,perl_get_sv ("Wais::recsep", FALSE))
/*              Decode %xx escaped characters                   HTUnEscape()
**              -----------------------------
**
**      This function takes a pointer to a string in which some
**      characters may have been encoded in %xy form, where xy is
**      the acsii hex code for character 16x+y.
**      The string is converted in place, as it will never grow.
*/

PRIVATE char from_hex ARGS1(char,c)
{
  return  c >= '0' && c <= '9' ?  c - '0' 
            : c >= 'A' && c <= 'F'? c - 'A' + 10
            : c - 'a' + 10;     /* accept small letters just in case */
}

PUBLIC char    *HTUnEscape 
ARGS1 (char *, str)
{
  char           *p = str;
  char           *q = str;

  if (!str) {                   /* Just for safety ;-) */
    if (TRACE)
      fprintf (stderr, "HTUnEscape.. Called with NULL argument.\n");
    return "";
  }
  while (*p) {
    if (*p == HEX_ESCAPE) {
      p++;
      if (*p)
        *q = from_hex (*p++) * 16;
      if (*p)
        *q = FROMASCII (*q + from_hex (*p++));
      q++;
    } else {
      *q++ = *p++;
    }
  }

  *q++ = 0;
  return str;

}                               /* HTUnEscape */

/*      Matrix of allowed characters in filenames
**      -----------------------------------------
*/

PRIVATE BOOL    acceptable[256];
PRIVATE BOOL    acceptable_inited = NO;
PRIVATE char    hex[17] = "0123456789ABCDEF";
PRIVATE void init_acceptable NOARGS
{
  unsigned int    i;
  char           *good =
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789./-_$";

  for (i = 0; i < 256; i++)
    acceptable[i] = NO;
  for (; *good; good++)
    acceptable[(unsigned int) *good] = YES;
  acceptable_inited = YES;
}

#define ACCEPTABLE(a) (acceptable[a]==YES)
#define __ACCEPTABLE(a) ( a>=32 && a<128 && ((isAcceptable[a-32]) & mask))

PUBLIC char    *HTEscape 
ARGS2 (char *, str,
       unsigned char, mask)
{
  CONST char     *p;
  char           *q;
  char           *result;
  int             unacceptable = 0;

  for (p = str; *p; p++)
    if (!ACCEPTABLE ((unsigned char) TOASCII (*p)))
      unacceptable++;
  result = (char *) malloc (p - str + unacceptable + unacceptable + 1);
  if (result == NULL) {
    if (TRACE)
      fprintf (stderr, "HTEscape: outofmem\n");
    return (NULL);
  }
  for (q = result, p = str; *p; p++) {
    unsigned char   a = TOASCII (*p);

    if (!ACCEPTABLE (a)) {
      *q++ = HEX_ESCAPE;        /* Means hex commming */
      *q++ = hex[a >> 4];
      *q++ = hex[a & 15];
    } else
      *q++ = *p;
  }
  *q++ = 0;                     /* Terminate */
  return result;
}

void showDiags 
ARGS2 (
        STR *, target,
        diagnosticRecord **, d)
{
  long            i;

  for (i = 0; d[i] != NULL; i++) {
    if (d[i]->ADDINFO != NULL) {
      STRCAT (target, d[i]->DIAG);
      STRCAT (target, "|");
      STRCAT (target, d[i]->ADDINFO);
      STREND (target);
    }
  }
}

/*      Transform file identifier into WWW address
**      ------------------------------------------
**
**
** On exit,
**      returns         nil if error
**                      pointer to malloced string (must be freed) if ok
*/
char           *WWW_from_archie 
ARGS1 (char *, file)
{
  char           *end;
  char           *result;
  char           *colon;

  for (end = file; *end > ' '; end++);  /* assumes ASCII encoding */
  result = (char *) malloc (10 + (end - file));
  if (!result)
    return result;              /* Malloc error */
  strcpy (result, "file://");
  strncat (result, file, end - file);
  colon = strchr (result + 7, ':');     /* Expect colon after host */
  if (colon) {
    for (; colon[0]; colon[0] = colon[1], colon++);     /* move down */
  }
  return result;
}                               /* WWW_from_archie */

/*      Transform document identifier into URL
**      --------------------------------------
**
** Bugs: A static buffer of finite size is used!
**      The format of the docid MUST be good!
**
** On exit,
**      returns         nil if error
**                      pointer to malloced string (must be freed) if ok
*/
/*
extern char from_hex PARAMS((char a));                  ** In HTWSRC @@ **
*/

PRIVATE char   *WWW_from_WAIS 
ARGS1 (any *, docid)
{
  static unsigned char buf[BIG];
  char            num[10];
  unsigned char  *q = buf;
  char           *p = (docid->bytes);
  int             i, l;

  if (TRACE) {
    char           *p;

    fprintf (stderr, "WAIS id (%d bytes) is ", (int) docid->size);
    for (p = docid->bytes; p < docid->bytes + docid->size; p++) {
      if ((*p >= ' ') && (*p <= '~'))   /* Assume ASCII! */
        fprintf (stderr, "%c", *p);
      else
        fprintf (stderr, "<%x>", (unsigned) *p);
    }
    fprintf (stderr, "\n");
  }
  for (p = docid->bytes;
       (p < docid->bytes + docid->size) &&
       (q < &buf[BIG]);) {
    if (TRACE)
      fprintf (stderr, "    Record type %d, length %d\n",
               p[0], p[1]);
    sprintf (num, "%d", (int) *p);
    bcopy (num, q, strlen (num));
    q += strlen (num);
    p++;
    *q++ = '=';                 /* Separate */
    l = (int) ((unsigned char) *p);
    p++;
    if (l > 127) {
      l = (l - 128) * 128;
      l = l + (int) ((unsigned char) *p);
      p++;
    }
    for (i = 0; i < l; i++, p++) {
      if (!acceptable[(unsigned char) *p]) {
        *q++ = HEX_ESCAPE;
        *q++ = hex[((unsigned char) *p) >> 4];
        *q++ = hex[((unsigned char) *p) & 15];
      } else
        *q++ = (unsigned char) *p;
    }
    *q++ = ';';                 /* Terminate field */
  }
  *q++ = 0;                     /* Terminate string */
  if (TRACE)
    fprintf (stderr, "WWW form of id: %s\n", buf);
  {
    char           *result = (char *) malloc (strlen (buf) + 1);

    strcpy (result, buf);
    return result;
  }
}                               /* WWW_from_WAIS */


/*      Transform URL into WAIS document identifier
**      -------------------------------------------
**
** On entry,
**      docname         points to valid name produced originally by
**                      WWW_from_WAIS
** On exit,
**      docid->size     is valid
**      docid->bytes    is malloced and must later be freed.
*/

PRIVATE any    *WAIS_from_WWW 
ARGS2 (any *, docid, char *, docname)
{
  char           *z;                        /* Output pointer */
  char           *sor;                      /* Start of record - points to size field. */
  char           *p;                        /* Input pointer */
  char           *q;                        /* Poisition of "=" */
  char           *s;                        /* Position of semicolon */
  int             n;                        /* size */

  if (docname == NULL) {        /* UP */
    if (TRACE)
      fprintf (stderr, "WWW id empty\n");
    return (NULL);
  }
  if (TRACE)
    fprintf (stderr, "WWW id (to become WAIS id): %s\n", docname);
  for (n = 0, p = docname; *p; p++) {   /* Count sizes of strings */
    n++;
    if (*p == ';')
      n--;                      /* Not converted */
    else if (*p == HEX_ESCAPE)
      n = n - 2;                /* Save two bytes */
    docid->size = n;
  }

  docid->bytes = (char *) malloc (docid->size + 32);    /* result record */
  z = docid->bytes;

  for (p = docname; *p;) {
    q = strchr (p, '=');
    if (!q)
      return 0;
    *q = '\0';
    *z++ = atoi (p);
    *q = '=';
    s = strchr (q, ';');        /* (Check only) */
    if (!s)
      return 0;                 /* Bad! No ';'; */
    sor = z;                    /* Remember where the size field was */
    z++;                        /* Skip record size for now */

    {
      int             len;
      int             tmp;

      for (p = q + 1; *p != ';';) {
        if (*p == HEX_ESCAPE) {
          char            c;
          unsigned int    b;

          p++;
          c = *p++;
          b = from_hex (c);
          c = *p++;
          if (!c)
            break;              /* Odd number of chars! */
          *z++ = (b << 4) + from_hex (c);
        } else {
          *z++ = *p++;          /* Record */
        }
      }
      len = (z - sor - 1);

      z = sor;
      if (len > 127) {
        tmp = (len / 128);
        len = len - (tmp * 128);
        tmp = tmp + 128;
        *z++ = (char) tmp;
        *z = (char) len;
      } else {
        *z = (char) len;
      }
      z++;
    }

    for (p = q + 1; *p != ';';) {
      if (*p == HEX_ESCAPE) {
        char            c;
        unsigned int    b;

        p++;
        c = *p++;
        b = from_hex (c);
        c = *p++;
        if (!c)
          break;                /* Odd number of chars! */
        *z++ = (b << 4) + from_hex (c);
      } else {
        *z++ = *p++;            /* Record */
      }
    }
    p++;                        /* After semicolon: start of next record */
  }

  if (TRACE) {
    char           *p;

    fprintf (stderr, "WAIS id (%d bytes) is ", (int) docid->size);
    for (p = docid->bytes; p < docid->bytes + docid->size; p++) {
      if ((*p >= ' ') && (*p <= '~'))
        fprintf (stderr, "%c", *p);
      else
        fprintf (stderr, "<%x>", (unsigned) *p);
    }
    fprintf (stderr, "\n");
  }
  return docid;                 /* Ok */

}                               /* WAIS_from_WWW */

/*      Send a plain text record to the client          output_text_record()
**      --------------------------------------
*/

PRIVATE void output_text_record 
ARGS3 (
        STR *, target,
        WAISDocumentText *, record,
        boolean, quote_string_quotes)
{
  if (record->DocumentText->size) {
    /* This cast should be unnecessary, as put_block should operate
       on unsigned char from the start.  What was he thinking??? */
    str_ncat (target, (unsigned char *) record->DocumentText->bytes,
              record->DocumentText->size);
  }
}                               /* output text record */


/*      Format A Search response for the client         display_search_response
**      ---------------------------------------
*/
/* modified from tracy shen's version in wutil.c
 * displays either a text record or a set of headlines.
 */
void
display_search_response 
ARGS6 (
        STR *, diagnostics,
        STR *, headlines,
        STR *, texts,
        SearchResponseAPDU *, response,
        char *, wais_database,
        char *, keywords)
{
  WAISSearchResponse *info;
  long            i, k;
  BOOL            archie;
  SV* WAISfldsep = perl_get_sv ("Wais::fldsep", FALSE);

  if (!response) {
    STRCAT (diagnostics, "Arrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrgh!");
    STREND (diagnostics);
    return;
  }
  archie = strstr (wais_database, "archie") != 0;    /* Specical handling */

  if (TRACE)
    fprintf (stderr, "HTWAIS: Displaying search response\n");
  if (TRACE)
    fprintf (stderr, "HTWAIS: database 0x%08x '%s', response 0x%08x\n",
             wais_database, wais_database, response);
  if (TRACE)
    fprintf (stderr, "HTWAIS: keywords 0x%08x '%s'\n", keywords, keywords);
  sprintf (line,
           "Index %s contains the following %d item%s relevant to '%s'.\n",
           wais_database,
           (int) (response->NumberOfRecordsReturned),
           response->NumberOfRecordsReturned == 1 ? "" : "s",
           keywords);
  /*
     PUTS(line);
     PUTS("The first figure for each entry is its relative score, ");
     PUTS("the second the number of lines in the item.");
     START(HTML_MENU);
   */
  if (response->DatabaseDiagnosticRecords != 0) {
    info = (WAISSearchResponse *) response->DatabaseDiagnosticRecords;
    i = 0;

    if (info->Diagnostics != NULL)
      showDiags (diagnostics, info->Diagnostics);

    if (info->DocHeaders != 0) {
      for (k = 0; info->DocHeaders[k] != 0; k++) {
        WAISDocumentHeader *head = info->DocHeaders[k];
        char           *headline = trim_junk (head->Headline);
        any            *docid = head->DocumentID;
        char           *docname;            /* printable version of docid */

        i++;

/*      Make a printable string out of the document id.
 */
        if (TRACE)
          fprintf (stderr,
                   "HTWAIS:  %2ld: Score: %4ld, lines:%4ld '%s'\n",
                   i,
                   (long int) (info->DocHeaders[k]->Score),
                   (long int) (info->DocHeaders[k]->Lines),
                   headline);
#define NORESULT "Search produced no result."
        if (!strncmp (headline, NORESULT, strlen (NORESULT))) {
          STRCAT (diagnostics, NORESULT);
          STREND (diagnostics);
          continue;
        }
        sprintf (line, "%ld%s%ld%s",
                 head->Score, str_get (WAISfldsep),
                 head->Lines, str_get (WAISfldsep));
        STRCAT (headlines, line);

        if (archie) {
          char           *www_name = WWW_from_archie (headline);

          if (www_name) {
            STRCAT (headlines, www_name);
            STRSEP (headlines);
            STRCAT (headlines, headline);
            STREND (headlines);
            free (www_name);
          } else {
            STRCAT (headlines, headline);
            STRCAT (headlines, " (bad file name)");
            STREND (headlines);
          }
        } else {                /* Not archie */
          docname = WWW_from_WAIS (docid);
          if (TRACE)
            fprintf (stderr, "HTWAIS: docname '%s'\n", docname);
          if (docname) {
            char           *dbname;
            char            types_array[1000];  /* bad */
            char           *type_escaped;

            acceptable['/'] = NO;
            dbname = HTEscape (wais_database);
            acceptable['/'] = YES;
            types_array[0] = 0;

            if (head->Types) {
              int             i;

              for (i = 0; head->Types[i]; i++) {
                if (i)
                  strcat (types_array, ",");

                type_escaped = HTEscape (head->Types[i]);
                strcat (types_array, type_escaped);
                free (type_escaped);
              }
              if (TRACE)
                fprintf (stderr, "Built types_array '%s'\n", types_array);
            } else {
              strcat (types_array, "TEXT");
            }

            sprintf (line, "%s/%s/%d/%s",
                     dbname,
                     types_array,
                     (int) (head->DocumentLength),
                     docname);

            STRCAT (headlines, line);
            STRSEP (headlines);
            STRCAT (headlines, headline);
            STREND (headlines);
            free (dbname);
            free (docname);
          } else {
            STRCAT (diagnostics, "(bad doc id)");
            STREND (diagnostics);
          }
        }
      }                         /* next document header */
    }                           /* if there were any document headers */
    if (info->ShortHeaders != 0) {
      k = 0;
      while (info->ShortHeaders[k] != 0) {
        i++;
        STRCAT (diagnostics, "(Short Header record, can't display)");
        STREND (diagnostics);
      }
    }
    if (info->LongHeaders != 0) {
      k = 0;
      while (info->LongHeaders[k] != 0) {
        i++;
        STRCAT (diagnostics, "\nLong Header record, can't display\n");
        STREND (diagnostics);
      }
    }
    if (info->Text != 0) {
      k = 0;
      while (info->Text[k] != 0) {
        i++;
        output_text_record (texts, info->Text[k++], false);
      }
    }
    if (info->Headlines != 0) {
      k = 0;
      while (info->Headlines[k] != 0) {
        i++;
        STRCAT (diagnostics, "\nHeadline record, can't display\n");
        STREND (diagnostics);
      }
    }
    if (info->Codes != 0) {
      k = 0;
      while (info->Codes[k] != 0) {
        i++;
        STRCAT (diagnostics, "\nCode record, can't display\n");
        STREND (diagnostics);
        /* dsply_code_record( info->Codes[k++]); */
      }
    }
  }                             /* Loop: display user info */
}


static long 
rbn (size, buf)
     int             size;
     unsigned char  *buf;
{
  long            result = 0;

  while (size) {
    size--;
    result = (result << 8) + *(buf++);
  }
  return (result);
}

static long 
rci (buf, chars)
     char           *buf;
     int            *chars;
{
  long            number;
  int             byte;

  number = 0;
  do {
    byte = *(buf++);
    (*chars)++;
    number <<= 7;
    number += (byte & 127);
  } while (byte & 128);
  return (number);
}


/* ------------------------------------------------------------------------ */
/* ---------------- Local copy of connect_to_server calls ----------------- */
/* ------------------------------------------------------------------------ */

/* Returns 1 on success, 0 on fail, -1 on interrupt. */
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

static int fd_connect_to_server 
ARGS3 (
        char *, host_name,
        long, port,
        long *, sockfd)
{
  struct sockaddr_in server;
  struct hostent *them, *gethostbyname ();
  int             status;

  /* Lookup the host */
  if (TRACE)
    fprintf (stderr, "fd_connect_to_server. Looking up `%s\'\n", host_name);
  if ((them = gethostbyname (host_name)) == NULL) {
    if (TRACE)
      fprintf (stderr, "fd_connect_to_server... Can't find internet node name `%s'.\n", host_name);
    return -1;
  }
  /* Make the socket */
  if ((*sockfd = socket (AF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
    return -1;
  }
  if (TRACE)
    fprintf (stderr, "fd_connect_to_server. Created socket number %d\n", *sockfd);

  memset ((void *) &server, '\0', sizeof (server));
  server.sin_family = AF_INET;
  server.sin_port = htons (port);
  bcopy ((char *) them->h_addr, (char *) &server.sin_addr, them->h_length);

  /* now call ther server */

  if ((status = connect (*sockfd, (struct sockaddr *) &server,
                         sizeof (server))) < 0) {
    *sockfd = -1;
    return -1;
  }
  if (TRACE)
    fprintf (stderr, "fd_connect_to_server returning file descriptor %d\n",
             *sockfd);
  return status;
}


int 
WAISsearch (host, port, wais_database, keywords,
            diagnostics, headlines, texts)
     char           *host;
     int             port;
     char           *wais_database;
     char           *keywords;
     STR            *diagnostics;
     STR            *headlines;
     STR            *texts;
{
  /* This below fixed size stuff is terrible */
  char           *request_message = (char *) s_malloc ((size_t) MAX_MESSAGE_LEN * sizeof (char));
  char           *response_message = (char *) s_malloc ((size_t) MAX_MESSAGE_LEN * sizeof (char));
  long            request_buffer_length = MAX_MESSAGE_LEN;
  FILE           *connection;
  long            fd;
  int             status;

  if (!acceptable_inited)
    init_acceptable ();
  if (host != NULL) {
    status = fd_connect_to_server (host, port, &fd);
    if (status < 0) {
      if (TRACE)
        fprintf (stderr, "===WAIS=== connection failed\n");
      return -1;
    }
#ifdef WAIS_USES_STDIO
#ifdef fdopen
#undef fdopen
#endif
#endif
    if ((connection = fdopen (fd, "r+")) == NULL) {
      if (TRACE)
        fprintf (stderr,
                 "WAISsearch: Did not get FILE handle");
      STRCAT (diagnostics, "WAISsearch: Did not get FILE handle");
      STREND (diagnostics);
      close (fd);
      return (-1);
    }
  } else {
    if (TRACE)
      fprintf (stderr,
               "WAISsearch: local search\n");
    connection = NULL;
  }
  if (NULL == generate_search_apdu (request_message + HEADER_LENGTH,
                                    &request_buffer_length,
                                    keywords, wais_database, NULL, 
                                    SvIV(perl_get_sv ("Wais::maxdoc", FALSE)))) {
    if (TRACE)
      fprintf (stderr,
               "WAISsearch:WAIS request too large; something went wrong.\n");
    STRCAT (diagnostics, "WAIS request too large; something went wrong.");
    STREND (diagnostics);
    return (-1);
  }
  if (!interpret_message (request_message,
                          MAX_MESSAGE_LEN - request_buffer_length,
                          response_message,
                          MAX_MESSAGE_LEN,
                          connection,
                          false /* true verbose */
      )) {
    if (TRACE)
      fprintf (stderr,
               "WAIS returned message too large; something went wrong.\n");
    STRCAT (diagnostics, "WAIS returned message too large; something went wrong.");
    STREND (diagnostics);
    return (-1);
  } else {
    SearchResponseAPDU *query_response = 0;

    readSearchResponseAPDU (&query_response,
                            response_message + HEADER_LENGTH);
    /* We do want this to be called if !query_response, to
       get our cute error message. */
    display_search_response (diagnostics, headlines, texts,
                             query_response, wais_database, keywords);
    if (query_response) {
      if (query_response->DatabaseDiagnosticRecords)
        freeWAISSearchResponse (query_response->DatabaseDiagnosticRecords);
      freeSearchResponseAPDU (query_response);
    }
  }
  if (connection)
#ifdef WAIS_USES_STDIO
#ifdef fclose
#undef fclose
#endif
#endif
    fclose (connection);
  s_free (request_message);
  s_free (response_message);

  return (0);

}

int 
WAISretrieve (host, port, wais_database, documentid,
              diagnostics, headlines, texts)
     char           *host;
     int             port;
     char           *wais_database;
     char           *documentid;
     STR            *diagnostics;
     STR            *headlines;
     STR            *texts;
{
  /* This below fixed size stuff is terrible */
  char           *request_message = (char *) s_malloc ((size_t) MAX_MESSAGE_LEN * sizeof (char));
  char           *response_message = (char *) s_malloc ((size_t) MAX_MESSAGE_LEN * sizeof (char));
  WAISSearchResponse *response;
  SearchResponseAPDU *retrieval_response = 0;
  diagnosticRecord **diag;
  long            request_buffer_length = MAX_MESSAGE_LEN;
  FILE           *connection;
  long            fd;
  int             status, count;
  int             document_length;
  char           *www_database;
  char           *doctype;
  char           *doclength;
  char           *docname;
  any             doc_chunk;
  any            *docid = &doc_chunk;

  if (!acceptable_inited)
    init_acceptable ();
  if (host != NULL) {
    status = fd_connect_to_server (host, port, &fd);
    if (status < 0) {
      if (TRACE)
        fprintf (stderr, "===WAIS=== connection failed\n");
      return -1;
    }
    if ((connection = fdopen (fd, "r+")) == NULL) {
      if (TRACE)
        fprintf (stderr,
                 "WAISsearch: Did not get FILE handle");
      STRCAT (diagnostics, "WAISsearch: Did not get FILE handle");
      STREND (diagnostics);
      close (fd);
      return (-1);
    }
  } else {
    if (TRACE)
      fprintf (stderr,
               "WAISsearch: local search\n");
    connection = NULL;
  }

  /* www_database = strchr(documentid,'/'); */
  www_database = documentid;
  if (www_database) {
    *www_database++ = 0;        /* Separate database name */
    doctype = strchr (www_database, '/');
    if (doctype) {              /* If not search parse doc details */
      *doctype++ = 0;           /* Separate rest of doc address */
      doclength = strchr (doctype, '/');
      if (doclength) {
        *doclength++ = 0;
        /* OK, now doclength should be the rest of the URL,
           right??? */
        if (TRACE)
          fprintf (stderr,
                   "WAIS: doctype '%s', doclength\n~~~~\n%s\n~~~~\n",
                   doctype, doclength);
        document_length = atol (doclength);
        if (document_length) {
          docname = strchr (doclength, '/');
          if (docname) {
            *docname++ = 0;
          }                     /* if docname */
        }                       /* if document_length valid */
      }                         /* if doclength */
    }
    if (doctype)
      HTUnEscape (doctype);

    if (TRACE)
      fprintf (stderr,
               "===WAIS=== Retrieve document id `%s' type `%s' length %ld\n",
               docname, doctype, document_length);

    /*  Decode hex or literal format for document ID
     */
    WAIS_from_WWW (docid, docname);
    if (docid == NULL) {
      STRCAT (diagnostics, "WAISretrieve: empty docid");
      STREND (diagnostics);
    }
    /*  Loop over slices of the document
     */
    if (docid != NULL) {
      int             bytes = 0, intr;
      char            line[256];

      count = 0;
      while (1) {
        char           *type = s_strdup (doctype);      /* Gets freed I guess */

        request_buffer_length = MAX_MESSAGE_LEN;        /* Amount left */
        if (TRACE)
          fprintf (stderr, "HTWAIS: Slice number %ld\n", count);

        if (generate_retrieval_apdu
            (request_message + HEADER_LENGTH,
             &request_buffer_length,
             docid,
             CT_byte,
             count * CHARS_PER_PAGE,
             (count + 1) * CHARS_PER_PAGE,
             type,
             wais_database
            ) == 0) {
          STRCAT (diagnostics,
                  "WAIS error condition; retrieval may be unsuccessful.");
          STREND (diagnostics);
        }
        free (type);

        /*      Actually do the transaction given by request_message */
        if (0 ==
            interpret_message
            (request_message,
             MAX_MESSAGE_LEN - request_buffer_length,
             response_message,
             MAX_MESSAGE_LEN,
             connection,
             false              /* true verbose */
            )) {
          STRCAT (diagnostics,
                  "WAIS error condition; retrieval may be unsuccessful.");
          STREND (diagnostics);
          goto no_more_data;
        }
        /*      Parse the result which came back into memory.
         */
        readSearchResponseAPDU (&retrieval_response,
                                response_message + HEADER_LENGTH);

        response =
          (WAISSearchResponse *) retrieval_response->DatabaseDiagnosticRecords;
        diag = response->Diagnostics;

        if (NULL == response->Text) {
          if (TRACE)
            fprintf (stderr, "WAIS: no more data (NULL response->Text)\n");
          if (retrieval_response->DatabaseDiagnosticRecords)
            freeWAISSearchResponse
              (retrieval_response->DatabaseDiagnosticRecords);
          freeSearchResponseAPDU (retrieval_response);
          goto no_more_data;
        } else if
            (((WAISSearchResponse *)
              retrieval_response->DatabaseDiagnosticRecords)->Text[0]->DocumentText->size) {
          output_text_record
            (texts,
             ((WAISSearchResponse *)
              retrieval_response->DatabaseDiagnosticRecords)->Text[0],
             false);
        }
        /* If text existed */ 
        else {
          if (TRACE)
            fprintf (stderr, "WAIS: no more data (fell through)\n");
          if (retrieval_response->DatabaseDiagnosticRecords)
            freeWAISSearchResponse
              (retrieval_response->DatabaseDiagnosticRecords);
          freeSearchResponseAPDU (retrieval_response);
          goto no_more_data;
        }

        /* Slightly inaccurate for last slice. */
        bytes += CHARS_PER_PAGE;
        if (TRACE)
          fprintf (stderr, "Read %d bytes of data.", bytes);

        if (diag &&
            diag[0] &&
            diag[0]->ADDINFO != NULL &&
            !strcmp (diag[0]->DIAG, D_PresentRequestOutOfRange)) {
          if (TRACE)
            fprintf (stderr, "WAIS: no more data (diag)\n");
          if (retrieval_response->DatabaseDiagnosticRecords)
            freeWAISSearchResponse
              (retrieval_response->DatabaseDiagnosticRecords);
          freeSearchResponseAPDU (retrieval_response);
          goto no_more_data;
        }
        if (retrieval_response->DatabaseDiagnosticRecords)
          freeWAISSearchResponse
            (retrieval_response->DatabaseDiagnosticRecords);
        freeSearchResponseAPDU (retrieval_response);

        count++;
      }                         /* Loop over slices */

    }                           /* local variables */
  no_more_data:

    /* Close the connection BEFORE calling system(), which can
       happen in the free method. */
    if (connection)
      fclose (connection);
    free (docid->bytes);
  }                             /* If document rather than search */
  s_free (request_message);
  s_free (response_message);

  return (0);
}

