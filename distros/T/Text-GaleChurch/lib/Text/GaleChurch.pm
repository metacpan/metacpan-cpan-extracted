package Text::GaleChurch;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::GaleChurch ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = qw(align);

our @EXPORT = qw(align);

our $VERSION = '1.00';

# Preloaded methods go here.

sub align{
  my ($P1,$P2) = @_;
  if(!ref $P1 || !ref $P2) {
      return;
  }
  chomp(@{$P1});
  chomp(@{$P2});
  my(@A1,@A2);

  # parameters
  my %PRIOR;
  $PRIOR{1}{1} = 0.89;
  $PRIOR{1}{0} = 0.01/2;
  $PRIOR{0}{1} = 0.01/2;
  $PRIOR{2}{1} = 0.089/2;
  $PRIOR{1}{2} = 0.089/2;
#  $PRIOR{2}{2} = 0.011;
  
  # compute length (in characters)
  my (@LEN1,@LEN2);
  $LEN1[0] = 0;
  for(my $i=0;$i<scalar(@{$P1});$i++) {
    my $line = $$P1[$i];
    $line =~ s/[\s\r\n]+//g;
#    print "1: $line\n";
    $LEN1[$i+1] = $LEN1[$i] + length($line);
  }
  $LEN2[0] = 0;
  for(my $i=0;$i<scalar(@{$P2});$i++) {
    my $line = $$P2[$i];
    $line =~ s/[\s\r\n]+//g;
#    print "2: $line\n";
    $LEN2[$i+1] = $LEN2[$i] + length($line);
  }

  # dynamic programming
  my (@COST,@BACK);
  $COST[0][0] = 0;
  for(my $i1=0;$i1<=scalar(@{$P1});$i1++) {
    for(my $i2=0;$i2<=scalar(@{$P2});$i2++) {
      next if $i1 + $i2 == 0;
      $COST[$i1][$i2] = 1e10;
      foreach my $d1 (keys %PRIOR) {
	next if $d1>$i1;
	foreach my $d2 (keys %{$PRIOR{$d1}}) {
	  next if $d2>$i2;
	  my $cost = $COST[$i1-$d1][$i2-$d2] - log($PRIOR{$d1}{$d2}) +  
	    &match($LEN1[$i1]-$LEN1[$i1-$d1], $LEN2[$i2]-$LEN2[$i2-$d2]);
#	  print "($i1->".($i1-$d1).",$i2->".($i2-$d2).") [".($LEN1[$i1]-$LEN1[$i1-$d1]).",".($LEN2[$i2]-$LEN2[$i2-$d2])."] = $COST[$i1-$d1][$i2-$d2] - ".log($PRIOR{$d1}{$d2})." + ".&match($LEN1[$i1]-$LEN1[$i1-$d1], $LEN2[$i2]-$LEN2[$i2-$d2])." = $cost\n";
	  if ($cost < $COST[$i1][$i2]) {
	    $COST[$i1][$i2] = $cost;
	    @{$BACK[$i1][$i2]} = ($i1-$d1,$i2-$d2);
	  }
	}
      }
#      print $COST[$i1][$i2]."($i1-$BACK[$i1][$i2][0],$i2-$BACK[$i1][$i2][1]) ";
    }
#    print "\n";
  }
  
  # back tracking
  my (%NEXT);
  my $i1 = scalar(@{$P1});
  my $i2 = scalar(@{$P2});
  while($i1>0 || $i2>0) {
#    print "back $i1 $i2\n";
    @{$NEXT{$BACK[$i1][$i2][0]}{$BACK[$i1][$i2][1]}} = ($i1,$i2);
    ($i1,$i2) = ($BACK[$i1][$i2][0],$BACK[$i1][$i2][1]);
  }
  while($i1<scalar(@{$P1}) || $i2<scalar(@{$P2})) {
#    print "fwd $i1 $i2\n";
    my $s1 = "";
    my $s2 = "";
    for(my $i=$i1;$i<$NEXT{$i1}{$i2}[0];$i++) {
      $s1 .= " " unless $i == $i1;
      $s1 .= $$P1[$i];
    }
    push @A1,$s1;
    for(my $i=$i2;$i<$NEXT{$i1}{$i2}[1];$i++) {
      $s2 .= " " unless $i == $i2;
      $s2 .= $$P2[$i];
    }
    push @A2,$s2;
    ($i1,$i2) = @{$NEXT{$i1}{$i2}};
  }  
  return (\@A1,\@A2);
}

sub match {
  my ($len1,$len2) = @_;
  my $c = 1;
  my $s2 = 6.8;

  if ($len1==0 && $len2==0) { return 0; }
  my $mean = ($len1 + $len2/$c) / 2;
  my $z = ($c * $len1 - $len2)/sqrt($s2 * $mean);
  if ($z < 0) { $z = -$z; }
  my $pd = 2 * (1 - &pnorm($z));
  if ($pd>0) { return -log($pd); }
  return 25;
}

sub pnorm {
  my ($z) = @_;
  my $t = 1/(1 + 0.2316419 * $z);
  return 1 - 0.3989423 * exp(-$z * $z / 2) *
    ((((1.330274429 * $t 
	- 1.821255978) * $t 
       + 1.781477937) * $t 
      - 0.356563782) * $t
     + 0.319381530) * $t;
}

1;
__END__

=encoding utf8

=head1 NAME

Text::GaleChurch - Perl extension for aligning translated sentences

=head1 SYNOPSIS

    use Text::GaleChurch;

    my @eParagraph = ();
    push @eParagraph, "According to our survey, 1988 sales of mineral water and soft drinks were much higher than in 1987, reflecting the growing popularity of these products.";
    push @eParagraph, "Cola drink manufacturers in particular achieved above-average growth rates.";
    push @eParagraph, "The higher turnover was largely due to an increase in the sales volume.";
    push @eParagraph, "Employment and investment levels also climbed.";
    push @eParagraph, "Following a two-year transitional period, the new Foodstuffs Ordinance for Mineral Water came into effect on April 1, 1988.";
    push @eParagraph, "Specifically, it contains more stringent requirements regarding quality consistency and purity guarantees.";

    my @fParagraph = ();
    push @fParagraph, "Quant aux eaux minérales et aux limonades, elles rencontrent toujours plus d'adeptes.";
    push @fParagraph, "En effet, notre sondage fait ressortir des ventes nettement supérieures à celles de 1987, pour les boissons à base de cola notamment.";
    push @fParagraph, "La progression des chiffres d'affaires résulte en grande partie de l'accroissement du volume des ventes.";
    push @fParagraph, "L'emploi et les investissements ont également augmenté.";  
    push @fParagraph, "La nouvelle ordonnance fédérale sur les denrées alimentaires concernant entre autres les eaux minérales, entrée en vigueur le 1er avril 1988 après une période transitoire de deux ans, exige surtout une plus grande constance dans la qualité et une garantie de la pureté.";

    my $eAlignedRef,$fAlignedRef; 
    ($eAlignedRef,$fAlignedRef) = Text::GaleChurch::align(\@eParagraph,\@fParagraph);

    for(my $i=0;$i<scalar(@{$eAlignedRef});$i++) {
	print "E:",$eAlignedRef->[$i],"\t is aligned to\tF:",$fAlignedRef->[$i],"\n";
    }

=head1 DESCRIPTION

This module aligns the sentences of paragraphs in two languages in a way that the aligned sentences are likely translations of each other. This is useful for applications in machine translation and other applications where sentence-aligned parallel corpora are needed. The algorithm used for this is described in the paper "A Program for Aligning Sentences in Bilingual Corpora" by William A. Gale and Kenneth W. Church (Computational Linguistics, 1994). The input to the align function are two arrays with sentences from the source language and target language text. The arrays need to contain one sentence per array element. To split paragraphs into sentences the module L<Lingua::Sentence> can be used.

=head2 EXPORT

=over

=item split($sourceRef,$targetRef)

Align the bilingual sentences in the arrays referenced by the two arguments. The function returns two array references.

=back

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-GaleChurch>

For other issues, contact the maintainer.

=head1 SEE ALSO

L<Lingua::Sentence>

Google code project: L<http://code.google.com/p/corpus-tools/>

=head1 AUTHOR

Achim Ruopp, E<lt>achimru@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Digital Silk Road

Portions Copyright (C) 2005 by Philip Koehn and Josh Schroeder (used with permission)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
