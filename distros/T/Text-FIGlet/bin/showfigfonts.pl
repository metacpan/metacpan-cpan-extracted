#!/usr/bin/perl -w
use strict;
use vars '$VERSION';
use Text::FIGlet 2.01;
use File::Find;
$VERSION = 2.1.2; #2.11

my %opts;
$opts{$_} = undef for
  qw(D E h help -help);
$opts{$_} = "0 but true" for
  qw(d w);
for (my $i=0; $i <= scalar @ARGV; $i++) {
  last unless exists($ARGV[$i]);
  shift && last if $ARGV[$i] eq '--';
  foreach my $key ( sort { length($b)-length($a) } keys %opts) {
    if ( $ARGV[$i] =~ /^-$key=?(.*)/ ) {      
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
Text::FIGlet::croak("Usage: showfigfonts.pl -help\n") if @ARGV;


#support -m?!
my %figify = (
	      -w=>$opts{w}),


$opts{d} ||= $ENV{FIGLIB} || '/usr/games/lib/figlet/';
my @fonts;
find(sub {
	return unless -f && /.[ft]lf$/;
	push @fonts, $_;}, $opts{d});

$|++;
foreach ( sort @fonts ){
  my $font = Text::FIGlet->new(
			       -D=>$opts{D}&&!$opts{E},
			       -d=>$opts{d},
			       -f=>$_);
  s/\.[ft]lf$//;
  print "$_ :\n", scalar $font->figify(-A=>$_, -w=>$opts{w}), "\n";
}
__END__
=pod

=head1 NAME

showfigfonts.pl - prints samples of the available FIGlet fonts

=head1 SYNOPSIS

B<showfigfonts.pl>
[ B<-D> ]
[ B<-d=>F<fontdirectory> ]
[ B<-help> ]
[ B<-w=>I<outputwidth> ]

=head1 DESCRIPTION

This will recusrively fetch fonts displaying a sample
(the name of the font) of each in alphabetical order.

=head1 OPTIONS

=over

=item B<-D>
B<-E>

B<-E> is the default, and a no-op.

B<-D>  switches  to  the German (ISO 646-DE) character
set.  Turns `[', `\' and `]' into umlauted A, O and
U,  respectively.   `{',  `|' and `}' turn into the
respective lower case versions of these.  `~' turns
into  s-z.

These options are deprecated, which means they may soon
be removed.

=item B<-d>=F<fontdirectory>

Change the default font  directory.   FIGlet  looks
for  fonts  first in the default directory and then
in the current directory.  If the B<-d> option is  not
specified, FIGlet uses the directory that was specified
when it was  compiled.   To  find  out  which
directory this is, use the B<-I2> option.

=item B<-w>=I<outputwidth>

These  options  control  the  outputwidth,  or  the
screen width FIGlet  assumes  when  formatting  its
output.   FIGlet  uses the outputwidth to determine
when to break lines and how to center  the  output.
Normally,  FIGlet assumes 80 columns so that people
with wide terminals won't annoy the people they  e-mail
FIGlet output to. B<-w> sets the  outputwidth 
to  the  given integer.   An  outputwidth  of 1 is a
special value that tells FIGlet to print each non-
space  character, in its entirety, on a separate line,
no matter how wide it is. Another special outputwidth
is -1, it means to not warp.

=back

=head1 ENVIRONMENT

showfigfonts.pl will make use of these environment variables if present

=over

=item FIGLIB

The default location of fonts.

=back

=head1 FILES

FIGlet home page

 http://st-www.cs.uiuc.edu/users/chai/figlet.html
 http://mov.to/figlet/

FIGlet font files, these can be found at

 http://www.internexus.net/pub/figlet/
 ftp://wuarchive.wustl.edu/graphics/graphics/misc/figlet/
 ftp://ftp.plig.org/pub/figlet/

=head1 SEE ALSO

L<figlet>, L<Text::FIGlet>

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>|<webmaster@pthbb.org>

=cut
