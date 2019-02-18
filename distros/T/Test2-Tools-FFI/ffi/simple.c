#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

#define T2T_SIMPLE_API_ONLY
#include <t2t/simple.h>

struct {
  t2t_simple_message_cb note;
  t2t_simple_message_cb diag;
  t2t_simple_message_cb pass;
  t2t_simple_message_cb fail;
} cb;

static void
do_abort()
{
  fprintf(stderr, "t2t is not initalized.\n");
  abort();
}

static size_t buffer_size=0;
static char  *buffer=NULL;

static void
buffer_allocate(size_t size)
{
  if(size == 0)
  {
    free(buffer);
    buffer = NULL;
    buffer_size = 0;
  }
  else if(size > buffer_size)
  {
    if(buffer != NULL)
      free(buffer);
    buffer = malloc(size);
    buffer_size = size;
    if(buffer == NULL)
    {
      fprintf(stderr, "malloc returned NULL.\n");
      abort();
    }
  }
}

#define buffer_printf()                                        \
{                                                              \
  va_list aptr;                                                \
  int ret;                                                     \
                                                               \
  va_start(aptr, format);                                      \
  ret = vsnprintf(buffer, buffer_size, format, aptr);          \
  va_end(aptr);                                                \
                                                               \
  if(ret >= buffer_size)                                       \
  {                                                            \
    buffer_allocate(ret+1);                                    \
    va_start(aptr, format);                                    \
    ret = vsnprintf(buffer, buffer_size, format, aptr);        \
    va_end(aptr);                                              \
                                                               \
    if(ret >= buffer_size)                                     \
    {                                                          \
      fprintf(stderr, "something weird happened.\n");          \
      abort();                                                 \
    }                                                          \
  }                                                            \
}

void
t2t_simple_note(const char *language, const char *filename, int linenumber, const char *function, const char *message)
{
  if(cb.note)
    cb.note(message, language, filename, linenumber, function);
  else
    do_abort();
}

void
t2t_simple_notef(const char *language, const char *filename, int linenumber, const char *function, const char *format, ...)
{
  if(cb.note)
  {
    buffer_printf();
    cb.note(buffer, language, filename, linenumber, function);
  }
  else
    do_abort();
}

void
t2t_simple_diag(const char *language, const char *filename, int linenumber, const char *function, const char *message)
{
  if(cb.diag)
    cb.diag(message, language, filename, linenumber, function);
  else
    do_abort();
}

void
t2t_simple_diagf(const char *language, const char *filename, int linenumber, const char *function, const char *format, ...)
{
  if(cb.diag)
  {
    buffer_printf();
    cb.diag(buffer, language, filename, linenumber, function);
  }
  else
    do_abort();
}


int
t2t_simple_pass(const char *language, const char *filename, int linenumber, const char *function, const char *name)
{
  if(cb.pass)
  {
    cb.pass(name, language, filename, linenumber, function);
    return 1;
  }
  else
    do_abort();
}

int
t2t_simple_fail(const char *language, const char *filename, int linenumber, const char *function, const char *name)
{
  if(cb.fail)
  {
    cb.fail(name, language, filename, linenumber, function);
    return 0;
  }
  else
    do_abort();
}

void
t2t_simple_init(t2t_simple_message_cb note, t2t_simple_message_cb diag, t2t_simple_message_cb pass, t2t_simple_message_cb fail)
{
  cb.note = note;
  cb.diag = diag;
  cb.pass = pass;
  cb.fail = fail;
  buffer_allocate(512);
}

void
t2t_simple_deinit()
{
  cb.note = cb.diag = cb.pass = cb.fail = NULL;
  buffer_allocate(0);
}
