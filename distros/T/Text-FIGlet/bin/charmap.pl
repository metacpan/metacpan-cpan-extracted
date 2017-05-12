#!/usr/bin/perl -w
use constant PRIVb => 0xF0000;
use constant PRIVe => 0xFFFFD;
use strict;
use vars '$VERSION';
use Text::FIGlet 2.01;
$VERSION = 2.19.1;

my %opts;
$opts{$_} = undef for
  qw(h help -help);
$opts{$_} = "0 but true" for
  qw(d f w);
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
Text::FIGlet::croak("Usage: charmap.pl -help\n") if @ARGV;


my $font = Text::FIGlet->new('_maxLen'=>8,
			     -d=>$opts{d},
			     -m=>'-0',
			     -f=>$opts{f});
my %figify = (
	      -w=>$opts{w});

my $n = int(($opts{w}||80) / $font->{_maxLen});
#XXX
#if($n > 10){
#    $font->{_maxLen} = 7;
#    $n = 10;
#}

#ASCII
{
  print "ASCII: [-\b-E\bE]\n\n";
  for(my$i=33; $i <= 126; $i++){
    printf "%s =% 4i %s", chr($i), $i, ' 'x($font->{_maxLen}-8);
    print "\n", scalar $font->figify(-A=>join('', map(chr($_),
						$i-$n+1..$i)),%figify),
      "\n" if ($i-32)%$n == 0;
  }
  if( my $r = 94 % $n ){
    print "\n", scalar $font->figify(-A=>join('', map(chr($_),
						126-$r..126)),%figify),
      "\n";
  }
}
  
my @buffer;
#German ... have to re-read :-(
{
  $font = Text::FIGlet->new('_maxLen'=>8,
			    -D=>1,
			    -d=>$opts{d},
			    -m=>'-0',
			    -f=>$opts{f},
			    -U=>1);

#XXX  $n = int($opts{w}||80 / $font->{_maxLen});

  print "German: [-\b-D\bD]\n\n";
  @buffer = qw(91 92 93 123 124 125 126);
  
  unshift @buffer, '';
  for(my$i=1; $i < scalar @buffer; $i++){
    printf "%s =%04i %s", chr($buffer[$i]), $buffer[$i], ' 'x($font->{_maxLen}-8);
    if( $i%$n == 0 ){
      print "\n",scalar $font->figify(-A=>join('', map(chr($_),
						 @buffer[$i-$n+1..$i])),%figify), "\n";
      splice(@buffer,1,$n);
      $i-=$n;
    }
  }
  if( scalar @buffer -1 ){
    print "\n", scalar $font->figify(-A=>join('', map(chr($_),
						splice(@buffer,1))),%figify),
      "\n" ;
  }
}
exit unless scalar @{$font->{_font}} > 128;

#Extended chars...
{
  print "Extended Characters\n\n";
  @buffer = ();
  my $U;
  for(my$i=128; $i <= scalar @{$font->{_font}}; $i++){
    last if $i > PRIVb;
    next unless exists($font->{_font}->[$i]) && scalar @{$font->{_font}->[$i]};
    push @buffer, $i;
    $i < 256 ? 
      printf("%s =%04i %s", chr($i), $i, ' 'x($font->{_maxLen}-8)) :
	printf("0x%05X %s", $i, ' 'x($font->{_maxLen}-8));

    if( scalar @buffer == $n ){
      print "\n", scalar $font->figify(-U=> $U = $i > 255 ? 1 : 0,
				-A=>join('', '', map(chr($_), @buffer)),%figify),
	"\n" ;
      @buffer = ();
    }
  }
  for(my$i=PRIVe; $i <= scalar @{$font->{_font}}; $i++){
    next unless exists($font->{_font}->[$i]) && scalar @{$font->{_font}->[$i]};
    push @buffer, $i;
    printf("0x%05X %s", $i, ' 'x($font->{_maxLen}-8));
    if( scalar @buffer == $n ){
      print "\n", scalar $font->figify(-U=>1,
				-A=>join('', '', map(chr($_), @buffer)),%figify),
	"\n" ;
      @buffer = ();
    }
  }
  if( scalar @buffer ){
    print "\n", scalar $font->figify(-U=> $U,
			      -A=>join('', map(chr($_), @buffer)),%figify),
      "\n" ;
  }
}

#Negative chars...
{
  @buffer = ();
  exit if scalar @{$font->{_font}} < PRIVb;
  print "Negative (unmapped) Characters\n\n";
  for(my$i=PRIVe; $i >= PRIVb; $i--){
    next unless exists($font->{_font}->[$i]) && scalar @{$font->{_font}->[$i]};
    push @buffer, $i;
    printf "-0x%04X %s", (-$i+PRIVe+2), ' 'x($font->{_maxLen}-8);
#   print join(':', map { sprintf "0x%06X", $_} @buffer), "\n";#XXX
#   print join(':', map(chr($_), @buffer)), "\n";#XXX
    if( scalar @buffer == $n ){
      print "\n", scalar $font->figify(-U=>1,
				-A=>join('', '', map(chr($_), @buffer)),%figify),
	"\n" ;
      @buffer = ();
    }
  }
  if( scalar @buffer ){
    print "\n", scalar $font->figify(-U=>1,
			      -A=>join('', map(chr($_), @buffer)),%figify),
      "\n" ;
  }
}

__END__
=pod

=head1 NAME

charmap.pl - display a FIGfont  with associated codes

=head1 SYNOPSIS

B<charmap.pl>
[ B<-d=>F<fontdirectory> ]
[ B<-f=>F<fontfile> ]
[ B<-help> ]
[ B<-w=>I<outputwidth> ]

=head1 DESCRIPTION

Charmap doesn't tell you anything you can't find out
by viewing a font in your favorite pager. However,
it does have a few advantages.

=over

=item * You don't have to ignore hardspaces (though you could do this with tr)

=item * It displays more than one FIGchar per FIGline

=back

=head1 OPTIONS

=over

=item B<-d>=F<fontdirectory>

Change the default font  directory.   FIGlet  looks
for  fonts  first in the default directory and then
in the current directory.  If the B<-d> option is  not
specified, FIGlet uses the directory that was specified
when it was  compiled.   To  find  out  which
directory this is, use the B<-I2> option.

=item B<-f>=F<fontfile>

Select the font.  The .flf suffix may be  left  off
of  fontfile,  in  which  case FIGlet automatically
appends it.  FIGlet looks for the file first in the
default  font  directory  and  then  in the current
directory, or, if fontfile  was  given  as  a  full
pathname, in the given directory.  If the B<-f> option
is not specified, FIGlet uses  the  font  that  was
specified  when it was compiled.  To find out which
font this is, use the B<-I3> option.

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
is -1, it means to not wrap.

=back

=head1 ENVIRONMENT

charmap.pl will make use of these environment variables if present

=over

=item FIGFONT

The default font to load.
It should reside in the directory specified by FIGLIB.

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

=head1 CAVEATS

The L<Text::Wrap> in perl 5.6 or earlier operate on bytes,
consequently the display of characters greater than 0x100
end up wrapped across two rows.

=head1 SEE ALSO

L<figlet>, L<Text::FIGlet>

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>|<webmaster@pthbb.org>

=cut
