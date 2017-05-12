#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>

/* Including the chm header */
#include <chm_lib.h>


#define CHM_MAX_BUF 65536

static char * my_strndup(const char *, size_t );

/*
 * This struct will hold some necessary data for the extension and is
 * the opaque C-object returned by new().
 *
 */

typedef struct 
{

  struct chmFile* chmfile;
  char*           filename;

} ChmObj;


/*
 * ChmObjData holds some infos about a particular member of the chm
 * file. It will be used to build a linked list that contains infos
 * about the content of the chm file. The member of the structure are:
 *
 *     - path is the complete path of the member;
 *     - title is the title of the member if it is an html file;
 *     - size is the file-size of the member;
 *     - next is a pointer to the next structure .
 *
 */

struct ChmObjData
{

  char *path;
  char *title;
  size_t size;
  struct ChmObjData *next;

};


/*
 * We must(?) make this variable global, so it could be used in
 * _chm_enumerate_callback().
 *
 */

struct ChmObjData *data = NULL;



/*
 * This function creates a new node for the linked list containing the
 * filelist of the chm file.
 *
 */

static struct ChmObjData *chm_data_add(char *path, char *title, size_t size)
{

  struct ChmObjData *tmp;

  tmp = calloc(1, sizeof(struct ChmObjData));
  if ( NULL == tmp )
    croak("Out of memory\n");

  tmp->path  = my_strndup(path, strlen(path));
  tmp->title = title;
  tmp->size  = size;
  tmp->next  = NULL;
    
  return tmp;

}


/*
 * Init the ChmObject.
 *
 */

static ChmObj *perl_chm_init(const char* filename)
{

  ChmObj *self = NULL;

  self = Newz(1, self, 1, ChmObj);
    
  if ( NULL == self )
    croak("Out of memory");
  
  self->filename = calloc(strlen(filename) + (size_t)1, sizeof(char));
  
  if ( !self->filename )
    croak("Out of memory");
  else
    strncpy(self->filename, filename, strlen(filename));

  self->chmfile = chm_open(self->filename);

  if ( NULL == self->chmfile )
    croak("Can't open file %s\n", self->filename);

  return self;

}



/*
 * Get rid of faulty strndup implementations...
 *
 */

static char * my_strndup(const char *src, size_t len)
{

  char *ret = NULL;

  ret = calloc(len + (size_t)1, sizeof(char));

  if ( !ret )
    croak("Out of memory\n");

  strncpy(ret, src, len);
  *(ret + (int)len) = '\0';

  return ret;

}


/*
 * Given a valid "path", perl_get_object() fetch its content from
 * chmfile, setting len to the length of the string that contains it
 * (len is a value-result argument).
 *
 */

static unsigned char *perl_get_object(struct chmFile *chmfile, const char *path, size_t *len)
{

  struct chmUnitInfo ui;
  unsigned char chm_buffer[CHM_MAX_BUF], *retbuf;
  int offset, swath;

  if ( CHM_RESOLVE_SUCCESS != chm_resolve_object(chmfile, path, &ui) )
    croak("Can't resolve given path\n");

  Newz(1, retbuf, (size_t)ui.length, unsigned char);

  if ( NULL == retbuf )
       croak("Out of memory\n");

  swath = CHM_MAX_BUF;
  offset = 0;
  *len = (size_t)ui.length;  

  while ( offset < ui.length ) /* Let's read the file at swath bytes per time, */
    {                          /* incrementing offset with the data we've read */

      if ( (ui.length - offset) < CHM_MAX_BUF )
	swath = ui.length - offset;
      else
	swath = CHM_MAX_BUF;

      swath = (int)chm_retrieve_object(chmfile, &ui, chm_buffer, offset, swath);
      memcpy((retbuf + offset), chm_buffer, (size_t)swath);
      offset += swath;

    }
  
  return retbuf;

}


static int file_is_normal(const char *filename)
{

  /* 
   * For the moment, we are intrested only on normal files, such as
   * html, css, images, etc... So we limit to look to these.
   *
   */
  
  if ( '/' == *filename ) /* SPECIAL or NORMAL file */
    {
      if ( ('#' == *(filename + 1)) || ('$' == *(filename + 1)) ) /* SPECIAL file */
	return 0;
      else /* NORMAL file */
	return 1;
    }
  else /* META file */
    return 0;

}


/*
 * Check that the file at "path" is an html one, taking this decision
 * depending on the extension of the file.
 *
 */

static int file_is_html(const char *path)
{

  char *tmp;

  if ( (int)strlen(path) < 4 ) /* Path must be at least 5 char long. */
    return 0;

  if ( NULL != (tmp = strrchr(path, '.')) )
    if ( 0 == strncasecmp(++tmp, "htm", (size_t)3) || 
	 0 == strncasecmp(tmp, "html", (size_t)4) )
	return 1;

  return 0;

}


/*
 * Traverse the content of the string "s", which contains html code,
 * to find the text between <title> and </title>, and return it.
 *
 */

static char *find_title(char *s)
{

  char *tmp = s;
  size_t len;

  while ( tmp++ )
    {
      tmp = strchr(tmp, '<');
      
      if ( 0 == strncasecmp(tmp, "<title>", (size_t)7) )
	{
	  tmp += 7;
	  len = (size_t) (strchr(tmp, '<') - tmp);
	  return my_strndup(tmp, len);
	}
      else
	continue;
    }

  return NULL;
	  
}      


/*
 * Glue-function for getting the title of an html file and returning
 * it.
 *
 */

static char *get_html_title(struct chmFile *chmfile, const char *filename)
{

  char *content, *title;
  size_t len;
  
  content = perl_get_object(chmfile, filename, &len);
  title = find_title(content);

  return title;

}


/*
 * Callback function to be passed to chm_enumerate(), in order to
 * build a linked list of ChmObjData structures that contains some
 * informations about the "normal" members (html, css, xml and image
 * files) of the chm file.
 *
 */

static int _chm_enumerate_callback(struct chmFile *h, struct chmUnitInfo *ui, void *context)
{
  
  char *title;
  struct ChmObjData *tmp;

  if ( file_is_normal(ui->path) )
    {
      title = ((file_is_html(ui->path)) ? get_html_title(h, ui->path) : NULL);
      tmp = chm_data_add(ui->path, title, ui->length);

      data->next = tmp;
      data = data->next;    
      tmp = NULL;
    }

  return CHM_ENUMERATOR_CONTINUE;

}
  

MODULE = Text::CHM	     PACKAGE = Text::CHM



ChmObj *
new( CLASS, file )
     char * CLASS;
     char * file;
  CODE:
     RETVAL = perl_chm_init(file);

     if ( NULL == RETVAL )
       XSRETURN_UNDEF;
  OUTPUT:
     RETVAL


void
DESTROY( self )
     ChmObj * self;
  CODE:
     chm_close(self->chmfile);
     safefree(self);


char*
filename( self )
     ChmObj * self;
  CODE:
     RETVAL = self->filename;
  OUTPUT:
     RETVAL


void
close( self )
     ChmObj * self;
  CODE:
     chm_close(self->chmfile);


void *
get_object( self, objname )
     ChmObj * self;
     char * objname;
  INIT:
     unsigned char * buf;
     size_t len;
  PPCODE:
     buf = perl_get_object(self->chmfile, objname, &len);
     XPUSHs(sv_2mortal(newSVpv(buf, len)));
     

void *
get_filelist( self )
     ChmObj * self;
  INIT:
     struct ChmObjData *contents = NULL;
     HV * hash;
  PPCODE:

     contents = chm_data_add("start", "start", 0);
     data = contents;

     if ( !chm_enumerate(self->chmfile, CHM_ENUMERATE_ALL, _chm_enumerate_callback, NULL ) )
        croak("Errors getting filelist\n");

     data = contents->next;

     while ( data )
         {
	    hash = newHV();
	    hv_store(hash, "path", 4, newSVpv(data->path, strlen(data->path)), 0);
	    hv_store(hash, "size", 4, newSViv(data->size), 0);
	    if ( data->title )
	      hv_store(hash, "title", 5, newSVpv(data->title, strlen(data->title)), 0);
	    else
	      hv_store(hash, "title", 5, newSV(0), 0);

	    XPUSHs(sv_2mortal(newRV((SV *)hash)));
	    
	    data = data->next;
	 }
