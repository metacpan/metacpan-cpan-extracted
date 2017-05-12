package Text::FIGlet;
use strict;
use vars qw'$VERSION %RE';
$VERSION = '2.19.3';           #Actual code version: 2.19.1

                               #~50us penalty w/ 2 constant calls for 5.005
use constant PRIVb => 0xF0000; #Map neg chars into Unicode's private area
use constant PRIVe => 0xFFFFD; #0-31 are also available but unused.
use Carp qw(carp croak);
use File::Spec;
use File::Basename 'fileparse';
use Text::FIGlet::Control;
use Text::FIGlet::Font;
use Text::FIGlet::Ransom;


if( $] >= 5.008 ){
    require Encode; #Run-time rather than compile-time, without an eval
    import Encode;
    eval 'sub _utf8_on  {Encode::decode("utf8",shift)}';
#          sub _utf8_off {Encode::_utf8_off(@_)}';
}   #Next block from Encode::compat, but broadened from 5.6.1 to 5.6
elsif ($] >= 5.006 and $] <= 5.007) {
    eval 'sub _utf8_on  { $_[0] = pack("U*", unpack("U0U*", $_[0])) }
          sub Encode::_utf8_off { $_[0] = pack("C*", unpack("C*",   $_[0])) }';
}
else{
    local $^W = 0;
    eval "sub _utf8_on{}; sub Encode::_utf8_off{};";
}


my $thByte = '[\x80-\xBF]';
%RE = (
       #XXX Should perhaps put 1 byte UTF-8 last as . instead, to catch ANSI
       #XXX Alas that catches many other unfortunate things...
       UTFchar => qr/([\x20-\x7F]|[\xC2-\xDF]$thByte|[\xE0-\xEF]$thByte{2}|[\xF0-\xF4]$thByte{3})/,
       bytechar=> qr/(.)/s,
       no      => qr/(-?)((0?)(?:x[\da-fA-F]+|\d+))/,
       );


sub import{
  @_ = qw/UTF8chr UTF8ord UTF8len/ if grep(/:Encode/, @_);

  if( @_ ) {
    no strict 'refs';
    *{scalar(caller).'::'.$_} = $_ for grep/UTF8chr|UTF8ord|UTF8len/, @_;
  }
}


sub new {
  local $_;
  my $proto = shift;
  my %opt = @_;
  my($class, @isect, %count);
  my %class = (-f => 'Font', -C => 'Control');


  if( ref($opt{-f}) =~ /ARRAY|HASH/ ){
      $class = 'Text::FIGlet::Ransom';
  }
  else{
      $count{$_}++ for (keys %opt, keys %class);
      $count{$_} == 2 && push(@isect, $_) for keys %count;
      croak("Cannot new both -C and -f") if scalar @isect > 1;
      $class = 'Text::FIGlet::' . $class{shift(@isect) || '-f'};
  }
  $class->new(@_);
}


sub UTF8chr{
  my $ord = shift || $_;
  my @n;

  #x00-x7f        #1 byte
  if( $ord < 0x80 ){ 
    @n = $ord; }
  #x80-x7ff       #2 bytes
  elsif( $ord < 0x800 ){
    @n  = (0xc0|$ord>>6, 0x80|$ord&0x3F ); }
  #x800-xffff     #3 bytes
  elsif( $ord < 0x10000 ){
    @n  = (0xe0|$ord>>12, 
	   0x80|($ord>>6)&0x3F,
	   0x80|$ord&0x3F ); }
  #x10000-x10ffff #4 bytes
  elsif( $ord<0x20000 ){
    @n = (0xf0|$ord>>18,
	  0x80|($ord>>12)&0x3F,
	  0x80|($ord>>6)&0x3F,
	  0x80|$ord&0x3F); }
  else{
    warn "Out of range for UTF-8: $ord"; }

  return pack "C*", @n;
}


sub UTF8len{
  my $str = shift || $_;
  my $count = () = $str =~ m/$Text::FIGlet::RE{UTFchar}/g;
}


sub UTF8ord{
  my $str = shift || $_;
  my $len = length ($str);

  return ord($str) if $len == 1;
  #This is a FIGlet specific error value
  return 128       if $len > 4 || $len == 0;

  my @n = unpack "C*", $str;
  $str  = (($n[-2] & 0x3F) <<  6) + ($n[-1] & 0x3F);
  $str += (($n[-3] & 0x1F) << 12) if $len ==3;
  $str += (($n[-3] & 0x3F) << 12) if $len ==4;
  $str += (($n[-4] & 0x0F) << 18) if $len == 4;
  return $str;
}


sub _no{
  my($one, $two, $thr, $over) = @_;

  my $val = ($one ? -1 : 1) * ( $thr eq 0 ? oct($two) : $two);

  #+2 is to map -2 to offset zero (-1 is forbidden, modern systems have no -0)
  $val += PRIVe + 2 if $one;
  if( $one && $over && $val < PRIVb ){
    carp("Extended character out of bounds");
    return 0;
  }

  $val;
}


sub _canonical{
  my($defdir, $usrfile, $extre, $backslash) = @_;
  return -e $usrfile ? $usrfile :
      File::Spec->catfile($defdir, $usrfile);

  #Dragons be here, was for pseudo-Windows tests/old Perls?

  #Split things up
  my($file, $path, $ext) = fileparse($usrfile, $extre);

  $path =~ y/\\/\// if $backslash;

  #Handle paths relative to current directory
  my $curdir = File::Spec->catfile(File::Spec->curdir, "");
  $path = $defdir if $path eq $curdir && index($usrfile, $curdir) < 0;


  #return canonicaled path
  return File::Spec->catfile($path, $file.$ext);
}

local $_="Act kind of random and practice less beauty sense --ginoh";

__END__

=pod

=head1 NAME

Text::FIGlet -  provide FIGlet abilities, akin to banner i.e; ASCII art

=head1 SYNOPSIS

 my $font = Text::FIGlet-E<gt>new(-f=>"doh");
 $font->figify(-A=>"Hello World");

=head1 DESCRIPTION

Text::FIGlet reproduces its input using large characters made up of
other characters; usually ASCII, but not necessarily. The output is similar
to that of many banner programs--although it is not oriented sideways--and
reminiscent of the sort of I<signatures> many people like to put at the end
of e-mail and UseNet messages.

Text::FIGlet can print in a variety of fonts, both left-to-right and
right-to-left, with adjacent characters kerned and I<smushed> together in
various ways. FIGlet fonts are stored in separate files, which can be
identified by the suffix I<.flf>. Most FIGlet font files will be stored in
FIGlet's default font directory F</usr/games/lib/figlet>. Support for TOIlet
fonts I<*.tlf>, which are typically in the same location, has also been added.

Text::FIGlet can also use control files, which tell it to map input characters
to others, similar to the Unix tr command. Control files can be identified by
the suffix I<.flc>. Most control files will be stored with the system fonts,
as some fonts use control files to provide access to foreign character sets.

=head1 OPTIONS

C<new>

=over

=item B<-C=E<gt>>F<controlfile>

Creates a control object. L<Text::File::Control> for control object specific
options to new, and how to use the object.

=item B<-f=E<gt>>F<fontfile> | I<\@fonts> | I<\%fonts>

Loads F<fontfile> if specified, and creates a font object.
L<Text::File::Font> for font object specific options to new,
and how to use the object.

With the other forms of B<-f>, a number of fonts can be loaded and blended
into a single font as a L<Text::FIGlet::Ransom> object.

=item B<-d=E<gt>>F<fontdir>

Whence to load files.

Defaults to F</usr/games/lib/figlet>

=back

F<fontfile> and F<controlfile> can be the (absolute or relative) path to the
specified file, or simply the name of a file (with or without an extension)
present in B<-d>.

C<new> with no options will create a font object using the default font.

=head1 EXAMPLES

  perl -MText::FIGlet -e 'print ~~Text::FIGlet->new()->figify(-A=>"Hello World")'

To generate headings for webserver directory listings,
for that warm and fuzzy BBS feeling.

Text based clocks or counters at the bottom of web pages.

Anti-bot obfuscation a la L</AUTHOR>.

=head2 Other Things to Try

A variety of interesting effects can be obtained from dot-matrix-like fonts
such as lean and block by passing them through C<tr>. Hare are some to try:

  tr/|/]/
  tr[ _/][ ()]
  tr[ _/][./\\]
  tr[ _/][ //]
  tr[ _/][/  ]

If you're using FIGlet as some sort of CAPTCHA, or you'd just like a starry
background for your text, you might consider adding noise to the results
of figify e.g;

  #50% chance of replacing a space with an x
  s/( )/rand()>.5?$1:x/eg

  #50% chance of replacing a space with an entry from @F
  @F = qw/. x */; s/( )/$F[scalar@F*2*rand()]||$1/eg;

  #5% chance of substituting a random ASCII character
  #Note that this may yield unpleasant results if UTF is involved
  s/(.)/rand()<.05?chr(32+rand(94)):$1/eg

=head1 ENVIRONMENT

B<Text::FIGlet> will make use of these environment variables if present

=over

=item FIGFONT

The default font to load. If undefined the default is F<standard.flf>.
It should reside in the directory specified by FIGLIB.

=item FIGLIB

The default location of fonts.
If undefined the default is F</usr/games/lib/figlet>

=back

=head1 FILES

FIGlet font files and control files are available at

  http://www.figlet.org/fontdb.cgi
 
=head1 SEE ALSO

Module architecture: L<http://pthbb.org/manual/software/perl/T-F/>

Animated FIGlet: L<Acme::Curses::Marquee::Extensions>

Ancestors: L<figlet(6)> L<http://www.figlet.org>, L<banner(6)>, L<Text::Banner>

=head1 NOTES

If you are using perl 5.005 and wish to try to acces Unicode characters
programatically, or are frustrated by perl 5.6's Unicode support, you may
try importing C<UTF8chr> from this module.

This module also offers C<UTF8ord> and C<UTF8len>, which are used internally,
but may be of general use. To import all three functions, use the B<:Encode>
import tag. C<UTF8len> does not count control characters (0x00-0x19)!

=head1 AUTHOR

Jerrad Pierce

                **                                    />>
     _         //                         _  _  _    / >>>
    (_)         **  ,adPPYba,  >< ><<<  _(_)(_)(_)  /   >>>
    | |        /** a8P_____88   ><<    (_)         >>    >>>
    | |  |~~\  /** 8PP"""""""   ><<    (_)         >>>>>>>>
   _/ |  |__/  /** "8b,   ,aa   ><<    (_)_  _  _  >>>>>>> @cpan.org
  |__/   |     /**  `"Ybbd8"'  ><<<      (_)(_)(_) >>
               //                                  >>>>    /
                                                    >>>>>>/
                                                     >>>>>

=cut
