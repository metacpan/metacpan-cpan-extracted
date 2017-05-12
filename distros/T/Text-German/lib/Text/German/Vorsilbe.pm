#                              -*- Mode: Perl -*- 
# Vorsilbe.pm -- 
# Author          : Ulrich Pfeifer
# Created On      : Thu Feb  1 09:10:48 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Apr  3 11:44:42 2005
# Language        : Perl
# Update Count    : 23
# Status          : Unknown, Use with caution!

package Text::German::Vorsilbe;
# require Exporter;
# @ISA = qw(Exporter);
# @EXPORT = qw(%VORSILBE);

{
  local ($_);
  while (<DATA>) {
    chomp;
    ($vorsilbe, $key) = split;
    $VORSILBE{$vorsilbe} = pack 'b*', $key;
  }
  close DATA;
}

sub vorsilben {
  my $word = shift;
  my @result;
  
  for $i (1 .. length($word)) {
    my $vorsilbe = substr($word,0,$i);
    if (defined $VORSILBE{$vorsilbe}) {
      push @result, $vorsilbe;
    }
  }
  @result;
}

sub max_vorsilbe {
  my $word  = shift;
  my $result = undef;
  
  for $i (1 .. length($word)) {
    my $vorsilbe = substr($word,0,$i);
    if (defined $VORSILBE{$vorsilbe}) {
      $result = $vorsilbe
        if !defined($result) || length($vorsilbe) > length($result);
    }
  }
  $result;
}

1;
# un ?

__DATA__
ab	010
an	010
auf	010
aus	010
be	100
bei	010
da	010
dabei	011
dar	010
darauf	011
drauf	012
durch	110
ein	010
em	100
ent	100
er	100
fest	010
fort	010
frei	010
ge	100
her	010
herauf	011
herum	011
herunter	011
hin	010
hinauf	011
hinzu	011
miss	100
mit	010
nach	010
nahe	010
ob	100
recht	010
ueber	110
um	110
umher	011
unter	110
ver	100
vor	010
voraus	011
vorher	011
weg	010
wider	110
wieder	110
zer	100
zu	010
zugrunde	012
zurueck	012
zusammen	012
