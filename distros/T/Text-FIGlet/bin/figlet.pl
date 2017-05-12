#!/usr/bin/perl -w
package main;
use strict;
use vars '$VERSION';
use Text::FIGlet 2.01;
$VERSION = 2.19.2;

my %opts;
$opts{-C} = [];
$opts{$_} = undef for
  qw(A D E L R U X c d e f h help -help l r x);
$opts{$_} = "0 but true" for
  qw(I m w);
for (my $i=0; $i <= scalar @ARGV; $i++) {
  last unless defined($ARGV[$i]);
  shift && last if $ARGV[$i] eq '--';
  if( $ARGV[$i]  =~ /^-N$/ ) {
    shift; $i--;
    $opts{-C} = [];
  }
  if( $ARGV[$i]  =~ /^-C=?(.*)/ ) {
    shift; $i--;
    $opts{-C} = [ @{$opts{-C}}, 
		  defined($1) && $1 ne '' ?
		  $1 : defined($opts{-C}) ? do{$i--; shift} : undef
		];
    next;
  }
  foreach my $key ( sort { length($b)-length($a) } keys %opts) {
    if( $ARGV[$i] =~ /^-$key=?(.*)/ ){
      shift; $i--;
      $opts{$key} = defined($1) && $1 ne '' ?
	$1 : defined($opts{$key}) ? do{$i--; shift} : 1;
      last;
    }
  }
}
defined($_) && $_ eq '0 but true' && ($_ = undef) for values %opts;
if( $opts{help}||$opts{h}||$opts{-help} ){
    eval "use Pod::Text;";
    die("Unable to print man page: $@\n") if $@;
    pod2text(__FILE__);
    exit 0;
}

$opts{I} ||= 0;
if( $opts{I} == 1 ){
  my @F = unpack("c*", $VERSION);
  die(10_000 * $F[0] + 100 * $F[1] +$F[2], "\n");
}

my $font = Text::FIGlet->new(-D=>$opts{D}&&!$opts{E},
			  -d=>$opts{d},
			  -m=>$opts{m}||-2,
			  -f=>$opts{f});
@_ = map { -C=> $_ } @{$opts{-C}} if scalar @{$opts{-C}};
my $ctrl = Text::FIGlet->new( @_,
			     -d=>$opts{d}) if @_;

if( $opts{I} == 2 ){
    die("$font->{-d}\n");
}
if( $opts{I} == 3 ){
    die("$font->{-f}\n");
}

my %figify = (
	      -U=>$opts{U},
	      -X=>($opts{L}&&'L')||($opts{R}&&'R'),
	      -m=>$opts{m},
	      -w=>$opts{w},
	      -x=>($opts{l}&&'l')||($opts{c}&&'c')||($opts{r}&&'r') );
croak("figlet.pl: cannot use both -A and -e") if $opts{A} && $opts{e};
if( $opts{e} ){
    $opts{A} = 1;
    @ARGV = eval "@ARGV";
    croak($@) if $@;
}
if( $opts{A} ){
    $_ = join(' ', map($_ = $_ eq '' ? $/ : $_, @ARGV));
    #XXXtraneous space...
    print scalar $font->figify(-A=>($ctrl ? $ctrl->tr() : $_), %figify);
    exit 0;
}
else{
    Text::FIGlet::croak("Usage: figlet.pl -help\n") if @ARGV;
    print scalar $font->figify(-A=>($ctrl ? $ctrl->tr() : $_), %figify)
      while <STDIN>;
}
__END__
=pod

=head1 NAME

figlet.pl - display large characters made up of ordinary screen characters

=head1 SYNOPSIS

B<figlet.pl>
[ B<-A> ]
[ B<-C> ]
[ B<-D> ]
[ B<-E> ]
[ B<-L> ]
[ B<-N> ]
[ B<-R> ]
[ B<-U> ]
[ B<-X> ]
[ B<-c> ]
[ B<-d=>F<fontdirectory> ]
[ B<-e> C<EXPR>]
[ B<-f=>F<fontfile> ]
[ B<-help> ]
[ B<-l> ]
[ B<-r> ]
[ B<-w=>I<outputwidth> ]
[ B<-x> ]

=head1 DESCRIPTION

B<figlet.pl> prints its input using large characters made up of
ordinary screen characters. B<figlet.pl> output is generally
reminiscent of the sort of I<signatures> many people like
to put at the end of e-mail and UseNet messages. It is
also reminiscent of the output of some banner programs,
although it is oriented normally, not sideways.

B<figlet.pl> can print in a variety of fonts, both left-to-right
and right-to-left, with adjacent characters kerned and
I<smushed> together in various ways. B<figlet.pl> fonts are
stored in separate files, which can be identified by the
suffix I<.flf>. Most B<figlet.pl> font files will be stored in
FIGlet's default font directory.

B<figlet.pl> can also use control files, which tell it to
map certain input characters to certain other characters,
similar to the Unix tr command. Control files can be
identified by the suffix F<.flc>. Most FIGlet control
files will be stored in FIGlet's default font directory.

=head1 OPTIONS

=over

=item B<-A>

All Words. Once the - arguments are read, all words remaining on the command
line are used instead of standard input to print letters. Allows shell scripts
to generate large letters without having to dummy up standard input files.

An empty character, obtained by two sequential and empty quotes, results in a
line break.

To include text begining with - that might otherwise appear to be an invalid
argument, use the argument --

=item B<-C>=F<controlfile>
B<-N>

These options deal with FIGlet F<controlfiles>. A F<controlfile> is a file
containing a list of commands that FIGlet executes each time it reads a
character. These commands can map certain input characters to other characters,
similar to the Unix tr command or the FIGlet B<-D> option. FIGlet maintains
a list of F<controlfiles>, which is empty when FIGlet starts up. B<-C> adds
the given F<controlfile> to the list. B<-N> clears the F<controlfile> list,
cancelling the effect of any previous B<-C>. FIGlet executes the commands in
all F<controlfiles> in the list. See the file F<figfont.txt>, provided with
FIGlet, for details on how to write a F<controlfile>.

=item B<-D>
B<-E>

B<-E> is the default, and a no-op.

B<-D> switches  to  the German (ISO 646-DE) character set.
Turns `[', `\' and `]' into umlauted A, O and U,  respectively.
`{',  `|' and `}' turn into the respective lower case versions of these.
`~' turns into  s-z.

These options are deprecated, which means they may soon
be removed. The modern way to achieve this effect is with
control files, see B<-C>.

=item B<-I>I<infocode>

These options print various information about FIGlet, then exit.

=over

=item 1 Version (integer).

This will print the version of your copy of FIGlet as a decimal integer.
The main version number is multiplied by 10000, the sub-version number is
multiplied by 100, and the sub-sub-version number is multiplied by 1.
These are added together, and the result is printed out. For example,
FIGlet 2.1.2 will print ``20102''. If there is ever a version 2.1.3,
it will print ``20103''.  Similarly, version 3.7.2 would print ``30702''.
These numbers are guaranteed to be ascending, with later versions having
higher numbers.

=item 2 Default font directory.

This will print the default font directory. It is affected by the B<-d> option.

=item 3 Font.

This will print the name of the font FIGlet would use. It is affected by the
B<-f> option. This is not a filename; the I<.flf> suffix is not printed.

=back

=item B<-L>
B<-R>
B<-X>

These options control whether FIGlet prints left-to-right or right-to-left.
B<-L> selects left-to-right printing. B<-R> selects right-to-left printing.
B<-X> (default) makes FIGlet use whichever is specified in the font file.

=item B<-U>

Process input as Unicode, if you use a control file with the C<u>
directive unicode processing is automagically enabled for any text
processed with that control.

=item B<-c>
B<-l>
B<-r>
B<-x>

These options handle the justification of FIGlet output. B<-c> centers the
output horizontally. B<-l> makes the output flush-left. B<-r> makes it
flush-right. B<-x> (default) sets the justification according to whether
left-to-right or right-to-left text is selected. Left-to-right text will be
flush-left, while right-to-left text will be flush-right. (Left-to-rigt
versus right-to-left text is controlled by B<-L>, B<-R> and B<-X>.)

=item B<-d>=F<fontdirectory>

Change the default font directory. FIGlet looks for fonts first in the default
directory and then in the current directory. If the B<-d> option is not
specified, FIGlet uses the directory that was specified when it was compiled.
To find out which directory this is, use the B<-I2> option.

=item B<-e> C<EXPR>

Evaluates the remaining arguments as perl and processes the results.
This can be especially useful for retrieving Unicode characters.

=item B<-f>=F<fontfile>

Select the font. The I<.flf> suffix may be left off of fontfile, in which case
FIGlet automatically appends it. FIGlet looks for the file first in the default
font directory and then in the current directory, or, if fontfile was given as
a full pathname, in the given directory. If the B<-f> option is not specified,
FIGlet uses the font that was specified when it was compiled. To find out which
font this is, use the B<-I3> option.

=item B<-m=>I<smushmode>

Specifies how B<Text::FIGlet::Font> should ``smush'' and kern consecutive
characters together. On the command line, B<-m0> can be useful, as it tells
FIGlet to kern characters without smushing them together. Otherwise, this
option is rarely needed, as a B<Text::FIGlet::Font> font file specifies the
best smushmode to use with the font. B<-m> is, therefore, most useful to font
designers testing the various smushmodes with their font. I<smushmode> can be
-2 through 63.

=over

=item S<-2>

Get mode from font file (default).

Every FIGlet font file specifies the best smushmode to use with the font.
This will be one of the smushmodes (-1 through 63) described in the following
paragraphs.

=item S<-1>

No smushing or kerning.

Characters are simply concatenated together.

=item S<-0>

Fixed width.

This will pad each character in the font such that they are all a consistent
width. The padding is done such that the character is centered in it's "cell",
and any odd padding is the trailing edge.

=item S<0>

Kern only.

Characters are pushed together until they touch.

=back

=item B<-w>=I<outputwidth>

These options control the outputwidth, or the
screen width FIGlet assumes when formatting its
output. FIGlet uses the outputwidth to determine
when to break lines and how to center the output.
Normally, FIGlet assumes 80 columns so that people
with wide terminals won't annoy the people they e-mail
FIGlet output to. B<-w> sets the outputwidth 
to the given integer. An outputwidth of 1 is a
special value that tells FIGlet to print each non-
space character, in its entirety, on a separate line,
no matter how wide it is. Another special outputwidth
is -1, it means to not warp.

=back

=head1 EXAMPLES

C<figlet.pl -A Hello "" World>

=head1 ENVIRONMENT

B<figlet.pl> will make use of these environment variables if present

=over

=item FIGFONT

The default font to load.
If undefined the default is F<standard.flf>
It should reside in the directory specified by FIGLIB.

=item FIGLIB

The default location of fonts.
If undefined the default is F</usr/games/lib/figlet>

=back

=head1 FILES

FIGlet font files are available at

  ftp://ftp.figlet.org/pub/figlet/

=head1 BUGS

Under pre 5.8 perl B<-e> may munge the first character if it is Unicode,
this is a bug in perl itself. The output is usually:

=over

=item 197  LATIN CAPITAL LETTER A WITH RING ABOVE

=item 187  RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK

=back

    o   \\ 
   /_\   >>
  /   \ // 

If this occurs, prepend the sequence with a null.

=head1 SEE ALSO

L<Text::FIGlet>, L<figlet(6)>, L<banner(6)>, L<http://www.figlet.org|>

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>|<webmaster@pthbb.org>

=cut
