/*
 * Fracture.xs
 * Copyright (c) 2007, 2008, Juergen Weigert, Novell Inc.
 * This module is free software. It may be used, redistributed
 * and/or modified under the same terms as perl itself.
 *
 * see perldoc perlxstut, perlguts, perlapi
 *
 * Linus Torvalds: 
 * "Quite frankly, even if the choice of C were to do *nothing*
 * but keep the C++ programmers out, that in itself would be a 
 * huge reason to use C."
 * (http://thread.gmane.org/gmane.comp.version-control.git/57643/focus=57918)
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static int max_chars = 2000;
static int max_lines = 20;
static int max_cpl = 300;
static int verbose = 0;


struct char_stat
{
  char top_four[4];		// unused.
  unsigned int n_top_four[4];	// unused.
  unsigned int n_wordsx;	// number of words (distinct strings of is_word_ch_x()).

  int n_distinct;	// number of different printable nonwhitespace chars seen.
  int n_nonprint;	// number of chars >= 128, or < 32 but not whitespace.
  int n_whitespace;	// ' ', '\t', '\n', '\r' (only space and tab should appear, though)
  int n_iswordx;	// number of chars with is_word_ch_x()
  int n_other;		// non_word, non_withespace, but printable -> punctuation, etc.
  int wet_indent;	// whitespace indentation, including but not counting 
  			//MAX_INDENT_WETNESS
};

struct line
{
  int offset;		// byte offset of the first char of this line.
  int offset_l;		// line offset from the beginning of the file, beginning with 1
  int end_offset;	// byte offset of the first char of next line.
  int length;		// eff. length, ignoring trailing, includiing indent
  int weight;		// accumulator for fracture weights. Break after this line, if high.
  struct char_stat s;
};

#define MAX_INDENT_WETNESS	2	// two printable nonword chars allowed in indent.
#define WEIGHT_BLANK_LINE	800		// an empty line (applies to current line).
#define WEIGHT_NO_INDENT	400		// no longer indented line start
#define WEIGHT_wW_CHANGE	200		// word-char -> non-word-char transition
#define WEIGHT_INDENT_DIFF	100		// add/subtract max for indent change.
#define WEIGHT_LLEN_DIFF	300		// cut after short lines.
#define WEIGHT_DISTINCT_DIFF	50		// add/subtract max for distinct change.
#define WEIGHT_BALANCE_CHANGE	3		// other/iswordx balance changes


#if 0 //UNUSED
#define WEIGHT_Ww_START		100		// non-word-char start -> word-char start (applies to prev line)
#define WEIGHT_LINE_LENGTH	-1		// per character "cut after short lines" (applies to current line)
#endif

struct char_input
{
  int offset;			// byte offset of ch in text.
  int next_offset;		// byte offset of next_ch in text.
  int ch, next_ch, last_ch;	// characters read examined from text
  int next_ch_raw;		// identical to next_ch, except '\r' if next_ch is '\n'.
};

#define char_input_init(in)	\
do {				\
  (in)->ch = '\0';		\
  (in)->last_ch = '\0';		\
  (in)->next_ch = '\n';		\
  (in)->offset = -1; 		\
} while (0)

static int do_fetch(int *offp, const char *text, int len)
{
  while (++(*offp) < len)
    if (text[*offp])
      return text[*offp];

  *offp = len;			// oops, we walked beyond len.
  return '\n';			// fake a newline.
}

static int char_input_fetch(struct char_input *in, const char *text, int len)
{
  if (!in->ch) 		// initialisation.
    {
      in->ch = do_fetch(&in->offset, text, len);
      in->next_offset = in->offset;
      in->next_ch = do_fetch(&in->next_offset, text, len);
    }
  else
    {
      in->last_ch = in->ch;
      in->ch = in->next_ch_raw;				// get a '\r' to see "\r\n" correctly.
      in->offset = in->next_offset;
      in->next_ch = do_fetch(&in->next_offset, text, len);
    }

  if ((in->ch == '\n' && in->next_ch == '\r') ||
      (in->ch == '\r' && in->next_ch == '\n'))
    in->next_ch = do_fetch(&in->next_offset, text, len); // handle cr-lf and lf-cr as lf.

  in->next_ch_raw = in->next_ch;
  if (in->ch      == '\v') in->ch      = '\f';		// handle vert-tab as form-feed.
  if (in->ch      == '\r') in->ch      = '\n';		// handles single cr as lf.
  if (in->next_ch == '\r') in->next_ch = '\n';		// handles single cr as lf.
  return in->ch;
}

// private version of \w, we also include "$:."
// This is plain wrong for e.g. /etc/passed, where colon seperates fields.
// but nowadays, we more often see colon as a namespace separator, which 
// should not chop words in pieces. Imagine "Data::Dumper"
//
static int is_word_ch_x(int c)
{
  if ((c <= 'z' && c >= 'a') ||
      (c <= 'Z' && c >= 'A') ||
      (c <= '9' && c >= '0') ||
       c == '_' || c == '$' || 
       c == ':' || c == '.')
    return 1;
  return 0;
}


// returns number of characters excluding trailing whitespace or nonprintables,
// including wet_indent
// fills in the char_stat structure.
static int char_stat(struct char_stat *s, const char *text, int len)
{
  int ch_arr[128-32];
  int i, j, wetness = 0, in_word = 0;
  for (i = 0; i < 128-32; i++) ch_arr[i] = 0;
  while ((len > 0) && (text[len-1] <= ' ')) len--;
  bzero((void *)s, sizeof(struct char_stat));
  s->wet_indent = -1;

  for (i = 0; i < len; i++)
    {
      unsigned char c = (unsigned char)text[i];

      if (c == ' ' || c == '\t' || c == '\0' || c == '\n' || c == '\r') 
        {
          in_word = 0;
	  s->n_whitespace++;
	}
      else if (c < 32 || c > 127) 
	{
          in_word = 0;
	  if (s->wet_indent < 0) s->wet_indent = i - wetness;
	  s->n_nonprint++;
	}
      else
	{
	  ch_arr[c-32]++;
	  if (is_word_ch_x(c))
	    {
	      if (s->wet_indent < 0) s->wet_indent = i - wetness;
	      s->n_iswordx++;
	      if (!in_word) s->n_wordsx++;
	      in_word++;
	    }
	  else
	    {
	      in_word = 0;
	      if ((s->wet_indent < 0) && (++wetness > MAX_INDENT_WETNESS)) 
	        s->wet_indent = i - wetness + 1;
	      s->n_other++;
	    }
	}
    }
  if (s->wet_indent < 0) s->wet_indent = len - wetness;

  for (j = 0; j < 128-32; j++)
    {
      if (ch_arr[j]) s->n_distinct++;
    }

  for (i = 0; i < 4; i++)
    {
      int m = -1;
      int c = -1;
      for (j = 0; j < 128-32; j++)
        {
	  if (ch_arr[j] > m)
	    {
	      m = ch_arr[j];
	      c = j+32;
	    }
	}
      s->top_four[i] = c;
      s->n_top_four[i] = m;
      ch_arr[c-32] = 0;
    }

  return len;
}

// call once per line.
//
static void weight_line(struct line *l1, struct line *l2, const char *text)
{
  struct char_stat *s1, *s2;
  s1 = &l1->s;
  s2 = &l2->s;

  if (!l1->length)	// triggers only for first element.
    l1->length = char_stat(s1, text+l1->offset, l1->end_offset - l1->offset);

  if (!l2->length)	// triggers always...
    l2->length = char_stat(s2, text+l2->offset, l2->end_offset - l2->offset);

  // now use the stats left and right of the break point to adjust its 
  // weight in l1->weight.

  // break very easy, where an indent disappeared.
  if (s1->wet_indent > 0 && s2->wet_indent == 0) 
    l1->weight += WEIGHT_NO_INDENT;

  // encourage break, where indent decreases, emphasizing small numbers.
  // discourage break, where indent inreases, emphasizing small numbers.
  if (s2->wet_indent > 0) 
    l1->weight += (s1->wet_indent - s2->wet_indent) * WEIGHT_INDENT_DIFF / 
		  (s1->wet_indent + s2->wet_indent);

  // encourage break when coming from more iswordx chars to more other chars.
  if ((s1->n_iswordx > s1->n_other) &&
      (s2->n_iswordx < s2->n_other)) 
    l1->weight += (s1->n_iswordx + s2->n_other - s1->n_other - s2->n_iswordx)
      * WEIGHT_BALANCE_CHANGE;

  // also encourage when coming from less iswordx to more other chars.
  if ((s2->n_iswordx > s2->n_other) &&
      (s1->n_iswordx < s1->n_other)) 
    l1->weight += (s2->n_iswordx + s1->n_other - s2->n_other - s1->n_iswordx)
      * WEIGHT_BALANCE_CHANGE;

  // strongly encourage break when a line had no word chars, but the next has.
  // encourage a bit, where isxwordx increases,
  // discourage a bit, where isxwordx decreases.
  if ((s1->n_iswordx == 0) && s2->n_iswordx > 0) 
    l1->weight += WEIGHT_wW_CHANGE;
  else
    l1->weight += s2->n_iswordx - s1->n_iswordx;

  // encourage where number of distinct chars grows
  // discurage where number of distinct chars gets less
  // ... emphasizing small numbers..
  if (s2->n_distinct > 0)
    l1->weight += (s2->n_distinct - s1->n_distinct) * WEIGHT_DISTINCT_DIFF /
                  (s2->n_distinct + s1->n_distinct);

  // number of words, avg length of words, does that mean anything?
  // l1->weight += s1->n_wordsx   - s2->n_wordsx;	

  // encourage where lines get longer
  // discourage where lines get shorter,
  // emphasizing small numbers.
  if (l2->length > 0)
    l1->weight += (l2->length - l1->length) * WEIGHT_LLEN_DIFF /
                  (l2->length + l1->length);  	

  // little hack: 
  // WEIGHT_BLANK_LINE is already there, before weight_line gets called.
  // we use this property in this look-ahead logic:

  if (l2->weight >= WEIGHT_BLANK_LINE)
    {
      // Here we propagate 'something' into the blank lines.
      // without such propagation, all blank lines ar exactly equal (1250)
      // without any variation. This gives the peak detector a hard time to 
      // choose good peaks. bisect_fract() easily degenerates to cut at *every* 
      // 1250 peak, even, if there is only one or two lines of text between them.
      // Adding a small random value to the peaks is sufficient to help peak detector 
      // out of this degenerated mode.
      //
      // Instead of a random value, we use the weight of the line just before the 
      // blank line, because randomness is really bad for re-recognition of breaks.
      // And there is actually no reason to use a *small* value. :-)
      //

      l2->weight += l1->weight;
    }
}

// push_fracture
// adds the range from after the start_idx-line, to and including the 
// end_idx line to the return value r.
//
// use start_idx == -1 to include larr[0] ...
// 
static void push_fracture(AV *r, struct line *larr, int start_idx, int end_idx)
{
  AV *fra;
  int s_e_offset, s_offset_l;
  struct line *e = &larr[end_idx];
	
  if (start_idx < 0)
    {
      s_e_offset = 0;
      s_offset_l = 1;
    }
  else
    {
      s_e_offset = larr[start_idx].end_offset;
      s_offset_l = larr[start_idx].offset_l;
    }

  fra = (AV *)sv_2mortal((SV *)newAV());
  av_push(fra, newSVnv(s_e_offset));			// offset in bytes
  av_push(fra, newSVnv(e->end_offset - s_e_offset));	// length in bytes
  av_push(fra, newSVnv(s_offset_l));			// offset in lines
  av_push(fra, newSVnv(e->offset_l - s_offset_l+1));	// length in lines
  av_push(r, newRV((SV *)fra));
}

// is_small_enough() is a predicate, which returns true, if the 
// interval after start_idx, up to including end_idx does not exceeds the
// given max_* limits.
//
// use start_idx == -1 to include larr[0]
//
static int is_small_enough(struct line *larr, int start_idx, int end_idx, int max_lines, int max_chars)
{
  int n_chars = 0;
  struct line *l;

  if ((end_idx - start_idx) < 2) return 1;
  if ((end_idx - start_idx) > max_lines) return 0;

  // count chars after start_idx line, up to including end_idx line.
  for (l = &larr[start_idx+1]; l <= &larr[end_idx]; l++)
    n_chars += l->length;
  if (n_chars > max_chars) return 0;
  return 1;
}

static int find_max_idx(struct line *larr, int i1, int i2)
{
  int m = larr[i1].weight;
  int i = i1;
  int r = i;

  while (++i < i2)
    {
      if (m < larr[i].weight)
        {
	  m = larr[i].weight;
	  r = i;
	}
    }
  // printf("bisect(%d,%d, idx=%d, thr=%d)\n", i1, i2, r, m);
  return r;
}

// initial call shall be with start_idx == -1 and end_idx = larr_size;
static void bisect_fract(AV *r, struct line *larr, int start_idx, int end_idx, int max_lines, int max_chars)
{
  int bisec_idx;
  int ss, ee;

  if (is_small_enough(larr, start_idx, end_idx, max_lines, max_chars))
    {
      push_fracture(r, larr, start_idx, end_idx);
      return;
    }
  
  // find maximum weight, between excluding first and last weight, 
  // so that we have three distinct points to break at.

  ss = 1;
  ee = 1;
  bisec_idx = find_max_idx(larr, start_idx+ss, end_idx-ee);

  // max two of the following three blocks will be executed.
  // these three blocks are here to counter monotonic slopes
  // at the end of intervals. 
  // if other peaks surface, we jump there.
  // if all fails, we produce a series of two-liners along the slope,
  // only in this case we get a quadratic runtime.
  // given the high dynamics in calculating weight, a monotonic slope 
  // is unlikely, and a long monotonic slope extremly unlikely.

  // try to move away from the upper end, if we are there.
  while (bisec_idx == end_idx-ee-1)
    {
      ee++;
      // printf("%d,%d move down\n",start_idx,end_idx);
      if (end_idx-ee < start_idx+ss + 2) break;
      bisec_idx = find_max_idx(larr, start_idx+ss, end_idx-ee);
    }

  // try to move away from the lower end, if we are there.
  while (bisec_idx == start_idx+ss)
    {
      ss++;
      // printf("%d,%d move up\n",start_idx,end_idx);
      if (end_idx-ee < start_idx+ss + 2) break;
      bisec_idx = find_max_idx(larr, start_idx+ss, end_idx-ee);
    }

  // again try to move away from the upper end, if we are there.
  while (bisec_idx == end_idx-ee-1)
    {
      ee++;
      // printf("%d,%d move down\n",start_idx,end_idx);
      if (end_idx-ee < start_idx+ss + 2) break;
      bisec_idx = find_max_idx(larr, start_idx+ss, end_idx-ee);
    }
  
  // be recursive; this trivially keeps the entries in r sorted.
  bisect_fract(r, larr, start_idx, bisec_idx, max_lines, max_chars);
  bisect_fract(r, larr, bisec_idx,   end_idx, max_lines, max_chars);
}


MODULE = Text::Fracture	PACKAGE = Text::Fracture
PROTOTYPES: ENABLE

int
init(obj)
    HV *obj

  PREINIT:
    SV** pp;

  CODE:
    pp = hv_fetch(obj, "max_chars",    9, 0); if (pp) max_chars   = SvUV(*pp);
    pp = hv_fetch(obj, "max_lines",    9, 0); if (pp) max_lines   = SvUV(*pp);
    pp = hv_fetch(obj, "max_cpl",      7, 0); if (pp) max_cpl     = SvUV(*pp);
    pp = hv_fetch(obj, "verbose",      7, 0); if (pp) verbose     = SvUV(*pp);

    if (max_chars < max_cpl) croak("max_chars=%d must be greater than max_cpl=%d\n", max_chars, max_cpl);
    if (max_lines <= 1) croak("max_lines must > 1, not %d\n", max_lines);
    
    RETVAL = 1;
  OUTPUT:
    RETVAL



SV *
do_fract(sv_text)
    SV *sv_text
  PREINIT:
    int larr_size = 0;		// allocated max number of lines 
    int larr_idx = 0;		// idx = larr-l;
    struct line *larr = NULL;	// array to store line info.
    struct line *l = NULL;	// l = &larr[larr_idx]
    int line_count_total;	// counts through the file
    int line_count;		// counts since start of fragment
    AV *r;			// return array;
    int text_lnr;		// line number in text. starts with 1.
    int line_off;		// byte offset in text, where this line starts.
    int last_nonprint_off;	// byte offset in text, where a nonprintable char was.
    int last_whitespace_off;	// byte offset in text, where a whitespace was.
    int last_nonwordx_off;	// byte offset in text, where a non-word char was.
    STRLEN text_len;		// like strlen(text), but including '\0' bytes. STRLEN is unsigned!
    struct char_input in;	// input object.
    const char *text;

  INIT:
    text = (const char *)SvPV(sv_text, text_len);
    line_count = line_count_total = 0;
    r = (AV *)sv_2mortal((SV *)newAV());

    last_whitespace_off = last_nonprint_off = last_nonwordx_off = 0;

  CODE:
    if (verbose) warn(" max_chars=%d, max_lines=%d, max_cpl=%d\n text_len=%d\n", 
    	max_chars, max_lines, max_cpl, (int)text_len);


    // estimate size of larr[]
    line_off = 0;
    char_input_init(&in);
    while (in.offset < (int)text_len)
      {
	char_input_fetch(&in, text, (int)text_len);

	if ((in.ch == '\n') || (in.ch == '\f') || 
	    (in.next_offset - line_off > max_cpl))
	  {
	    // count this line as 1, or more, if it is longer than max_cpl.
	    // more is: chunks of at least max_cpl/2 size.
	    larr_size += (int)((in.next_offset - line_off) / max_cpl * 2) + 1;
	    line_off = in.next_offset;
	  }
      }
    larr_size++;	// we'll add one additional dummy element after the loop
    larr = (struct line *)calloc(sizeof(struct line), larr_size+1);


    // populate larr[]
    line_off = 0;
    text_lnr = 1;
    larr_idx = 0;
    char_input_init(&in);
    while (in.offset < (int)text_len)
      {
        unsigned char c;
	char_input_fetch(&in, text, (int)text_len);

	// similar logic as in char_stat(), but ignoring \0
	c = (unsigned char)in.ch;
	if (!is_word_ch_x(c)) 
	  last_nonwordx_off = in.offset;
	if (c == ' ' || c == '\t' || c == '\n' || c == '\r') 
	  last_whitespace_off = in.offset;
        if ((c && c < 32) || c > 127) 
	  last_nonprint_off = in.offset;

	if ((in.ch == '\n') || (in.ch == '\f'))
	  {
	    l = &larr[larr_idx++];
	    l->offset = line_off;
	    l->offset_l = text_lnr;
	    line_off = l->end_offset = in.next_offset;
	    if ((in.ch == '\f') || (in.ch == '\n' && in.last_ch == '\n'))
	      l->weight = WEIGHT_BLANK_LINE;
	    // This is the only weight that gets applied outside of weight_line().
	    // reason for this little hack: see inside of weight_line()
            text_lnr++;
	  }
	else if (in.next_offset - line_off > max_cpl)
	  {
	    int break_off, min_break_off;

	    l = &larr[larr_idx++];
	    l->offset = line_off;
	    l->offset_l = text_lnr;

	    //
	    // no newline in viscinity. sigh.
	    // find a (good?) break point or rather a not so bad one .
	    // between halfway of max_cpl and max_cpl
	    // we prefer to take the rightmost whitespace,
	    // if there is none, we take the rightmost nonprinting
	    // or failing the above, we take the rightmost nonword character.
	    // failing everything, we break just at max_cpl.
	    // 
	    break_off = in.next_offset;

	    // must consume at least max_cpl/2 chars now, 
	    // or larr_idx may go out of bounds later. Take care.
	    min_break_off = line_off+max_cpl/2;
	    if (last_whitespace_off > min_break_off)
	      break_off = last_whitespace_off;
	    else if (last_nonprint_off > min_break_off)
	      break_off = last_nonprint_off;
	    else if (last_nonwordx_off > min_break_off)
	      break_off = last_nonwordx_off;

	    line_off = l->end_offset = break_off;
	  }
      }

    assert(larr_idx < larr_size);	// calloc() above was big enough

    l = &larr[larr_idx];
    l->offset = line_off;
    l->offset_l = text_lnr;
    l->end_offset = in.next_offset;
    l->weight = WEIGHT_BLANK_LINE * 2;
    larr_size = larr_idx;		//  we know how long we really are

    for (larr_idx = 0; larr_idx <= larr_size; larr_idx++)
      {
	weight_line(&larr[larr_idx], &larr[larr_idx+1], text);

        if (verbose > 1)
	  {
  	    printf("larr[%d].w=%-5d lno=%-3d l=%d\n", 
  	    larr_idx, larr[larr_idx].weight,
  	    larr[larr_idx].offset_l, larr[larr_idx].length);
	  }
      }
    
    bisect_fract(r, larr, -1, larr_size, max_lines, max_chars);

    // 
    if (larr) free((void *)larr);
    //
    RETVAL = newRV((SV *)r);
  OUTPUT:
    RETVAL

