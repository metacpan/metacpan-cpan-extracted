#                              -*- Mode: Perl -*- 
# Endung.pm -- 
# Author          : Ulrich Pfeifer
# Created On      : Thu Feb  1 09:10:48 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Apr  3 12:16:20 2005
# Language        : Perl
# Update Count    : 45
# Status          : Unknown, Use with caution!

package Text::German::Endung;
# require Exporter;
# @ISA = qw(Exporter);
# @EXPORT = qw(%ENDUNG);

use Text::German::Util;
{
  local ($_);
  
  while (<DATA>) {
    chomp;
    my ($endung, $key) = split;
    my ($a,$b,$c,$d) = split ':', $key; # $c, $d nicht verwedet?
    my $B = Text::German::Util::bit_to_int($b);
    $ENDUNG{$endung} = [$a,$B,$c,$d];
  }
  close DATA;
}

sub endungen {
  my $word  = shift;
  my $class = wordclass($word);
  my @result;
  
  for $i (1 .. length($word)) {
    my $endung = substr($word, length($word)-$i,$i);
    if (defined $ENDUNG{$endung} && defined $ENDUNG{$endung}->[1]
        and ($ENDUNG{$endung}->[1] & $class)) {
      push @result, $endung;
    }
  }
  @result;
}

sub max_endung {
  my $word   = shift;
  my $class  = wordclass($word);
  my $result = undef;
  
  for $i (1 .. length($word)) {
    my $endung = substr($word, length($word)-$i,$i);
    if (defined $ENDUNG{$endung}
        and ($ENDUNG{$endung}->[1] & $class)) {
      $result = $endung
        if !defined($result) || length($endung) > length($result);
      
    }
  }
  $result;
}

sub wort_klasse {
  my $endung = shift;
  
  $ENDUNG{$endung}->[1];
}

sub regel {
  my $endung = shift;
  
  $ENDUNG{$endung}->[0];
}

1;
#       regel
#           wortklassen
#                     nachfolgeregel
__DATA__
e	001:11100:000:000
em	004:00100:000:000
en	002:11101:000:010
end	003:00010:000:011
ende	037:00010:001:047
endem	039:00010:004:049
enden	038:00010:002:048
ender	040:00010:005:050
endere	057:00010:092:067
enderem	059:00010:094:069
enderen	058:00010:093:068
enderer	060:00010:095:070
enderes	061:00010:096:071
endes	041:00010:007:051
endste	077:00010:102:087
endstem	079:00010:104:089
endsten	078:00010:103:088
endster	080:00010:105:090
endstes	081:00010:106:091
ene	032:00001:001:001
enem	034:00001:004:004
enen	033:00001:002:002
ener	035:00001:005:005
enere	052:00001:092:092
enerem	054:00001:094:094
eneren	053:00001:093:093
enerer	055:00001:095:095
eneres	056:00001:096:096
enes	036:00001:007:007
enste	072:00001:102:102
enstem	074:00001:104:104
ensten	073:00001:103:103
enster	075:00001:105:105
enstes	076:00001:106:106
er	005:10100:000:000
ere	092:00100:001:001
erem	094:00100:004:004
eren	093:00100:002:002
erer	095:00100:005:005
eres	096:00100:007:007
ern	006:10000:000:010
es	007:10100:000:012
est	008:00100:000:013
este	097:00100:001:102
estem	099:00100:004:104
esten	098:00100:002:103
ester	100:00100:005:105
estes	101:00100:007:106
et	009:00001:000:014
ete	042:00001:001:017
etem	044:00001:004:019
eten	043:00001:002:018
eter	045:00001:005:020
etere	062:00001:092:022
eterem	064:00001:094:024
eteren	063:00001:093:023
eterer	065:00001:095:025
eteres	066:00001:096:026
etes	046:00001:007:021
etste	082:00001:102:102
etstem	084:00001:104:104
etsten	083:00001:103:103
etster	085:00001:105:105
etstes	086:00001:106:106
n	010:11000:000:000
nd	011:00010:000:000
nde	047:00010:001:001
ndem	049:00010:004:004
nden	048:00010:002:002
nder	050:00010:005:005
ndere	067:00010:092:092
nderem	069:00010:094:094
nderen	068:00010:093:093
nderer	070:00010:095:095
nderes	071:00010:096:096
ndes	051:00010:007:007
ndste	087:00010:102:102
ndstem	089:00010:104:104
ndsten	088:00010:103:103
ndster	090:00010:105:105
ndstes	091:00010:106:106
s	012:10000:000:000
st	013:01000:000:014
ste	102:00100:001:017
stem	104:00100:004:019
sten	103:00100:002:018
ster	105:00100:005:020
stes	106:00100:007:021
t	014:01001:000:000
te	017:01001:001:001
tem	019:00001:004:004
ten	018:01001:002:002
ter	020:00001:005:005
tere	022:00001:092:092
terem	024:00001:094:094
teren	023:00001:093:093
terer	025:00001:095:095
teres	026:00001:096:096
tes	021:00001:007:007
test	015:01000:000:008
teste	027:00001:097:097
testem	029:00001:099:099
testen	028:00001:098:098
tester	030:00001:100:100
testes	031:00001:101:101
tet	016:01000:000:009
