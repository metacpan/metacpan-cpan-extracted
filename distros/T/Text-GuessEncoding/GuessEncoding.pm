package Text::GuessEncoding;

use warnings;
use strict;
use POSIX;

=head1 NAME

Text::GuessEncoding - Convert Text from almost any encoding to ASCII or UTF8

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';


=head1 SYNOPSIS

CAUTION: unfinished code. No objects created.

Text::GuessEncoding gathers statistic about typical and invalid codes in 
both Latin1 and UTF-8. The concept of 'typical' is currently from an 
european point of view.
Based on this statistics, methods to transform to Latin1 and UTF-8 are provided. These methods handle 'broken' input strings with mixed encodings well.

The input string may or may not have its utf8 flag set correctly; the flag
is ignored. The returned string has the utf8 flag always off, and contains
no characters above codepoint 127 (which means it is inside the ASCII
character set).  If called in a list context, C<to_ascii()> returns the
mapping table as a second value.  This mapping table is a hash, using all
recognized encodings as keys. (Any well-formed string should only have one
encoding, but one can never be sure.) Value per encoding is an array ref,
listing all the codepoints in the following form:
C<[ [ $codepoint, $replacement_bytecount, [ $offset, ... ] ], ... ]>
Offset positions refer to the output string, where byte counts are identical
with character counts.

Example:
  
  my $guess = new Text::GuessEncoding();
  ($ascii, $map) = $guess->to_ascii("J\x{fc}rgen \x{c3}\x{bc}\n");
  # $ascii = 'Juergen ue';
  # $map = { 'utf8' => [252, 2, [8]], 'latin1' => [252, 2, [1]] };

The input string contains both utf8 encoded u-umlaut glyph and a plain latin1 byte u-umlaut.
The output string is never flagged as utf8.

  ($utf8, $map) = $guess->to_utf8("J\x{fc}rgen \x{c3}\x{bc}\n");
  # $utf8 = 'J\N{U+fc}rgen \N{U+fc}';
  # $map = { 'utf8' => [7], 'latin1' => [1] };
  
C<to_utf8> returns a simpler mapping table, as the string preserves more inforation. 
Note that the offsets differ from to_ascii(), as no multi-character rewriting takes place.
The output string is always flagged as utf8.

    use Text::GuessEncoding;

    my $asciitext = Text::GuessEncoding::to_ascii($enctext);
    my ($asciitext,$mapping) = Text::GuessEncoding::to_ascii($enctext);

=head1 EXPORT

C<to_ascii()> - create plain text in 7-bit ASCII encoding.
C<to_utf8()> - return UTF-8 encoded text .

=head1 SUBROUTINES/METHODS

=head2 to_ascii

C<to_ascii()> is implemented in perl code as a post-processor of C<to_utf8()>.
It examines C<charnames::viacode($_)> and constructs some useful ascii replacements from these.
A number of frequently used codepoint values can be precompiled for speed.

=cut

sub to_ascii 
{
  my ($text) = @_;

  # run through the text, searching a byte with the high order bit set.
  # this then, is a non-ascii byte, and needs conversion.

  # We distinguish two cases here:
  # $text might know that it is utf8, or $text might believe it is not.

  if (utf8::is_utf8($text))
    {
      warn "to_ascii() running on a utf8 string";
    }
  else
    {
      use Data::Dumper;
      ## exmine the first 24 bytes to guess if this is a 16bit encoding
      warn "to_ascii() running on a non-utf8 string";
      my @bytes = unpack("C24", $text);
      print Dumper \@bytes;
    }

  while ($text =~ m{[[:^ascii:]]}g)
    {
      printf "non-ascii char at pos %d\n", pos($text);
    }
}

=head2 sysread_tout(FILE, $len, $tout)

attempts to read $len bytes from FILE, with a select() timeout of $tout.

=cut

sub sysread_tout
{
  my ($FILE, $len, $tout) = @_;
  my $r = '';
  while ($len > 0)
    {
      my $rout;
      my $rin = '';
      vec($rin,fileno($FILE), 1) = 1;
      my ($n, $t) = select($rout = $rin, undef, undef, $tout);
      $tout = $t if defined $t;
      last unless $n;
      my $buf = '';
      last if sysread($FILE, $buf, 1) <= 0;
      $r .= $buf;
      $len--;
    }
  return $r;
}

=head2 $orig_mode = tty_raw(FILE)

Uses POSIX::Termios to set the terminal FILE to raw mode. Returns the previous mode so 
that it can be restored with tty_set().
=cut

sub tty_raw
{
  my ($FILE) = @_;

  my $t = POSIX::Termios->new;
  my $o = POSIX::Termios->new;
  $t->getattr(fileno $FILE);
  $o->getattr(fileno $FILE);

  $t->setlflag(0);	# -echo, -icanon
  $t->setcc(POSIX::VMIN, 1);
  $t->setcc(POSIX::VTIME, 0);
  tty_set($FILE, $t);
  return $o;
}


=head2 tty_set(FILE, $tty_mode)

Sets the FILE, which is assumed to be a terminal, to mode $tty_mode .
=cut

sub tty_set
{
  my ($FILE, $t) = @_;
  $t->setattr(fileno $FILE, POSIX::TCSANOW) or die "TCSANOW failed: $!\n";
}


=head2 get_cursor_pos

Sets tty to raw mode by calling tty_raw(), flushes STDIN, and sends ANSI code 'ESC [ 6 n' 
(DC6 aka Report cursor Position) and attempts to read the returned position with 
a 100msec timeout.
The terminal is returned to the previous mode, and a hashref containing the keys x, y 
is returned.

=cut
sub get_cursor_pos
{
  my ($hint) = @_;
  # 1 may be an ansi term?
  # testing device status report 6, as seen in vttest.
  my $t = tty_raw(\*STDIN);

  while (length(sysread_tout(\*STDIN, 1, 0.1))) { }

  syswrite(\*STDOUT, "\33[6n", 4);
  my $r = sysread_tout(\*STDIN, 10, 0.1);
  tty_set(\*STDIN, $t);
  return { x => $2 - 1, y => $1 - 1, hint => 'DC6' } if $r =~ m{^\33\[(\d+);(\d+)R};
  return undef;
}


=head2 probe_tty

Prints a cariage return (no linefeed), to move the cursor to a defined column
position.  
Prints a few test characters to STDOUT and calls get_cursor_pos() to check how 
the terminal reacts upon each, e.g. by  (not) advancing the cursor position
one or multiple positions.
Then restores the cursor to the carriage return position.
=cut

sub probe_tty
{
  #
  # we can use STDIN and STDERR.
  # 0) first, see, if the terminal can report cursor positions.
  syswrite(STDOUT, "\r", 1);
  my $o = get_cursor_pos();
  print ", x=$o->{x}\n" if $::verbose > 1;

  # - if not, abort.
  die "get_cursor_pos failed.\n" unless defined $o;

  # - if it can, store the current position 
  if ($o->{x} != 0)
    {
      warn "strace (or other) output interferes or\n" if $o->{x} >= 20;
      die "carriage return does not work.\n";
    }

  # 1) write a single byte ascii character, 'X' and check, 
  # if it advances by one. 
  syswrite(STDOUT, "\rX", 2);
  my $p = get_cursor_pos($o->{hint});
  print ", x=$p->{x}\n" if $::verbose;
  

  # - If not, it is probably in microsoft-multibyte encoding, 
  #   and requires '\0' prefixing. check this, report and abort.
  die "multi-byte mode" if $p->{x} != 1;

  # 2)Then try non-ascii characters, e.g. a-umlaut.
  # 2a) send its latin1 code, and see what happens,
  syswrite(STDOUT, "\r1\34434", 5);	# 1, a-umlaut-latin1, 3, 4
  $p = get_cursor_pos($o->{hint});
  print ", x=$p->{x}\n" if $::verbose;
  die "no report" unless defined $p;

  # - no advance indicates that the terminal is not in latin1 mode 
  #   or a lousy font is used.
  # - advance by 2 indicates a defect in the tty-emulator.
  die "latin1 a-umlaut caused confusion." if $p->{x} > 4 or $p->{x} < 2;

  # in utf8, our \344 consumes another char, thus the '3' is not printed.
  # we don't know what the font does then.
  my $maybe = 'utf8' if $p->{x} == 2 or $p->{x} == 3;
  $maybe = 'latin1'  if $p->{x} == 4;
  print "maybe $maybe\n" if $::verbose;
  # - advance by 1 says nothing, may be latin1.
  # 2b) send its utf8 code.

  syswrite(STDOUT, "\r1\303\24434", 6);	 # 1, a-umlaut-utf8, 3, 4
  $p = get_cursor_pos($o->{hint});
  print ", x=$p->{x}\n" if $::verbose;

  die "no report" unless defined $p;
  # - no advance indicates that a lousy font is used.
  # - advance by one indicates that the terminal is in utf8 mode.
  # - advance by two indicates that the terminal is in latin1 mode.

  syswrite(STDOUT, "\r      \r", 8) unless $::verbose;	 # clear scratch area
  
  if ($p->{x} == 4)
    {
      return 'utf8' if $maybe eq 'utf8';
      return 'possibly utf8';
    }
  
  return 'latin1' if $maybe eq 'latin1';
  return 'possibly latin1';
}


=head2 probe_file

C<probe_file()>  contains all the material, from which we should build C<to_utf8>.
=cut
##
## if utf8_valid is positive, then it can only be utf-8.
##   (if also utf8_invalid and/or latin1_typ are positive, then it is a mixture)
## if only utf8_invalid or latin1_typ are positive, then it is latin1.
## if all 3 are zero, it is plain ascii.
##
## FIXME: should take an optional length parameter to limit runtime.
##
sub probe_file
{
  my ($fd, $name) = @_;
  # print "probing $name\n" if $::verbose;

  my %typ_latin = map { $_ => 1 } qw(169 171  174 176 177 178 179 181
  185 187 191 192 193 194 195 196 197 199 200 201 202 203 204 205 206 207 208 209
  210 211 212 213 214 215 216 217 218 219 220 
  223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245
  246 249 250 251 252 253 189 164);


  # when running incremental, $fd is probably not seekable.
  # so we need to buffer characters to be re-read after a lookahead.

  # http://de.wikipedia.org/wiki/UTF-8#Kodierung

  my $utf8_valid   = 0;		# parser happy.
  my $utf8_invalid = 0;		# something wrong.
  my $latin1_typ   = 0;		# valid chars in 128..255 range followed by a ascii byte
  my $ascii        = 0;		# char in 10..127 range
  my $utf8_size    = 0;		# how many bytes belong to this utf-8 char.
  my $utf8_len     = 0;		# how many more bytes belong to this utf-8 char.
  my $utf8_start   = 0;		# ord of utf_8 start char.

  while (defined(my $c = getc($fd)))
    {
      my $v = ord($c);
      if ($utf8_len)
        {
	  if (($v & 0xc0) == 0x80)	# 10xx xxxx
	    {
#	      printf "0 %02x\n", $v;
	      unless (--$utf8_len)
	        {
	          $utf8_valid++;
		  $utf8_size = 0;
		}
	    }
	  else
	    {
#	      printf "0x %02x %02x '$c' $utf8_size-$utf8_len\n", $utf8_start, $v;
              if (($utf8_size - $utf8_len) == 1 and $typ_latin{$utf8_start})
		{
		  if ($v > 7 && $v < 128)
		    {
		      $latin1_typ++;
		      $ascii++;
		    }
		  elsif ($typ_latin{$v})
		    {
		      $latin1_typ += 2;
		    }
		  else
		    {
		      $utf8_invalid++;
		    }
		}
	      else
		{
		  $utf8_invalid++;
		}
	      $utf8_len = $utf8_size = $utf8_start = 0;
	    }
	}
      elsif ($v > 7 && $v < 128)
        {
	  $ascii++;
	  next;
	}
      elsif (($v & 0xe0) == 0xc0)	 	# 110x xxxx
        {
	  $utf8_start = $v;
	  $utf8_size = 2;
	  $utf8_len = 1;
#	  printf "1 %02x\n", $v;
	}
      elsif (($v & 0xf0) == 0xe0)		# 1110 xxxx
        {
	  $utf8_start = $v;
	  $utf8_size = 3;
	  $utf8_len = 2;
#	  printf "2 %02x\n", $v;
	}
      elsif (($v & 0xf8) == 0xf0)		# 1111 0xxx
        {
	  $utf8_start = $v;
	  $utf8_size = 4;
	  $utf8_len = 3;
#	  printf "3 %02x\n", $v;
	}
      elsif ($typ_latin{$v})
        {
	  $latin1_typ++;
	}
      else
        {
	  $utf8_invalid++;
#	  printf "x %02x\n", $v;
	}
    }
  print "$name: utf8_valid=$utf8_valid utf8_invalid=$utf8_invalid latin1_typ=$latin1_typ ascii=$ascii\n";
}

=head2 utf8toascii
convert a well formed utf8 file into ascii transcript.

#! /usr/bin/perl -w -T
# 
# utf8toascii -- convert a well formed utf8 file into ascii transcript.
#
# 2010-01-09, jw -- initial draft.
#
# perl -e 'use Encode; use charnames ":full"; map { print charnames::viacode($_). "\n" } unpack "W*", Encode::decode_utf8("J\x{c3}\x{bc}rgen fl\x{ef}\x{ac}\x{82} ü\x{c2}\x{a8}\n")' 
#
#use charnames ":full";
#
#my $ofd = \*STDOUT;
#my $ifd = \*STDIN;
#
#print STDERR utf8toascii($ifd, $ofd);
#exit 0;
#############
=cut
sub utf8toascii
{
  my ($ifd, $ofd) = @_;
  my $msg = '';

  binmode($ifd, ":utf8");

  my %ascii_map = 
  (
    'RIGHT DOUBLE QUOTATION MARK' 	=> "``",
    'LEFT DOUBLE QUOTATION MARK'  	=> "''",
    'RIGHT SINGLE QUOTATION MARK' 	=> "`",
    'LEFT SINGLE QUOTATION MARK'  	=> "'",
    'MODIFIER LETTER TURNED COMMA'  	=> "'",
    'MODIFIER LETTER VERTICAL LINE'  	=> "|",
    'RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK'	=> ">>",
    'LEFT-POINTING DOUBLE ANGLE QUOTATION MARK'	=> "<<",
    'DOUBLE ACUTE ACCENT'  		=> '"',	
    'ACUTE ACCENT'			=> "'",
    'DOUBLE LOW-9 QUOTATION MARK'  	=> ',,',
    'HORIZONTAL ELLIPSIS'			=> '...',
    'LATIN SMALL LETTER A WITH DIAERESIS' => "ae",
    'LATIN SMALL LETTER O WITH DIAERESIS' => "oe",
    'LATIN SMALL LETTER U WITH DIAERESIS' => "ue",
    'LATIN CAPITAL LETTER A WITH DIAERESIS' => "Ae",
    'LATIN CAPITAL LETTER O WITH DIAERESIS' => "Oe",
    'LATIN CAPITAL LETTER U WITH DIAERESIS' => "Ue",
    'LATIN SMALL LETTER SHARP S'		=> "ss",
    'LATIN SMALL LIGATURE FL'		=> "fl",
    'LATIN SMALL LIGATURE FI'		=> "fi",
    'LATIN SMALL LIGATURE FF'		=> "ff",
    'LATIN SMALL LIGATURE FFI'		=> "ffi",
    'LATIN SMALL LIGATURE FFL'		=> "ffl",
    'NON-BREAKING HYPHEN'			=> "-",
    'SOFT HYPHEN'				=> "-",
    'EN DASH'				=> "-",
    'EM DASH'				=> "--",
    'SECTION SIGN'			=> "#",
    'DIVISION SIGN'			=> "/",
    'WHITE BULLET'			=> "^",
    'DEGREE SIGN'				=> "^",
    'DAGGER'				=> "+",
    'DOUBLE DAGGER'			=> "(++)",
    'FEMININE ORDINAL INDICATOR'		=> "(x)",
    'BLACK DIAMOND SUIT'			=> "(*)",
    'BULLET'				=> "*",
    'ASTERISK OPERATOR'			=> "*",
    'MULTIPLICATION SIGN'			=> "*",
    'INCREMENT'				=> "-",
    'COPYRIGHT SIGN'			=> "(c)",
    'REGISTERED SIGN'			=> "(R)",
    'TRADE MARK SIGN'			=> "(TM)",
    'BLACK FOUR POINTED STAR'		=> "+",
    'NARROW NO-BREAK SPACE'		=> " ",
    'NO-BREAK SPACE'			=> " ",
    'FIGURE SPACE'			=> " ",
    'EM SPACE'				=> "  ",
    'DIE FACE-6'				=> "[6]",
    'DIE FACE-5'				=> "[5]",
    'DIE FACE-4'				=> "[4]",
    'DIE FACE-3'				=> "[3]",
    'DIE FACE-2'				=> "[2]",
    'DIE FACE-1'				=> "[1]",
    'DINGBAT NEGATIVE CIRCLED DIGIT ONE'	=> "(1)",
    'DINGBAT NEGATIVE CIRCLED DIGIT TWO'	=> "(2)",
    'DINGBAT NEGATIVE CIRCLED DIGIT THREE'=> "(3)",
    'DINGBAT NEGATIVE CIRCLED DIGIT FOUR'	=> "(4)",
    'DINGBAT NEGATIVE CIRCLED DIGIT FIVE'	=> "(5)",
    'DINGBAT NEGATIVE CIRCLED DIGIT SIX'	=> "(6)",
    'DINGBAT NEGATIVE CIRCLED DIGIT SEVEN'=> "(7)",
    'DINGBAT NEGATIVE CIRCLED DIGIT EIGHT'=> "(8)",
    'DINGBAT NEGATIVE CIRCLED DIGIT NINE'	=> "(9)",
    'WHITE SQUARE'			=> "[ ]",
    'UPWARDS ARROW'			=> "^",
    'DRAFTING POINT RIGHTWARDS ARROW'	=> "(->)",
    'VULGAR FRACTION ONE HALF'		=> "(1/2)",
    'VULGAR FRACTION THREE QUARTERS'	=> "(3/4)",
  );

  while (defined(my $ch = getc($ifd)))
    {
      my $v = ord($ch);
      if ($v < 128)
	{
	  print $ofd $ch;
	}
      else
	{
	  my $name = charnames::viacode($v);
	  if (defined(my $a = $ascii_map{$name}))
	    {
	      print $ofd $a;
	    }
	  elsif ($name =~ m{^LATIN (SMALL )?LETTER (FINAL |SMALL CAPITAL |INVERTED )*(\w)})
	    {
	      print $ofd lc $3;
	    }
	  elsif ($name =~ m{^LATIN CAPITAL LETTER (FINAL |SMALL CAPITAL |INVERTED )*(\w)})
	    {
	      print $ofd uc $2;
	    }
	  elsif ($name =~ m{^(ARABIC|GREEK) (SMALL )?LETTER (FINAL |SMALL CAPITAL |INVERTED )*(\w+)$})
	    {
	      print $ofd lc "-$4-";
	    }
	  elsif ($name =~ m{^(ARABIC|GREEK) CAPITAL LETTER (FINAL |SMALL CAPITAL |INVERTED )*(\w+)$})
	    {
	      print $ofd uc "-$3-";
	    }
	  else
	    {
	      printf $ofd "[[%x='$name']]", $v;
	      $msg .= sprintf "unknown %x='$name'\n", $v;
	    }
	}
    }
  return $msg;
}


=head1 AUTHOR

Juergen Weigert, C<< <jw at suse.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-toascii at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-GuessEncoding>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::GuessEncoding


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-GuessEncoding>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-GuessEncoding>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-GuessEncoding>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-GuessEncoding/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Juergen Weigert.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Text::GuessEncoding
