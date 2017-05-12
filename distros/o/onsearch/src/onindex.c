/* $Id: onindex.c,v 1.20 2005/08/16 05:34:49 kiesling Exp $ */
/***
    To do - 
    1.  Option for alternate output file name.
    2.  Figure out how to handle filenames with chars other than isalnum ().
    3.  sigusr1 might not need sigaction, if re-setting handler within
        the sighandler.
    4.  Better locale support, and find out how ctype funcs work with it.
    5.  Make sure that SIGHUP works correctly.
    6.  Make sure that plugins show the correct help message, 
        and their names don't conflict with other standard executables.
    7.  Make sure that ndirs and nfiles are reset correctly even after
        a permission denied error.
    8.  Reduce memory footprint so that very large text files don't
        start thrashing.
    9.  Check for memory leaks, and that all memory is being freed 
        correctly.
*/
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <pwd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <ctype.h>
#include <time.h>
#include <stdarg.h>
#include <signal.h>
#include <fnmatch.h>
#include <locale.h>
#include "onindex.h"

#ifndef DATADIR
#define DATADIR "."
#endif
#ifndef ONSEARCHDIR
#define ONSEARCHDIR "."
#endif

#define TMPDIR "/tmp"
#define CONFFILE "onsearch.cfg"
#define IDXNAME ".onindex.idx"
#define BAKEXT ".bak"
#define SEARCHROOT "SearchRoot"
#define EXCLUDEWORD "ExcludeWord"
#define EXCLUDEDIR  "ExcludeDir"
#define EXCLUDEFGLOB "ExcludeGlob"
#define DIGITSONLY "DigitsOnly"
#define PLUGIN "PlugIn"
#define INDEXINTERVAL "IndexInterval"
#define WEBUSER "User"
#define WEBLOGDIR "WebLogDir"
#define SINGLELETTERWORDS "SingleLetterWords"
#define DEFAULTSECS 43200              /* Index every 12 hours. */

#define DEBUGMODE

extern int errno;

typedef struct _list {
  struct _list *next;
  struct _list *prev;
  char *c_data;
} LIST;

typedef struct _wordrec {
  struct _wordrec *next;
  struct _wordrec *prev;
  char word[MAXPATH];
  char offsets[MAXREC];
} WORDREC;

typedef struct _vfile {
  char name[MAXPATH];
  char tmpname[MAXPATH];
  char ftype[MAXPATH];
  char plugin[MAXPATH];
  long int fd_offset;
  long int tmpfd_offset;
  int err;
  FILE *fd;
  FILE *tmpfd;
} VFILE;

WORDREC *words = NULL;           /* List of words to be indexed.      */
WORDREC *lastword = NULL;        /* List head pointer for words list. */
LIST *dirs = NULL;
LIST *excludewords = NULL;
LIST *excludedirs = NULL;
LIST *plugins = NULL;
LIST *excludeglobs = NULL;
int ndirs;
int nfiles;
int nrecs = 0;
time_t starttime;
static char tmpname[MAXPATH];
static int verbose = FALSE;
static int vverbose = FALSE;
static int alldigits = FALSE;
static int deleteonly = FALSE;
static int singleletterwords = FALSE;
static int quiet = FALSE;
static int user_conf_path = FALSE;
static int user_output_file = FALSE;
static int nobacks = FALSE;
#ifdef DEBUGMODE
static int debugmode = FALSE;
#endif
static char app_name[MAXPATH];
static char conf_path[MAXPATH];
static char output_fn[MAXPATH];
static char w_path[MAXPATH];
static char cwd[MAXPATH];
static char pidfilepath[MAXPATH];
static time_t interval = DEFAULTSECS;
static int terminate = FALSE;
static char webuserid[MAXPATH];
char log_path[MAXPATH];
pid_t pgid, sid;

#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2

/* Prototypes */
void parse_args (int, char**);
void help (void);
char *filetype (char *);
int collate (char *, long int);
int read_conffile (void);
int subdir (char *);
int index_file (char *, char *);
int isal8 (int);
int write_words (char *);
LIST *new_pathrec (void);
WORDREC *new_wordrec (void);
void list_push (LIST *, LIST *);
void word_push (WORDREC *, WORDREC *);
void word_unshift (WORDREC *);
FILE *tmpopen (char *, int);
void tmpclose (FILE *);
int is_word (char *);
void delete_words (void);
int backup_and_rename (char *, char *);
int d_expired (char *);
int fstatus (char *);
VFILE *vfopen (char *, char *);
void vfclose (VFILE *);
char *basename (char *);
void split (char *, ...);
int vfread (char *, size_t, size_t, VFILE *);
int run_filter (VFILE *);
void signals (void);
void delete_list (LIST *);
int d_excluded (char *);
int delete_indexes (char *);
int openlogfile (char *, char *);
void chomp_dir (char *);
int f_excluded (char *);
int run (void);
int clf (char *, char *,...);

int main (int argc, char **argv) {

  int result;
  LIST *t;
  double timesincelast;
  pid_t pid;
  char *rpath;
  struct passwd *webuser;

#ifndef BINDIR
  if (getenv("DOCUMENT_ROOT")) {
     sprintf (conf_path, "%s/%s/%s", getenv("DOCUMENT_ROOT"), 
	      ONSEARCHDIR, CONFFILE);
     strcpy (w_path, getenv("DOCUMENT_ROOT"));
  } else {
    sprintf (conf_path, "%s", CONFFILE);
    strcpy (w_path, "/");
  }
#else
  sprintf (conf_path, "%s/%s", ONSEARCHDIR, CONFFILE);
  strcpy (w_path, ONSEARCHDIR);
#endif

  setlocale (LC_ALL, "");

  signals ();

  parse_args (argc, argv);

  if ((rpath = getcwd (cwd, MAXPATH)) == NULL) {
    fprintf (stderr, "%s: onindex: could not get cwd: %s.\n",
	 app_name, strerror (errno));
    _exit (-1);
  }

  sprintf (tmpname, ".onindex.%d", getpid ());

  if ((result = read_conffile ()) < 0) {
    fprintf(stderr, "%s: %s: %s.\n", app_name, conf_path, strerror (errno));
    return 1;
  }

  if (user_output_file) {
    clf ("notice", "%s: Output file %s.\n", app_name, output_fn);
  }
  if (user_conf_path) {
    clf ("notice", "%s: Using configuration %s.\n", app_name, conf_path);
  }

  if ((webuser = getpwnam (webuserid)) == NULL) {
    clf ("error", "%s: onindex: %s: %s.\n", app_name, webuserid,
 	     strerror (errno));
    _exit (-1);
  }

  if ((result = setegid (webuser -> pw_gid)) < 0) {
    clf ("error", "%s: onindex: could not set group id %d: %s.\n", app_name,
	 webuser -> pw_gid,
	 strerror (errno));
    _exit (-1);
  }

  if ((result = seteuid (webuser -> pw_uid)) < 0) {
    clf ("error", "%s: onindex: could not set user id: %s.\n", app_name,
 	     strerror (errno));
    _exit (-1);
  }
    
  clf ("notice", "%s: %s.", app_name, "starting");

  time (&starttime);

#ifdef DEBUGMODE
   if (!debugmode) {
#endif
     switch (pid = fork ()) 
       {
       case -1:
	 clf ("error", "%s: PID %d fork: %s.", app_name, getppid (),
	      strerror (errno));
	 _exit (-1);
       case 0:
	 break;
       default:
	 return pid;
       }

     if ((sid = setsid ()) == -1) {
       clf ("error", "%s: PID %d setsid: %s.", app_name, getppid (),
	    strerror (errno));
       _exit (-1);
     }

     switch (pid = fork ())
       {
       case -1:
	 clf ("error", "%s: PID %d fork: %s.", app_name, getppid (),
	      strerror (errno));
	 _exit (-1);
       case 0:
	 close (STDIN_FILENO);
	 close (STDOUT_FILENO);
	 close (STDERR_FILENO);
	 break;
       default:
	 pgid = getpgrp ();
	 setpgid (pid, pgid);
	 return pid;
       }
#ifdef DEBUGMODE
   } else {
     clf ("notice", "%s: %s.", app_name, "debug mode");
   }
#endif

   setpgid (0, pgid);

   if (!deleteonly)
     if ((result = run ()) < 0) terminate = TRUE;

   if ((result = chdir ("/")) < 0) {
     clf ("error", "%s: chdir (%s): %s.", app_name, w_path, strerror (errno));
     _exit (result);
   }

   if (!deleteonly && !terminate)
     /*** format string */
     clf ("notice", "%s: %d seconds between indexes.", app_name, 
	  (int) interval);

   if (verbose && alldigits)
     clf ("notice", "%s: indexing words that contain only digits.", 
	  app_name);

   while (!terminate) {

     if (!deleteonly) {
       clf ("notice", "%s: %s.", app_name, "indexing");
       nfiles = ndirs = 0;
     }

     for (t = dirs; t; t = t -> next)
       result = subdir (t -> c_data);

     if (deleteonly) {
       clf ("notice", "%s: %s.", app_name, "deleted old indexes");
       terminate = TRUE;
     } else {
       clf ("notice", "%s: indexed %d files in %d directories.", 
	    app_name, nfiles, ndirs);
     }
    
     while (((timesincelast = difftime (time(NULL), starttime)) < interval) &&
       (! terminate)) {
       usleep (1* 1000000L);
     }
     time (&starttime);

   }

   clf ("notice", "%s: %s.", app_name, "terminating");
   return 0;
}

void term (int signum) {

  struct sigaction sa, old_sa;

  clf ("notice", "%s: %s, %s.", app_name, 
       (signum == 2) ? "SIGINT" :
       (signum == 3) ? "SIGQUIT":
       (signum == 15) ? "SIGTERM" : "Wild Signal", 
       "terminating");
       
  if (unlink (pidfilepath) < 0)
    clf ("error", "%s: %s: %s.", app_name, pidfilepath, strerror (errno));

  sa.sa_handler = SIG_IGN;
  sa.sa_flags = 0;
  sigemptyset (&sa.sa_mask);
  sigaction (signum, &sa, &old_sa);
  terminate = TRUE;
}

void sighup (int signum) {

  int result;

  clf ("notice", "%s: SIGHUP, re-reading conf.", app_name);

  delete_list (dirs); dirs = NULL;
  delete_list (excludewords); excludewords = NULL;
  delete_list (excludedirs); excludedirs = NULL;
  delete_list (plugins); plugins = NULL;
  delete_list (excludeglobs); excludeglobs = NULL;
  delete_words ();
  if ((result = read_conffile ()) < 0) _exit (1);
  clf ("notice", "%s: %d seconds between indexes.", app_name, 
	  (int) interval);
  signal (SIGHUP, sighup);
}

void sigusr1 (int signum) {
  clf ("notice", "%s: %s.", app_name, "indexing");
  starttime = 0;
}

void signals (void) {

  struct sigaction sa_usr1, old_sa_usr1;

  signal (SIGTERM, term);
  signal (SIGINT, term);
  signal (SIGQUIT, term);
  signal (SIGHUP, sighup);

  sa_usr1.sa_handler = sigusr1;
  sa_usr1.sa_flags = 0;
  sigemptyset (&sa_usr1.sa_mask);
  sigaction (SIGUSR1, &sa_usr1, &old_sa_usr1);
}

int read_conffile (void) {

  FILE *conf;
  LIST *p, *p1;
  char s[MAXPATH], *n;
  char iv_label[64], iv_buf[64];
  char wu_label[64], wu_buf[64];
  char wl_label[64], wl_buf[MAXPATH];
  int i = 0;

  if ((conf = fopen (conf_path, "r")) == NULL) {
    fprintf (stderr, "%s: %s: %s.", app_name, conf_path, strerror (errno));
    return -1;
  }
  while (fgets (s, MAXPATH, conf)) {
    n = index (s, '\n');
    if (n) *n = '\0';
    if ((*s == '#') || (*s == '\0')) continue;

    if (!strncmp (s, SEARCHROOT, strlen(SEARCHROOT))) {
      if (dirs == NULL) {
 	dirs = new_pathrec ();
 	n = rindex (s, ' ');
 	chomp_dir (++n);
 	strcpy (dirs -> c_data, n);
      } else {
 	p = new_pathrec ();
 	n = rindex (s, ' ');
 	chomp_dir (++n);
 	strcpy (p -> c_data, n);
 	list_push (dirs, p);
      }
    }

    if (!strncmp (s, EXCLUDEWORD, strlen(EXCLUDEWORD))) {
      if (excludewords == NULL) {
 	excludewords = new_pathrec ();
 	n = rindex (s, ' ');
 	strcpy (excludewords -> c_data, ++n);
      } else {
 	p = new_pathrec ();
 	n = rindex (s, ' ');
 	strcpy (p -> c_data, ++n);
 	list_push (excludewords, p);
       }
    }

    if (!strncmp (s, EXCLUDEDIR, strlen(EXCLUDEDIR))) {
      if (excludedirs == NULL) {
 	excludedirs = new_pathrec ();
 	n = rindex (s, ' ');
 	chomp_dir (++n);
 	strcpy (excludedirs -> c_data, n);
      } else {
 	p = new_pathrec ();
 	n = rindex (s, ' ');
 	chomp_dir (++n);
 	strcpy (p -> c_data, n);
 	list_push (excludedirs, p);
      }
    }

     if (!strncmp (s, PLUGIN, strlen (PLUGIN))) {
       if (plugins == NULL) {
	 plugins = new_pathrec ();
	 strcpy (plugins -> c_data, s);
       } else {
 	p1 = new_pathrec ();
 	strcpy (p1 -> c_data, s);
 	list_push (plugins, p1);
       }
     }

     if (!strncmp (s, EXCLUDEFGLOB, strlen (EXCLUDEFGLOB))) {
       if (excludeglobs == NULL) {
 	excludeglobs = new_pathrec ();
 	n = rindex (s, ' ');
 	strcpy (excludeglobs -> c_data, ++n);
       } else {
 	p1 = new_pathrec ();
 	n = rindex (s, ' ');
 	strcpy (p1 -> c_data, ++n);
 	list_push (excludeglobs, p1);
       }
     }

     if (!strncmp (s, DIGITSONLY, strlen(DIGITSONLY))) {
       n = rindex (s, ' ');
       if (atoi (n))
 	  alldigits = TRUE;
     }

     if (!strncmp (s, SINGLELETTERWORDS, strlen(SINGLELETTERWORDS))) {
       n = rindex (s, ' ');
       if (atoi (n))
 	  singleletterwords = TRUE;
     }

    if (!strncmp (s, INDEXINTERVAL, strlen(INDEXINTERVAL))) {
      split (s, iv_label, iv_buf);
      interval = atoi (iv_buf);
    } 

    if (!strncmp (s, WEBUSER, strlen(WEBUSER))) {
      split (s, wu_label, wu_buf);
      strcpy (webuserid, wu_buf);
    } 

    if (!strncmp (s, WEBLOGDIR, strlen(WEBLOGDIR))) {
      split (s, wl_label, wl_buf);
      strcpy (log_path, wl_buf);
    } 
 }

  fclose (conf);
  return i;
}

void chomp_dir (char *d) {

  char *l;

  l = rindex (d, '/');
  if (((l - d) + 1) == strlen (d)) 
    *l = 0;

}

int subdir (char *d_name) {

  struct dirent *d_ent;
  DIR *d;
  struct stat statbuf;
  char idxpath[MAXPATH],
    tmpidxpath[MAXPATH], path[MAXPATH], opentag[32], closetag[32];
  int i_res, rput, e_res, indexp = FALSE;
  FILE *tmp;

  if (!d_excluded (d_name)) return 0;

  if (deleteonly) return delete_indexes (d_name);

  if (user_conf_path) {
    strcpy (tmpidxpath, output_fn);
  } else {
    sprintf (tmpidxpath, "%s/%s", d_name, tmpname);
  }
  sprintf (idxpath, "%s/%s", d_name, IDXNAME);

  if (((e_res = fstatus(idxpath)) < 0) || d_expired (d_name)) {
    indexp = TRUE;
    if (verbose)
      clf ("notice", "%s: indexing %s.", app_name, d_name);
    if ((tmp = tmpopen (tmpidxpath, 1)) == NULL)
      return -1;
    ++ndirs;
    sprintf (opentag, "<index>\n");
    if ((rput = fputs (opentag, tmp)) < 0) {
      clf ("error", "%s: subdir (%s): %s.", app_name, d_name, 
	   strerror (errno));
      return -1;
    }
    tmpclose (tmp);
  }

  d = opendir (d_name);
  while ((d_ent = readdir (d)) != NULL) {
    if (strcmp (d_ent -> d_name, ".") && strcmp (d_ent -> d_name, "..")
	&& strncmp (d_ent -> d_name, ".onindex", strlen (".onindex"))) {
      sprintf (path, "%s/%s", d_name, d_ent -> d_name);
      memset ((void *)&statbuf, 0, sizeof(statbuf));
      stat (path, &statbuf);
      if (statbuf.st_mode & S_IFDIR) {
	subdir (path);
      } else {
	if ((indexp == TRUE) && (statbuf.st_mode & S_IFREG) &&
	    strcmp (tmpidxpath, path) && 
	    strncmp (idxpath, path, strlen (idxpath))) {
	  /***
	      The only exception here should be if a plugin is not 
	      available.  In that case, keep going and attempt to 
	      index the other files in the directory.
	   ***/
	  if (!f_excluded (d_ent -> d_name)) {
	    i_res = index_file (path, tmpidxpath);
	  }
	}
      }
    }
  }
  closedir (d);

  if (indexp == TRUE) {
    if ((tmp = tmpopen (tmpidxpath, 0)) == NULL)
      return -1;
    sprintf (closetag, "</index>\n");
    if ((rput = fputs (closetag, tmp)) < 0) {
      clf ("error", "%s: subdir (%s): %s.", app_name, d_name, 
	   strerror (errno));
      return -1;
    }
    tmpclose (tmp);
    backup_and_rename (d_name, tmpidxpath);
  }

  return 0;
}

int delete_indexes (char *d_name) {

  struct dirent *d_ent;
  DIR *d;
  struct stat statbuf;
  char path[MAXPATH];

  if ((d = opendir (d_name)) != NULL) {
    while ((d_ent = readdir (d)) != NULL) {
      if (!strcmp (d_ent -> d_name, ".") || !strcmp (d_ent -> d_name, ".."))
	continue;
      sprintf (path, "%s/%s", d_name, d_ent -> d_name);
      memset ((void *)&statbuf, 0, sizeof(statbuf));
      stat (path, &statbuf);
      if (statbuf.st_mode & S_IFDIR) { 
	subdir (path); 
      } else { 
	if (!strncmp (d_ent -> d_name, ".onindex", 8)) {
	  if (verbose)
	    clf ("notice", "%s: deleting %s index.", app_name, d_name);
	  unlink (path); 
	}
      } 
    }
    closedir (d);
  }
  return 0;
}

int f_excluded (char *fn) {

  LIST *l = excludeglobs;
  int r;

  do {
    if ((r = fnmatch (l -> c_data, fn, 0)) == 0) {
      if (verbose) 
	clf ("notice", "%s: excluding file %s.", app_name, fn);
      return 1;
    }
  } while ((l = l -> next) != NULL);

  return 0;
}

int d_excluded (char *d) {

  LIST *l;

  if (excludedirs) {
    l = excludedirs;
    do {
      if (!strncmp (l -> c_data, d, strlen (l -> c_data))) {
 	if (verbose) 
	  clf ("notice", "%s: excluding directory %s.", app_name, d);
	return FALSE;
      }
    }  while ((l = l -> next) != NULL);
  }
  return TRUE;
}

int d_expired (char *d_name) {

  struct stat statbuf;
  time_t idx_mtime = 0, dir_mtime = 0;
  char path[MAXPATH], dirpath[MAXPATH];

  sprintf (dirpath, "%s/.", d_name);
  stat (dirpath, &statbuf);
  dir_mtime = statbuf.st_mtime;

  sprintf (path, "%s/%s", d_name, IDXNAME);
  stat (path, &statbuf);
  idx_mtime = statbuf.st_mtime;

  if (idx_mtime < dir_mtime)
    return TRUE;

  return FALSE;
}

int index_file (char *path, char *tmpidxpath) {

  FILE *tmp;
  char word[MAXPATH], opentag[MAXPATH * 2], closetag[32],
    inbuf[MAXREC];
  int r, rput, nwords = 0, i = 0, j, wordlength, inword = FALSE;
  long int offset;
  VFILE *vf;

  if ((vf = vfopen (path, "r")) == NULL)
    return -1;

  if ((tmp = tmpopen (tmpidxpath, 0)) == NULL)
     return -1;
  sprintf (opentag, "<file path=\"%s\">\n", path);
  if ((rput = fputs (opentag, tmp)) < 0) {
    clf ("error", "%s: index_file (%s): %s.", app_name, tmpidxpath, 
	 strerror (errno));
    vfclose (vf);
    return -1;
  }
  tmpclose (tmp);

  ++nfiles;

  while ((r = vfread (inbuf, sizeof(char), MAXREC-1, vf)) > 0) {
    for (j = 0; j < r; j++) {
      if (isal8(inbuf[j])) {
	if (!inword) {
	  inword = TRUE;
	  word[0] = (char) inbuf[j];
	  word[1] = '\0';
 	  offset = i + j;
	} else {
	  wordlength = strlen (word);
	  if (wordlength >= MAXPATH) goto loop;
	  word[wordlength] = (char) inbuf[j];
	  word[wordlength+1] = '\0';
	}
      } else {
	if (inword) {
	  inword = FALSE;
	  if (!is_word (word)) collate (word, offset);
	} else {
	  continue;
	}
      }
    loop:
    }
    i += r;
  }

  nwords = write_words (tmpidxpath);
  if (verbose)
    clf ("notice", "%s: %s: %d words indexed.", app_name, path, nwords);
  delete_words ();

  sprintf (closetag, "</file>\n");
  if ((tmp = tmpopen (tmpidxpath, 0)) == NULL)
    return -1;
  if ((r = fputs (closetag, tmp)) < 0) {
    clf ("error", "%s: index_file (): %s.", app_name, strerror (errno));
    return -1;
  }
  tmpclose (tmp);

  vfclose (vf);
  return FALSE;
}

/* Criteria set by command-line and onsearch.cfg options. */
int is_word (char *word) {

  int i, hasalpha = FALSE;

  if (!singleletterwords && (strlen (word) == 1)) return TRUE;

  if (!alldigits) {
    for (i = 0; (i < strlen (word)) && (! hasalpha) ; i++) {
      if (isal8 ((int) word[i])) { 
	hasalpha = TRUE;
      }
    }
  } else {
    hasalpha = TRUE;
  }

  if (!hasalpha) {
    return TRUE;
  } else {
    return FALSE;
  }
}

int isal8 (int c) {
  if (isalnum(c)) return TRUE;
                                  /* iso_8859_1.7 */
  if (((c >= 192) && (c <= 214)) || /* Skip mulitiplication */
      ((c >= 216) && (c <= 246)) || /* and division signs.  */
      ((c >= 248) && (c <= 255))) return TRUE;
  return FALSE;
}

FILE *tmpopen (char *path, int create) {

  static FILE *f;
  int r;

  if (!create) {
    if ((r = fstatus (path)) < 0) {
      clf ("error", 
	   "%s: tmpopen temporary index %s: %s. You need to reindex.", 
	   app_name, path, strerror (errno));

    }
  }

  if ((f = fopen (path, "a")) == NULL) {
    clf ("error", "%s: tmpopen (%s): %s.", app_name, path, strerror (errno));
    return NULL;
  }

  return f;
}

void tmpclose (FILE *f) {
  fclose (f);
}

int collate (char *word, long int offset) {

  WORDREC *w;
  char offbuf[64];
  int listed = FALSE;

  sprintf (offbuf, "%ld", offset);
  if (words == NULL) {
    words = new_wordrec ();
    lastword = words;
    strcpy (words -> word, word);
    sprintf (words -> offsets, "%ld", offset);
  } else {
    w = words;
    do {
      if (!strcmp (w -> word, word)) {
	if ((strlen (offbuf) +  1 + strlen(w -> offsets)) > 
	    sizeof (w -> offsets)) {
	  return TRUE;
	}
	sprintf (w -> offsets, "%s,%ld", w -> offsets, offset);
	listed = TRUE;
      }
    } while (!listed && (w = w -> next) != NULL);
    if (!listed) {
      w = new_wordrec ();
      strcpy (w -> word, word);
      sprintf (w -> offsets, "%ld", offset);
      word_push (words, w);
    }
  }
  return FALSE;
}

int write_words (char *idxpath) {

  char recbuf[MAXREC * 2];
  int r, nwords = 0;
  WORDREC *w;
  FILE *tmp;

  if ((w = words) == NULL) return FALSE;
  if ((tmp = tmpopen (idxpath, 0)) == NULL)
    return FALSE;
  do {
    sprintf (recbuf, " <word chars=\"%s\">%s</word>\n", 
	     w -> word, w -> offsets);

    if ((r = fputs (recbuf, tmp)) < 0) {
      clf ("error", "%s: write_words: %s.", app_name, strerror (errno));
      return -1;
    }
    ++nwords;
  } while ((w = w -> next) != NULL);

  tmpclose (tmp);
  return nwords;
}

LIST *new_pathrec (void) {

  LIST *p;

  if ((p = (LIST *)calloc (1, sizeof (struct _list))) == NULL) {
    clf ("error", "%s: new_pathrec (): %s.", app_name, strerror (errno));
    exit (errno);
  }
  if ((p -> c_data = (char *)calloc (1, MAXPATH)) == NULL) {
    clf ("error", "%s: new_pathrec (): %s.", app_name, strerror (errno));
    exit (errno);
  }
  
  return p;
}

WORDREC *new_wordrec (void) {

  WORDREC *w;

  if ((w = (WORDREC *)calloc (1, sizeof (struct _wordrec))) == NULL) {
    clf ("error", "%s: new_wordrec (): %s.", app_name, strerror (errno));
    exit (errno);
  }
  return w;
}

void list_push (LIST *l1, LIST *l2) {

  LIST *n = l1;

  while (n -> next != NULL)
    n = n -> next;

  n -> next = l2;
  l2 -> prev = n;
  l2 -> next = NULL;
}

void word_push (WORDREC *l1, WORDREC *l2) {

  WORDREC *n = lastword;

  n -> next = l2;
  l2 -> prev = n;
  l2 -> next = NULL;
  lastword = l2;
}

void delete_words (void) {
  WORDREC *x, *x2;

  if (words == NULL) return;

  if (lastword != words) {
    x = lastword;
    x2 = x -> prev;
    do {
      free (x);
      x = x2;
    } while (x && ((x2 = x -> prev) != words));
  }
  words = NULL;
  lastword = NULL;
}

void delete_list (LIST *l) {

  LIST *x, *x2;

  if (l == NULL) return;

  if (! l -> next) {
    free (l -> c_data);
    free (l);
  } else {
    for (x = l; x; x = x2) {
      free (x -> c_data);
      x2 = x -> next;
      free (x);
    }
  }
  l = NULL;
}

char *filetype (char *s) {

  char *c;
  /*** TO DO */
  /* Get a better sampling of xml docs for signatures. */
  if ((c = strstr (s, XMLSIG)) != NULL) 
    return XMLTYPE;
  if ((c = strstr (s, XMLSIG_U)) != NULL) 
    return XMLTYPE;
  if ((c = strstr (s, HTMLSIG)) != NULL) 
    return HTMLTYPE;
  if ((c = strstr (s, HTMLSIG_U)) != NULL) 
    return HTMLTYPE;
  if ((c = strstr (s, HTMLDOCTYPE)) != NULL) 
    return HTMLTYPE;
  if ((c = strstr (s, HTMLDOCTYPE_U)) != NULL) 
    return HTMLTYPE;

  if (!strncmp (s, JAVACLASSSIG, strlen (JAVACLASSSIG))) {
    return JAVACLASSTYPE;
  }
  if (!strncmp (s, ELFSIG, strlen (ELFSIG))) {
    return ELFTYPE;
  }
  if (!strncmp (s, PNGSIG, strlen (PNGSIG))) {
    return PNGTYPE;
  }
  if (!strncmp (s, PSSIG, strlen (PSSIG))) {
    return PSTYPE;
  }
  if (!strncmp (s, PDFSIG, strlen (PDFSIG))) {
    return PDFTYPE;
  }
  if (!strncmp (s, PKZIPSIG, strlen (PKZIPSIG))) {
    return PKZIPTYPE;
  }
  if (!strncmp (s, GZIPSIG, strlen (GZIPSIG))) {
    return GZIPTYPE;
  }
  if (!strncmp (s, GIFSIG, strlen (GIFSIG))) {
    return GIFTYPE;
  }
  if (!strncmp (s, COMPRESSSIG, strlen (COMPRESSSIG))) {
    return COMPRESSTYPE;
  }
  if (!strncmp (&s[6], JPEGSIG, strlen (JPEGSIG))) {
    return JPEGTYPE;
  }
  if (!strncmp (&s[24], SUNPKGBINSIG, strlen (SUNPKGBINSIG))) {
    return SUNPKGBINTYPE;
  }

  return TEXTTYPE;
}

int fstatus (char *path) {

  struct stat statbuf;
  int r;

  memset ((void *)&statbuf, 0, sizeof(statbuf));
  r = stat (path, &statbuf);
  if (vverbose && (r < 0)) {
    clf ("error", "%s: fstatus (%s): %s.", app_name, path, strerror (errno));
    errno = 0;
  }

  return r;
}

int backup_and_rename (char *dir, char *tmppath) {

  char idxpath[MAXPATH], backup_path[MAXPATH];
  int r;
  
  sprintf (backup_path, "%s/%s%s", dir, IDXNAME, BAKEXT);
  sprintf (idxpath, "%s/%s", dir, IDXNAME);

  if ((r = fstatus (backup_path)) == 0)
    unlink (backup_path);

  if (((r = fstatus (idxpath)) == 0) && ! nobacks)
    rename (idxpath, backup_path);

  rename (tmppath, idxpath);

  return FALSE;
}

VFILE *vfopen (char *name, char *mode) {
  
  VFILE *vf;
  FILE *f;
  char inbuf[MAXREC], label[MAXPATH], mimetype[MAXPATH], 
    plugin[MAXPATH];
  int r;
  LIST *p;

  if ((f = fopen (name, mode)) == NULL) {
    clf ("error", "%s: vfopen (fopen (%s)): %s.", app_name, name, 
	 strerror (errno));
    return NULL;
  }

  if ((vf = (VFILE *)calloc (1, sizeof (struct _vfile))) == NULL) {
    clf ("error", "%s: vfopen (calloc (%s)): %s.", app_name, name, 
	 strerror (errno));
    return NULL;
  }
  vf -> fd = f;

  /* Handle zero length files also. */
  if ((r = fread (inbuf, sizeof(char), MAXREC-1, vf -> fd)) == 0) {
    if (ferror (vf -> fd)) {
      clf ("error", "%s: vfopen (fread (%s)): %s.", app_name, name, 
	   strerror (errno));
      vfclose (vf);
      return NULL;
    }
  }
  rewind (vf -> fd);

  strcpy (vf -> name, name);
  sprintf (vf -> tmpname, "%s/%s.%d", TMPDIR, 
	   basename (name), getpid ());
  strcpy (vf -> ftype, filetype (inbuf));

  if ((p = plugins) != NULL) {
    do {
      split (p -> c_data, label, mimetype, plugin); 
      if (!strcmp (mimetype, vf -> ftype))
	sprintf (vf -> plugin, "%s/%s", w_path, plugin);
    } while ((p = p -> next) != NULL);
  }

  if (*(vf -> plugin) == '\0') {
    clf ("warning", "%s: %s MIME type %s: no plugin.", app_name, 
	 vf -> name, vf -> ftype);
    vfclose (vf);
    return NULL;
  } else {
    if ((r = run_filter (vf)) < 0) {
      vfclose (vf);
      return NULL;
    }
  }

  if ((vf -> tmpfd = fopen (vf -> tmpname, "r")) == NULL) {
    clf ("error", "%s: vfopen (fopen (%s)): %s.", 
	 app_name, vf -> tmpname, strerror (errno));
    vfclose (vf);
    return NULL;
  }

  return vf;
}

int run_filter (VFILE *vf) {

  pid_t pid;
  int status;
  int rval;

  switch (pid = fork ()) 
    {
    case -1:
      clf ("error", "%s: run_filter (%s) : %s.", app_name, 
        vf -> plugin, strerror (errno));
      return -1;
      break;
    case 0:
      setpgid (0, pgid);
      execl (vf -> plugin, vf -> plugin, vf -> name, vf -> tmpname, NULL);
      /* If the program reaches here, there is an error. */
      clf ("error", "%s: run_filter (%s) : %s.", app_name, 
	   vf -> plugin, strerror (errno));
      _exit (errno);
      break;
    default:
      if ((rval = waitpid (pid, &status, 0)) < 0) {
	/* 
	   Not all filters spawn child process, so don't record 
	   those errors.
	*/
	if (errno != ECHILD) {
	  clf ("error", "%s: run_filter (%s) waitpid (%d) : %s.", 
	       app_name, vf -> plugin, pid, strerror (errno));
	}
	return -1;
      }
      return FALSE;
      break;
    }

  return FALSE;
}

void vfclose (VFILE *vf) {
  fclose (vf -> fd);
  if (vf -> tmpfd != NULL) fclose (vf -> tmpfd);
  unlink (vf -> tmpname);
  free (vf);
}

int vfread (char *inbuf, size_t size, size_t n, VFILE *vf) {

  int r;
  struct stat statbuf;

  if ((r = stat (vf -> tmpname, &statbuf)) < 0) {
    clf ("error", "%s: vfread (%s): %s.", app_name, 
	 vf -> tmpname, strerror (errno));
    return -1;
  }
  if (vf -> tmpfd_offset >= statbuf.st_size) return -1;

  if ((r = fread (inbuf, size, n, vf -> tmpfd)) < n) {
    if (feof (vf -> tmpfd)) {
      return r;
    }
    if (ferror (vf -> tmpfd)) {
      vf -> err = errno;
      vfclose (vf);
      return -1;
    }
  }
  vf -> tmpfd_offset += r;
  return r;
}

char *basename (char *pathname) {
  static char *i;

  i = rindex (pathname, '/');
  return ++i;
}

void parse_args (int c, char **a) {

  int i;
  char *n = NULL;

  n = rindex (a[0], '/');
  strcpy (app_name, ((n) ? ++n : a[0]));

  for (i = 1; i < c; i++) {
    if (a[i][0] == '-') {
      /* -h is help and exit. */
      if (!strncmp (&a[i][1], "h", 1)) {
	help ();
      }
      /* -vv is very verbose */
      if (!strncmp (&a[i][1], "vv", 2)) {
	verbose = vverbose = TRUE;
	continue;
      }
      /* -v is verbose */
      if (!strncmp (&a[i][1], "v", 1)) {
	verbose = TRUE;
	continue;
      }
      /* -d also indexes words that contain only digits. */
      if (!strncmp (&a[i][1], "d", 1)) {
	alldigits = TRUE;
	continue;
      }
#ifdef DEBUGMODE
      /* -D sets debugmode. */
      if (!strncmp (&a[i][1], "D", 1)) {
	debugmode = TRUE;
	continue;
      }
#endif
      /* -u deletes old indexes and exits. */
      if (!strncmp (&a[i][1], "u", 1)) {
	deleteonly = TRUE;
	continue;
      }
      /* -q enables quiet mode. */
      if (!strncmp (&a[i][1], "q", 1)) {
	quiet = TRUE;
	continue;
      }
      /* -N prevents backup of indexes. */
      if (!strncmp (&a[i][1], "N", 1)) {
	nobacks = TRUE;
	continue;
      }
      /*** -f <path> is the configuration file's path */
       if (!strncmp (&a[i][1], "f", 1)) {
 	user_conf_path = TRUE;
 	strcpy (conf_path, a[++i]);
	clf ("notice", "%s: Using configuration %s.\n", app_name, conf_path);
 	continue;
       }
       /*** -s <secs> is the time between indexing runs */
       if (!strncmp (&a[i][1], "s", 1)) {
	 interval = atoi (a[++i]);
	 continue;
       }
       if (!strncmp (&a[i][1], "o", 1)) {
	 user_output_file = TRUE;
	 strcpy (output_fn, a[++i]);
/* 	 clf ("notice", "%s: Output file %s.\n", app_name, output_fn); */
	 continue;
       }
       help ();
    } else {
      help ();
    }
  }
}

int run (void) {

  int rstat;
  int pid;
  struct stat statbuf;
  char localpidfiledir[MAXPATH];
  char pidstr[32];
  FILE *pidf;

  memset ((void *)&statbuf, 0, sizeof(statbuf));
  if ((rstat = stat (LOCALPIDFILEDIR, &statbuf)) < 0) {
    clf ("warning", "%s: %s: %s.  Using current directory.",
	      LOCALPIDFILEDIR, strerror (errno));
    strcpy (localpidfiledir, ".");
  } else {
    strcpy (localpidfiledir, LOCALPIDFILEDIR);
  }
  sprintf (pidfilepath, "%s/%s", localpidfiledir, PIDFILENAME);
  
  memset ((void *)&statbuf, 0, sizeof(statbuf));
  /* Old PID file. */
  if ((rstat = stat (pidfilepath, &statbuf)) == 0) {
    clf ("warning", "%s: old PID file %s found", app_name, pidfilepath);
    if ((pidf = fopen (pidfilepath, "r")) != NULL) {
      fgets (pidstr, MAXPATH, pidf);
      pid = atoi (pidstr);
      fclose (pidf);
    }
    /* Already running. */
    if (((rstat = kill (pid, 0)) == 0) && (errno != ESRCH)) {
      clf ("warning", "%s: existing daemon process found, PID %s", app_name, 
	   pidstr);
      return -1;
    }
  }

  if ((pidf = fopen (pidfilepath, "w")) != NULL) {
    sprintf (pidstr, "%d\n", getpid ());
    fputs (pidstr, pidf);
    fclose (pidf);
  } else {
    clf ("warning", "%s: Warning %s: %s", app_name, 
	 pidfilepath, strerror (errno));
    return -1;
  }

  return 0;
}

void help (void) {

  fprintf (stderr, "Usage: %s ", app_name);

#ifdef DEBUGMODE
  fprintf (stderr, "[-D] ");
#endif
  fprintf (stderr, "[-d] [-f <path>] [-h] [-N] [-o <path>] [-q] [-u] [-v] [-vv] [-s <secs>]\n");
  fprintf (stderr, "-d         Index words that contain only digits.\n");
#ifdef DEBUGMODE
  fprintf (stderr, "-D         Debug mode.\n");
#endif
  fprintf (stderr, "-f <path>  Use configuration file <path>.\n");
  fprintf (stderr, "-h         Display this message and exit.\n");
  fprintf (stderr, "-N         Do not back up indexes.\n");
  fprintf (stderr, "-o <path>  Output index to <path>.\n");
  fprintf (stderr, "-q         Do not print status information.\n");
  fprintf (stderr, "-s <secs>  Seconds between each index.\n");
  fprintf (stderr, "-v         Log extra information while indexing.\n");
  fprintf (stderr, "-vv        Log even more information.\n");
  fprintf (stderr, "-u         Delete old indexes and exit.\n");
  fprintf (stderr, "Options override the corresponding settings in %s.\n", CONFFILE);
  _exit (255);
}

void split (char *s, ...) {

  va_list a;
  char *t, *sp, buf[MAXPATH];
  int inword = FALSE;
  
  va_start (a, s);
  t = s;
  while (*t) {
    if (*t == ' ' || *t == '\t') {
      inword = FALSE;
    } else {
      if (!inword) {
	inword = TRUE;
	sp = index (t, ' ');
	if (!sp) sp = index (t, '\t');
	if (!sp) sp = index (t, '\0');
	strncpy (buf, t, sp - t);
	buf[sp - t] = 0;
	strcpy (va_arg (a, char *), buf);
      }
    }
    ++t;
  }
  va_end (a);
}
