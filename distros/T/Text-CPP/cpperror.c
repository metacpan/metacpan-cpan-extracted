/* Default error handlers for CPP Library.
   Original copyright Free Software Foundation, under GPL.
   Extracted from gcc by Shevek and rewritten to generate a Perl SV
   instead of printing to stderr. */

#include "config.h"
#include "system.h"
#include "cpplib.h"
#include "cpphash.h"
#include "intl.h"



#if 0
static void print_location PARAMS ((cpp_reader *, unsigned int, unsigned int));

/* Print the logical file location (LINE, COL) in preparation for a
   diagnostic.  Outputs the #include chain if it has changed.  A line
   of zero suppresses the include stack, and outputs the program name
   instead.  */
static void
print_location (pfile, line, col)
     cpp_reader *pfile;
     unsigned int line, col;
{
  if (!pfile->buffer || line == 0)
    fprintf (stderr, "%s: ", progname);
  else
    {
      const struct line_map *map;

      map = lookup_line (&pfile->line_maps, line);
      print_containing_files (&pfile->line_maps, map);

      line = SOURCE_LINE (map, line);
      if (col == 0)
	col = 1;

      if (line == 0)
	fprintf (stderr, "%s:", map->to_file);
      else if (CPP_OPTION (pfile, show_column) == 0)
	fprintf (stderr, "%s:%u:", map->to_file, line);
      else
	fprintf (stderr, "%s:%u:%u:", map->to_file, line, col);

      fputc (' ', stderr);
    }
}
#endif

/* Hacked out of _cpp_begin_message by Shevek. This contains the common
 * logic between the printf and the SV versions. */
static int
_cpp_can_begin_message (pfile, code, line, column, levelp)
     cpp_reader *pfile;
     int code;
     unsigned int line, column;
     int *levelp;
{
  int level = DL_EXTRACT (code);

  switch (level)
    {
    case DL_WARNING:
    case DL_PEDWARN:
      if (CPP_IN_SYSTEM_HEADER (pfile)
	  && ! CPP_OPTION (pfile, warn_system_headers))
	return 0;
      /* Fall through.  */

    case DL_WARNING_SYSHDR:
      if (CPP_OPTION (pfile, warnings_are_errors)
	  || (level == DL_PEDWARN && CPP_OPTION (pfile, pedantic_errors)))
	{
	  if (CPP_OPTION (pfile, inhibit_errors))
	    return 0;
	  level = DL_ERROR;
	  pfile->errors++;
	}
      else if (CPP_OPTION (pfile, inhibit_warnings))
	return 0;
      break;

    case DL_ERROR:
      if (CPP_OPTION (pfile, inhibit_errors))
	return 0;
      /* ICEs cannot be inhibited.  */
    case DL_ICE:
      pfile->errors++;
      break;
    }

  *levelp = level;
  return 1;
}

#if 0
/* Set up for a diagnostic: print the file and line, bump the error
   counter, etc.  LINE is the logical line number; zero means to print
   at the location of the previously lexed token, which tends to be
   the correct place by default.  Returns 0 if the error has been
   suppressed.  */
int
_cpp_begin_message (pfile, code, line, column)
     cpp_reader *pfile;
     int code;
     unsigned int line, column;
{
	int	 level;
	if (!_cpp_can_begin_message(pfile, code, line, column, &level))
		return 0;
	print_location (pfile, line, column);
	if (DL_WARNING_P (level))
		fputs (_("warning: "), stderr);
	else if (level == DL_ICE)
		fputs (_("internal error: "), stderr);
	return 1;
}
#endif














/* Print the logical file location (LINE, COL) in preparation for a
   diagnostic.  Outputs the #include chain if it has changed.  A line
   of zero suppresses the include stack, and outputs the program name
   instead.  */
static SV *
sv_print_location (pfile, line, col)
     cpp_reader *pfile;
     unsigned int line, col;
{
  SV	*sv;

  if (!pfile->buffer || line == 0)
    sv = newSVpv("Text::CPP: ", 0);
  else
    {
      const struct line_map *map;

      map = lookup_line (&pfile->line_maps, line);
      print_containing_files (&pfile->line_maps, map);

      line = SOURCE_LINE (map, line);
      if (col == 0)
	col = 1;

      if (line == 0)
	sv = newSVpvf("%s: ", map->to_file);
      else if (CPP_OPTION (pfile, show_column) == 0)
	sv = newSVpvf("%s:%u: ", map->to_file, line);
      else
	sv = newSVpvf("%s:%u:%u: ", map->to_file, line, col);
    }

    return sv;
}

/* Set up for a diagnostic: print the file and line, bump the error
   counter, etc.  LINE is the logical line number; zero means to print
   at the location of the previously lexed token, which tends to be
   the correct place by default.  Returns 0 if the error has been
   suppressed.  */
/* Shevek: This isn't static and is called from lots of places.
 * Therefore, it isn't as simple as it appears to convert it to using
 * SVs and callbacks. There is an error in do_diagnostic in cpplib.c
 * where it has not yet been converted. I think this is something to
 * do with the multipurposing of this function. */
SV *
_sv_cpp_begin_message (pfile, code, line, column)
     cpp_reader *pfile;
     int code;
     unsigned int line, column;
{
	SV	*sv;
	int	 level;

	if (!_cpp_can_begin_message(pfile, code, line, column, &level))
		return NULL;
	sv = sv_print_location (pfile, line, column);
	if (DL_WARNING_P (level))
		sv_catpvn(sv, "warning: ", 9);
	else if (level == DL_ICE)
		sv_catpvn(sv, "internal error: ", 16);
	return sv;
}

#if 0
	/* Shevek: This is replaced by a macro in the header file now. */
/* Don't remove the blank before do, as otherwise the exgettext
   script will mistake this as a function definition */
#define v_message(msgid, ap) \
 do { vfprintf (stderr, msgid, ap); putc ('\n', stderr); } while (0)
#endif

#define v_message(sv, msgid, ap) cb_error(pfile, sv, msgid, ap)

/* Exported interface.  */

/* Print an error at the location of the previously lexed token.  */
void
cpp_error VPARAMS ((cpp_reader * pfile, int level, const char *msgid, ...))
{
  unsigned int line, column;
  SV		*sv;

  VA_OPEN (ap, msgid);
  VA_FIXEDARG (ap, cpp_reader *, pfile);
  VA_FIXEDARG (ap, int, level);
  VA_FIXEDARG (ap, const char *, msgid);

  if (pfile->buffer)
    {
      if (CPP_OPTION (pfile, traditional))
	{
	  if (pfile->state.in_directive)
	    line = pfile->directive_line;
	  else
	    line = pfile->line;
	  column = 0;
	}
      else
	{
	  line = pfile->cur_token[-1].line;
	  column = pfile->cur_token[-1].col;
	}
    }
  else
    line = column = 0;

  if ((sv = _sv_cpp_begin_message (pfile, level, line, column)))
    v_message (sv, msgid, ap);

  VA_CLOSE (ap);
}

/* Print an error at a specific location.  */
void
cpp_error_with_line VPARAMS ((cpp_reader *pfile, int level,
			      unsigned int line, unsigned int column,
			      const char *msgid, ...))
{
	SV	*sv;
  VA_OPEN (ap, msgid);
  VA_FIXEDARG (ap, cpp_reader *, pfile);
  VA_FIXEDARG (ap, int, level);
  VA_FIXEDARG (ap, unsigned int, line);
  VA_FIXEDARG (ap, unsigned int, column);
  VA_FIXEDARG (ap, const char *, msgid);

  if ((sv = _sv_cpp_begin_message (pfile, level, line, column)))
    v_message (sv, msgid, ap);

  VA_CLOSE (ap);
}

void
cpp_errno (pfile, level, msgid)
     cpp_reader *pfile;
     int level;
     const char *msgid;
{
  if (msgid[0] == '\0')
    msgid = "stdout";

  /* This used to call xstrerror. Let's assume it won't fail for
   * our purposes. */
  cpp_error (pfile, level, "%s: %s", msgid, strerror (errno));
}
