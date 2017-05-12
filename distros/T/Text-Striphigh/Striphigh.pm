package Text::Striphigh;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(striphigh);
$VERSION = '0.02';

# this sub is generated -- and this comment line is needed, leave intact!
sub striphigh ($) {
    local($_) = @_;

    return undef unless defined $_;
    return "" if $_ eq "";
    tr{\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF}
      {\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1A\x1B\x1C\x1D\x1E\x1F\x20\x21\x63\x23\x78\x59\x7C\x26\x5E\xA9\x61\x3C\x2D\x24\xAE\x5E\x25\x7E\x26\x27\x27\x75\x71\x2D\x2C\x31\x30\x3E\xBC\xBD\xBE\x28\x41\x41\x41\x41\x41\x41\xC6\x43\x45\x45\x45\x45\x49\x49\x49\x49\x42\x4E\x4F\x4F\x4F\x4F\x4F\x78\x30\x55\x55\x55\x55\x59\x70\x42\x61\x61\x61\x61\x61\x61\xE6\x63\x65\x65\x65\x65\x69\x69\x69\x69\x6F\x6E\x6F\x6F\x6F\x6F\x6F\x3A\x30\x75\x75\x75\x75\x79\x62\x79};
    s/\xA9/(C)/g;
    s-\xBC-1/4-g;
    s-\xBD-1/2-g;
    s/\xE6/ae/g;
    s/\xC6/AE/g;
    s-\xBE-3/4-g;
    s/\xAE/(R)/g;
    $_;
}

# generate ourselves if called as a program -- leave this comment here too!
if ( !caller ) {
    undef &striphigh;
    eval join("", <DATA>);
    die $@ if $@;
    gen_striphigh();
}

1;
__DATA__
package Text::Striphigh;

# this is the prototype striphigh from which the other striphigh routine
# is generated.
sub striphigh ($) {
    local($_) = @_;

    return undef unless defined $_;
    return "" if $_ eq "";
    # translation starts here -- leave this comment intact!
    # translate any special characters to something sane
    tr{¢§•¶ß®™´}
      {cxY|&^a<};
    tr{¨Ø±¥µ}
      {-^~'u};
    # apparently '∂' is a difficult character. perl5.003 barfs on it.
    tr{\xB6}
      {q};
    tr{∑∏}
      {-,};
    tr{π∫ª«–—◊ÿ›ﬁﬂÁÒ˜¯˛}
      {10>CBNx0YpBcn:0b};
    # translate accented letters to their non-accented counterpart
    tr/¿¡¬√ƒ≈/A/;
    tr/»… À/E/;
    tr/ÃÕŒœ/I/;
    tr/“”‘’÷/O/;
    tr/Ÿ⁄€‹/U/;
    tr/‡·‚„‰Â/a/;
    tr/ËÈÍÎ/e/;
    tr/ÏÌÓÔ/i/;
    tr/ÚÛÙıˆ/o/;
    tr/˘˙˚¸/u/;
    tr/˝ˇ/y/;
    # substitute some characters for multichar equivalents
    s/©/(C)/g;
    s/Æ/(R)/g;
    s-º-1/4-g;
    s-Ω-1/2-g;
    s-æ-3/4-g;
    s/∆/AE/g;
    s/Ê/ae/g;
    # the below translation happens implicitly in the bit and below, but
    # specify it anyway...
    tr(°£≠∞≤≥ø¡·)
      (!#-023?Aa);
    # now strip off all high bits that we missed so far.
    $_ &= "\x7F" x length;
    $_;
}

sub gen_striphigh () {
    seek(DATA, 0, 0);
    my(@more, $i, $h, $t, %s);

    while ( <DATA> ) {
	print;
	last if /^# this sub is generated/;
    }
    while ( <DATA> ) {
	last if /^# generate ourselves if called as a program/;
    }
    push(@more, $_);
    while ( <DATA> ) {
	push(@more, $_);
	last if /^sub striphigh/;
    }
    print;
    while ( <DATA> ) {
	push(@more, $_);
	last if /^\s*# translation starts here/;
	print;
    }
    $h = $t = '';
    for $i ( 128..255 ) {
	$h .= chr $i;
	my $tmp = striphigh(chr $i);
	if ( length($tmp) == 1 ) {
	    $t .= $tmp;
	}
	else {
	    $t .= chr $i;
	    $s{chr $i} = $tmp;
	}
    }
    # generate the simple translation. Using a not-so-simple statement.
    print <<PERL;
    tr{@{[join("", map { sprintf("\\x%02X", ord $_) } split(//, $h))]}}
      {@{[join("", map { sprintf("\\x%02X", ord $_) } split(//, $t))]}};
PERL
    while ( ($h, $t) = each %s ) {
	my($d) = grep { $t !~ /$_/ } qw(/ - ! | . : { });
	$h = sprintf("\\x%02X", ord $h);
	die("no delimiter!\n") unless $d;
	print <<PERL;
    s$d$h$d$t${d}g;
PERL
    }
    # {balance
    print <<'PERL';
    $_;
}

PERL
    print @more;
    print while <DATA>;
}

=head1 NAME

Text::Striphigh - Perl extension to strip the high bit off of ISO-8859-1 text.

=head1 SYNOPSIS

  use Text::Striphigh 'striphigh'

  $SevenBitsText = striphigh($TextContainingEightBitCharacters);

=head1 DESCRIPTION

The Text::Striphigh module exports a single function: C<striphigh>. This
function takes one argument, a string possibly containing high ASCII
characters in the ISO-8859-1 character set, and transforms this into a
string containing only 7 bits ASCII characters, by substituting every
high bit character with a similar looking standard ASCII character, or
with a sequence of standard ASCII characters.

Because of precisely the deficiency this package tries to offer a workaround
for is present in some of the things that process pod, there are no
examples in this manpage. Look at the source or the test script if you
want examples.

=head1 MAINTENANCE

If you ever want to change the striphigh function yourself, then don't
change the one containing the mile long C<tr{}{}> statement that you see
at first, change the one behind the C<__DATA__> that's a lot more readable.

After you've done that, simply run the C<Striphigh.pm> file through perl
to generate a new version of the first routine, and in fact of the entire
file, something like this:

 perl -w Striphigh.pm > Striphigh.pm.new
 mv Striphigh.pm.new Striphigh.pm

=head1 BUGS

Assumes the input text is ISO-8859-1, without even looking at the LOCALE
settings.

Some translations are probably less than optimal.

People will be offended if you run their names through this function, and
print the result on an envelope using an outdated printing device. However,
it's probably better than having that printer print a name with a high ASCII
character in it which happens to be the command to set the printer on fire.

=head1 AUTHOR

Jan-Pieter Cornet <johnpc@xs4all.nl>
