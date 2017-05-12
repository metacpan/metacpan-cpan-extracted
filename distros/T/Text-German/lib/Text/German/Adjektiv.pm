#                              -*- Mode: Perl -*- 
# Adjektiv.pm -- 
# Author          : Ulrich Pfeifer
# Created On      : Thu Feb  1 09:10:48 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Apr  3 11:42:22 2005
# Language        : Perl
# Update Count    : 22
# Status          : Unknown, Use with caution!

package Text::German::Adjektiv;
use Text::German::Util;

{
  local ($_);
  while (<DATA>) {
    chomp;
    ($adjektiv, $key) = split;
    $ADJEKTIV{$adjektiv} = [split ':', $key];
  }
  close DATA;
}

sub reduce {
  my($v,$s,$e) = @_;
  
  
  #return undef unless $v.$s.$e =~ /$UMLAUTR/o;
  while (1) {                   # algorithmus unklar
    if (defined $ADJECTIV{$s}) {
      return ($v, $ADJECTIV{$s}->[0], $e);
    }
    $s .= substr($e,0,1);
    last unless $e;
    $e  = substr($e,1);
  }
  return undef;
}

1;
__DATA__
ält	alt:1
ärg	arg:1
ärm	arm:1
alt	alt:1
arg	arg:1
arm	arm:1
bäng	bang:0
bang	bang:0
bläss	blaß:0
blaß	blaß:0
dümm	dumm:1
dumm	dumm:1
frömm	fromm:0
fromm	fromm:0
gesünd	gesund:0
gesund	gesund:0
glätt	glatt:0
glatt	glatt:0
größ	groß:1
gröb	grob:1
groß	groß:1
grob	grob:1
härt	hart:1
höch	hoch:1
höh	hoch:1
hart	hart:1
hoch	hoch:1
jüng	jung:1
jung	jung:1
kält	kalt:1
kärg	karg:0
kürz	kurz:1
kalt	kalt:1
karg	karg:0
klüg	klug:1
klug	klug:1
kränk	krank:1
krümm	krumm:0
krank	krank:1
krumm	krumm:0
kurz	kurz:1
läng	lang:1
lang	lang:1
näch	nah:1
näh	nah:1
näss	naß:0
naß	naß:0
nah	nah:1
röt	rot:0
rot	rot:0
schärf	scharf:1
scharf	scharf:1
schmäl	schmal:0
schmal	schmal:0
schwäch	schwach:1
schwärz	schwarz:1
schwach	schwach:1
schwarz	schwarz:1
stärk	stark:1
stark	stark:1
wärm	warm:1
warm	warm:1
