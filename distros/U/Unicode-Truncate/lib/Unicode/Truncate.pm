package Unicode::Truncate;

our $VERSION = '0.303';

use strict;

require Exporter;
use base 'Exporter';
our @EXPORT = qw(truncate_egc truncate_egc_inplace);

# Commented out for distribution by Inline::Module::LeanDist
#use Inline::Module::LeanDist C => 'DATA', FILTERS => [ [ 'Uniprops2Ragel', push(@INC, 'inc') ], [ Ragel => '-G2' ] ];

# XSLoader added for distribution by Inline::Module::LeanDist:
require XSLoader; XSLoader::load(__PACKAGE__, $VERSION);



1;


__DATA__
__C__


%%{
  machine egc_scanner;

  write data;
}%%


static void _scan_egc(char *input, size_t len, size_t trunc_size, int *truncation_required_out, size_t *cut_len_out, int *error_occurred_out) {
  size_t cut_len = 0;
  int truncation_required = 0, error_occurred = 0;

  char *p, *pe, *eof, *ts, *te;
  int cs, act;
 
  ts = p = input;
  te = eof = pe = p + len;

  %%{
    action record_cut {
      if (p - input >= trunc_size) {
        truncation_required = 1;
        goto done;
      }

      cut_len = te - input;
    }


    ## Extract properties from unidata/GraphemeBreakProperty.txt (see inc/Inline/Filters/Uniprops2Ragel.pm)

    ALL_UNIPROPS


    ## This regexp is pretty much a straight copy from the "extended grapheme cluster" row in this table:
    ## http://www.unicode.org/reports/tr29/#Table_Combining_Char_Sequences_and_Grapheme_Clusters

    CRLF = CR LF;

    RI_Sequence = Regional_Indicator+;

    Hangul_Syllable = L* V+ T*    |
                      L* LV V* T* |
                      L* LVT T*   |
                      L+          |
                      T+;

    main := |*
              CRLF => record_cut;

              (
                ## No Prepend characters in unicode 7.0
                (RI_Sequence | Hangul_Syllable | (Any_UTF8 - Control))
                (Extend | SpacingMark)*
              ) => record_cut;

              Any_UTF8 => record_cut;
            *|;


    write init;
    write exec;
  }%%

  done:

  if (cs < egc_scanner_first_final) {
    error_occurred = 1;
    cut_len = p - input;
  }

  *truncation_required_out = truncation_required;
  *cut_len_out = cut_len;
  *error_occurred_out = error_occurred;
}






static SV *_truncate(SV *input, long trunc_len, SV *ellipsis, int in_place, const char *func_name) {
  size_t trunc_size;
  char *input_p, *ellipsis_p;
  size_t input_len, ellipsis_len;
  size_t cut_len;
  int truncation_required, error_occurred;
  SV *output;
  char *output_p;
  size_t output_len;

  SvUPGRADE(input, SVt_PV);
  if (!SvPOK(input)) croak("need to pass a string in as first argument to %s", func_name);

  input_len = SvCUR(input);
  input_p = SvPV(input, input_len);

  if (trunc_len < 0) croak("trunc size argument to %s must be >= 0", func_name);
  trunc_size = (size_t) trunc_len;

  if (ellipsis == NULL) {
    ellipsis_len = 3;
    ellipsis_p = "\xE2\x80\xA6"; // UTF-8 encoded U+2026 ellipsis character
  } else {
    SvUPGRADE(ellipsis, SVt_PV);
    if (!SvPOK(ellipsis)) croak("ellipsis must be a string in 3rd argument to %s", func_name);

    ellipsis_len = SvCUR(ellipsis);
    ellipsis_p = SvPV(ellipsis, ellipsis_len);

    if (!is_utf8_string(ellipsis_p, ellipsis_len)) croak("ellipsis must be utf-8 encoded in 3rd argument to %s", func_name);
  }

  if (ellipsis_len > trunc_size) croak("length of ellipsis is longer than truncation length in %s", func_name);
  trunc_size -= ellipsis_len;

  _scan_egc(input_p, input_len, trunc_size, &truncation_required, &cut_len, &error_occurred);

  if (error_occurred) croak("input string not valid UTF-8 (detected at byte offset %lu in %s)", cut_len, func_name);

  output_len = cut_len + ellipsis_len;

  if (input_len <= trunc_len) {
    truncation_required = 0;
    output_len = input_len;
  }

  if (in_place) {
    output = input;

    if (truncation_required) {
      SvGROW(output, output_len);
      SvCUR_set(output, output_len);
      output_p = SvPV(output, output_len);

      memcpy(output_p + cut_len, ellipsis_p, ellipsis_len);
    }
  } else {
    if (truncation_required) {
      output = newSVpvn("", 0);

      SvGROW(output, output_len);
      SvCUR_set(output, output_len);
      output_p = SvPV(output, output_len);

      memcpy(output_p, input_p, cut_len);
      memcpy(output_p + cut_len, ellipsis_p, ellipsis_len);
    } else {
      output = newSVpvn(input_p, input_len);
    }
  }

  SvUTF8_on(output);

  return output;
}



SV *truncate_egc(SV *input, long trunc_len, ...) {
  Inline_Stack_Vars;

  SV *ellipsis;

  const char *func_name = "truncate_egc";

  if (Inline_Stack_Items == 2) {
    ellipsis = NULL;
  } else if (Inline_Stack_Items == 3) {
    ellipsis = Inline_Stack_Item(2);
  } else {
    croak("too many items passed to %s", func_name);
  }

  return _truncate(input, trunc_len, ellipsis, 0, func_name);
}


void truncate_egc_inplace(SV *input, long trunc_len, ...) {
  Inline_Stack_Vars;

  SV *ellipsis;

  const char *func_name = "truncate_egc_inplace";

  if (SvREADONLY(input)) croak("input string can't be read-only with inplace mode at %s", func_name);

  if (Inline_Stack_Items == 2) {
    ellipsis = NULL;
  } else if (Inline_Stack_Items == 3) {
    ellipsis = Inline_Stack_Item(2);
  } else {
    croak("too many items passed to %s", func_name);
  }

  _truncate(input, trunc_len, ellipsis, 1, func_name);
}






__END__



=encoding utf-8

=head1 NAME

Unicode::Truncate - Unicode-aware efficient string truncation

=head1 SYNOPSIS

    use utf8;
    use Unicode::Truncate;

    truncate_egc("hello world", 7);
    ## returns "hell…";

    truncate_egc("hello world", 7, '');
    ## returns "hello w"

    truncate_egc('深圳', 7);
    ## returns "深…"

    truncate_egc("née Jones", 5)'
    ## returns "n…" (not "ne…", even in NFD)

    truncate_egc("\xff", 10)
    ## throws exception:
    ##   "input string not valid UTF-8 (detected at byte offset 0 in truncate_egc)"

    my $str = "hello world";
    truncate_egc_inplace($str, 8)
    ## $str is now "hello…";

=head1 DESCRIPTION

This module is for truncating UTF-8 encoded Unicode text to particular B<byte> lengths while inflicting the least amount of data corruption possible. The resulting truncated string will be no longer than your specified number of bytes (after UTF-8 encoding).

All truncated strings will continue to be valid UTF-8: it won't cut in the middle of a UTF-8 encoded code-point. Furthermore, if your text contains combining diacritical marks, this module will not cut in between a diacritical mark and the base character. It will in general try to preserve what users perceive as whole characters, with as little as possible mutilation at the truncation site.

The C<truncate_egc> function truncates only between L<extended grapheme clusters|https://en.wikipedia.org/wiki/Universal_Character_Set_characters#Characters_grapheme_clusters_and_glyphs> (as defined by L<Unicode TR29|http://www.unicode.org/reports/tr29/#Grapheme_Cluster_Boundaries> version 7.0.0).

The C<truncate_egc_inplace> function is identical to C<truncate_egc> except that the input string will be modified so that no copying occurs. If you pass in a read-only value it will throw an exception.

Eventually I'd like to support other boundaries such as words and sentences. Those functions will be named C<truncate_word> and so on.


=head1 RATIONALE

Of course in a perfect world we would only need to worry about the amount of space some text takes up on the screen, in the real world we often have to or want to make sure things fit within certain byte size capacity limits. Many databases, network protocols, and file-formats require honouring byte-length restrictions. Even if they automatically truncate for you, are they doing it properly and consistently? On many file-systems, file and directory names are subject to byte-size limits. Many APIs that use C structs have fixed limits as well. You may even wish to do things like guarantee that a collection of news headlines will fit in a single ethernet packet.

I knew I had to write this module after I asked Tom Christiansen about the best way to truncate unicode to fit in fixed-byte fields and he got angry and told me to never do that. :)

Why not just use C<substr> on a string before UTF-8 encoding it? The main problem with that is the number of bytes that an encoded string will consume is not known until after you encode it. It depends on how many "high" code-points are in the string, how "high" those code-points are, the normalisation form chosen, and (relatedly) how many combining marks are used. Even with perl unicode strings (ie before encoding), using C<substr> will cut in front of combining marks.

Truncating post-encoding may result in invalid UTF-8 partials at the end of your string, as well as cutting in front of combining marks.

One interesting aspect of unicode's combining marks is that there is no specified limit to the number of combining marks that can be applied. So in some interpretations a single character/grapheme/whatever can take up an arbitrarily large number of bytes. However, there are various recommendations such as the L<Unicode UAX15-D3|http://www.unicode.org/reports/tr15/#UAX15-D3> "stream-safe" limit of 30. Reportedly the largest known "legitimate" use is a 1 base + 8 combining marks grapheme used in a Tibetan script.


=head1 ELLIPSIS

When a string is truncated, C<truncate_egc> indicates this by appending an ellipsis. The length of the truncated content B<including> the ellipsis is guaranteed to be no greater than the byte size limit you specified.

By default the ellipsis is the character U+2026 (…) however you can use any other string by passing it in as the third argument. The ellipsis string must not contain invalid UTF-8 (it can be encoded or can contain perl high-code points, up to you). Note the default ellipsis consumes 3 bytes in UTF-8 encoding which is the same as 3 periods in a row.


=head1 IMPLEMENTATION

This module uses the L<ragel|http://www.colm.net/open-source/ragel/> state machine compiler to parse/validate UTF-8 and to determine the presence of combining characters. Ragel is nice because we can determine the truncation location with a single pass through the data in an optimised C loop.

One of the requirements of this module was to additionally validate UTF-8 encoding. This is so you can run it against strings with or without having decoded them with C<Encode::decode> first. This module will throw exceptions if the strings to be truncated aren't UTF-8. This property lets us minimise the amount of times a user-supplied string is "decoded". With this module, you can accept an arbitrary string from a web request (say), validate that it is UTF-8, truncate it if necessary, and write it out to a DB, all with only a single pass over the data.

As mentioned, this module will not scan further than it needs to in order to determine the truncation location. So creating a short truncation of a really long string doesn't require traversing the entire string. However, this module won't validate that the bytes beyond its truncation location are valid UTF-8.

Another purpose of this module is to be a "proof of concept" for L<Inline::Module::LeanDist> and L<Inline::Filters::Ragel>. This distribution concept was of course heavily inspired by L<Inline::Module>.


=head1 SEE ALSO

L<Unicode-Truncate github repo|https://github.com/hoytech/Unicode-Truncate>

Although efficient, as discussed above, C<substr> will not be able to give you a guaranteed byte-length output (if done pre-encoding) and will corrupt text (pre or post-encoding).

There are several similar modules such as L<Text::Truncate>, L<String::Truncate>, L<Text::Elide> but they are all essentially wrappers around C<substr> and are subject to its limitations.

A reasonable "99%" solution is to encode your string as UTF-8, truncate at the byte-level with C<substr>, decode with C<Encode::FB_QUIET>, and then re-encode it to UTF-8. This will ensure that the output is always valid UTF-8, but will still risk corrupting unicode text that contains combining marks.

Ricardo Signes suggested an algorithm using L<Unicode::GCString> which would also be correct but likely less efficient.

It may be possible to use the regexp engine's C<\X> combined with C<(?{})> in some way but I haven't been able to figure that out.


=head1 BUGS

Of course I can't test this module on all the writing systems of the world so I don't know the severity of the corruption in all situations. It's possible that the corruption can be minimised in additional ways without sacrificing the simplicity or efficiency of the algorithm. If you have any ideas please let me know and I'll try to incorporate them.

Eventually I'd like to truncate on other boundaries specified by unicode, such as word, sentence, and line.

It would be nice to be able to apply an EGC limit such as 30.

This module doesn't handle the UTF-16 surrogate range in the grapheme properties files because C<Encode::encode> isn't encoding them the way I'd need them to. That's OK because these aren't valid UTF-8 anyway.

Perl internally supports characters outside what is officially unicode. This module only works with the official UTF-8 range so if you are using this perl extension (perhaps for some sort of non-unicode sentinel value) this module will throw an exception indicating invalid UTF-8 encoding (which is more of a feature than a bug given this module's primary purpose of validating and truncating untrusted, user-provided text).


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2014-2017 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut
