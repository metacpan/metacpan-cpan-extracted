package Text::Levenshtein::BV;


use strict;
use warnings;
our $VERSION = '0.02';

##use standard; # experimental from Guacamole

use utf8;

use 5.010001;

#require Exporter;

#BEGIN {
#    $Text::Levenshtein::BV::VERSION     = '0.02';
#    @Text::Levenshtein::BV::ISA         = qw(Exporter);
#    @Text::Levenshtein::BV::EXPORT      = qw();
#    @Text::Levenshtein::BV::EXPORT_OK
#        = qw(SES distance sequences2hunks hunks2sequences sequence2char);
#    %Text::Levenshtein::BV::EXPORT_TAGS = (
#        'all' => [qw(SES distance sequences2hunks hunks2sequences sequence2char)],
#    );
#}

use Data::Dumper;

our $width = int 0.999+log(~0)/log(2);

use integer;
no warnings 'portable'; # for 0xffffffffffffffff

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}




sub SES {
  my ($self, $a, $b) = @_;

  #print STDERR 'SES $a: ',Dumper($a),"\n";
  #print STDERR 'SES $b: ',Dumper($b),"\n";

  my ($amin, $amax, $bmin, $bmax) = (0, $#$a, 0, $#$b);

# NOTE: prefix / suffix optimisation does not work yet
if (1) {
  while ($amin <= $amax and $bmin <= $bmax and $a->[$amin] eq $b->[$bmin]) {
    $amin++;
    $bmin++;
  }
  while ($amin <= $amax and $bmin <= $bmax and $a->[$amax] eq $b->[$bmax]) {
    $amax--;
    $bmax--;
  }
}
  # m = 10, 0..9, 2..7
  #my $m = $amax - $amin +1; # 7 - 2 + 1 = 6
  my $positions;

  #if ($amax < $width ) {
  #if ($m < $width ) {
  if (($amax - $amin) < $width ) {
      #$positions->{$a->[$_]} |= 1 << ($_ % $width) for $amin..$amax;
      $positions->{$a->[$_+$amin]} |= 1 << $_  for 0..($amax-$amin);

      my $VPs = [];
      my $VNs = [];
      my $VP  = ~0;
      my $VN  = 0;

      my ($y,$u,$X,$D0,$HN,$HP);

      # outer loop [HN02] Fig. 7
      #for my $j ($bmin..$bmax) {
      for my $j (0..($bmax - $bmin)) {
          $y = $positions->{$b->[$j + $bmin]} // 0;
          $X = $y | $VN;
          $D0 = (($VP + ($X & $VP)) ^ $VP) | $X;
          $HN = $VP & $D0;
          $HP = $VN | ~($VP|$D0);
          $X  = ($HP << 1) | 1;
          $VN = $X & $D0;
          $VP = ($HN << 1) | ~($X | $D0);
          $VPs->[$j] = $VP;
          $VNs->[$j] = $VN;
      }
      return [
          map { [$_ => $_] } 0 .. ($bmin-1) ,
          #@lcs,
          #backtrace($VPs, $VNs,$VP, $VN, $amin, $amax, $bmin, $bmax),
          _backtrace($VPs, $VNs,$VP, $VN, $amin, $amax, $bmin, $bmax),
          map { [++$amax => $_] } ($bmax+1) .. $#$b
      ];
  }


  # else { #TODO
  elsif (0) {

    $positions->{$a->[$_]}->[$_ / $width] |= 1 << ($_ % $width) for $amin..$amax;

    my $S;
    my $Vs = [];
    my ($y,$u,$carry);
    my $kmax = $amax / $width + 1;

    # outer loop
    for my $j ($bmin..$bmax) {
      $carry = 0;

      for (my $k=0; $k < $kmax; $k++ ) {
        $S = ($j) ? $Vs->[$j-1]->[$k] : ~0;
        $S //= ~0;
        $y = $positions->{$b->[$j]}->[$k] // 0;
        $u = $S & $y;             # [Hyy04]
        $Vs->[$j]->[$k] = $S = ($S + $u + $carry) | ($S & ~$y);
        $carry = (($S & $u) | (($S | $u) & ~($S + $u + $carry))) >> 63; # TODO: $width-1
      }
    }

  }


}


# Hyyrö, Heikki. (2004). A Note on Bit-Parallel Alignment Computation. 79-87.
# Fig. 3
sub _backtrace {
    my ($VPs, $VNs,$VP, $VN, $amin, $amax, $bmin, $bmax) = @_;

if (0) {
    print STDERR '$VPs: ',"\n";
    for my $vp (@$VPs) {
      print STDERR ' ',sprintf('%064b',$vp),"\n";
    }
    print STDERR '$VNs: ',"\n";
    for my $vn (@$VNs) {
      print STDERR ' ',sprintf('%064b',$vn),"\n";
    }
}

    #print STDERR 'backtrace $VPs: ',Dumper($VPs),"\n";
    #print STDERR 'backtrace $VNs: ',Dumper($VNs),"\n";
    #print STDERR 'backtrace $amin: ',$amin,"\n";
    #print STDERR 'backtrace $amax: ',$amax,"\n";
    #print STDERR 'backtrace $bmin: ',$bmin,"\n";
    #print STDERR 'backtrace $bmin: ',$bmin,"\n";

    # recover alignment
    #my $i = $amax;
    my $i = $amax - $amin;
    # my $j = $bmax;
    my $j = $bmax - $bmin;

    my @lcs;

    #print STDERR 'backtrace $amin: ',$amin,' $bmin: ',$bmin,"\n";
    #my $step = 0;

    my $none = '-1';

    #while ($i >= $amin && $j >= $bmin) {
    while ($i >= 0 && $j >= 0) {

        #$step++;

        if ($VPs->[$j] & (1<<$i)) {
        #if (($VP & (1<<$j)) & (1<<$i)) {
            #print STDERR 'step: ',$step,'[$i,-1]',"\n";
            #unshift @lcs,[$i,-1];
            #unshift @lcs,[$i,$none];
            unshift @lcs,[$i+$amin,$none];
            $i--;
        }
        else {
            #if (($j > $bmin) && ($VNs->[$j-1] & (1<<$i))) {
            if (($j > 0) && ($VNs->[$j-1] & (1<<$i))) {
            #if (($j > $bmin) && (($VN & (1<<$j-1)) & (1<<$i))) {
            #if ($VNs->[$j-1] & (1<<$i)) {
            #print STDERR 'step: ',$step,'[-1,$j]',"\n";
                  #unshift @lcs, [-1,$j];
                  #unshift @lcs, [$none,$j];
                  unshift @lcs, [$none,$j+$bmin];
                  $j--;
            }
            else {
            #print STDERR 'step: ',$step,'[$i,$j]',"\n";
                #unshift @lcs, [$i,$j];
                unshift @lcs, [$i+$amin,$j+$bmin];
                $i--;$j--;
            }
            #$i--;$j--;
        }
    }
    #while ($i >= $amin) {
    while ($i >= 0) {
        unshift @lcs,[$i+$amin,$none];
        $i--;
    }
    #while ($j >= $bmin) {
    while ($j >= 0) {
        unshift @lcs,[$none,$j+$bmin];
        $j--;
    }
    #print STDERR 'backtrace @lcs: ',Dumper(\@lcs);
    return @lcs;
}

# [HN02] Fig. 3 -> Fig. 7
sub distance {
  my ($self, $a, $b) = @_;

  my ($amin, $amax, $bmin, $bmax) = (0, $#$a, 0, $#$b);

if (1) {
  while ($amin <= $amax and $bmin <= $bmax and $a->[$amin] eq $b->[$bmin]) {
    $amin++;
    $bmin++;
  }
  while ($amin <= $amax and $bmin <= $bmax and $a->[$amax] eq $b->[$bmax]) {
    $amax--;
    $bmax--;
  }
}

  my $positions;

  if (($amax - $amin) < $width ) {
      #$positions->{$a->[$_]} |= 1 << ($_ % $width) for $amin..$amax;
      $positions->{$a->[$_+$amin]} |= 1 << $_  for 0..($amax-$amin);

      #my $VPs = [];
      #my $VNs = [];
      #my $VP  = ~0;

      my $m = $amax-$amin +1;
      my $diff = $m;
      #print STDERR '$m: ',$m,"\n";
      my $m_mask = 1 << $m-1;
      #print STDERR '$mm: ',sprintf('%064b',$m_mask),"\n";

      my $VP = 0;
      $VP  |= 1 << $_  for 0..$m-1;
      #print STDERR '$VP: ',sprintf('%064b',$VP),"\n";

      my $VN  = 0;

      my ($y,$u,$X,$D0,$HN,$HP);

      # outer loop [HN02] Fig. 7
      #for my $j ($bmin..$bmax) {
      for my $j (0..($bmax - $bmin)) {
          $y = $positions->{$b->[$j + $bmin]} // 0;
          $X = $y | $VN;
          $D0 = (($VP + ($X & $VP)) ^ $VP) | $X;
          $HN = $VP & $D0;
          $HP = $VN | ~($VP|$D0);
          $X  = ($HP << 1) | 1;
          $VN = $X & $D0;
          $VP = ($HN << 1) | ~($X | $D0);
          #$VPs->[$j] = $VP;
          #$VNs->[$j] = $VN;

          if ($HP & $m_mask) { $diff++; }
          if ($HN & $m_mask) { $diff--; }
      }
      return $diff;
  }
}

sub sequences2hunks {
  my ($self, $a, $b) = @_;
  return [ map { [ $a->[$_], $b->[$_] ] } 0..$#$a ];
}

sub hunks2sequences {
  my ($self, $hunks) = @_;

  my $a = [];
  my $b = [];

  for my $hunk (@$hunks) {
    push @$a, $hunk->[0];
    push @$b, $hunk->[1];
  }
  return ($a,$b);
}

sub sequence2char {
  my ($self, $a, $sequence, $gap) = @_;

  $gap = (defined $gap) ? $gap : '_';

  #my $result = [];

  #for my $position (@$sequence) {
  #  push @$result, ($position >= 0) ? $a->[$position] : $gap;
  #}

  return [ map { ($_ >= 0) ? $a->[$_] : $gap } @$sequence ];

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Levenshtein::BV - Bit Vector (BV) implementation of the
                 Levenshtein Algorithm

=begin html

<a href="https://travis-ci.org/wollmers/Text-Levenshtein-BV"><img src="https://travis-ci.org/wollmers/Text-Levenshtein-BV.png" alt="LCS-BV"></a>
<a href='https://coveralls.io/r/wollmers/Text-Levenshtein-BV?branch=master'><img src='https://coveralls.io/repos/wollmers/Text-Levenshtein-BV/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Text-Levenshtein-BV'><img src='http://cpants.cpanauthors.org/dist/Text-Levenshtein-BV.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Text-Levenshtein-BV"><img src="https://badge.fury.io/pl/Text-Levenshtein-BV.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

  use Text::Levenshtein::BV;

  $alg = Text::Levenshtein::BV->new;
  @ses = $alg->SES(\@a,\@b);

=head1 ABSTRACT

Text::Levenshtein::BV implements the Levenshtein using bit vectors and
is faster in most cases than the naive implementation using a match matrix.

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the SES computation.  Use one of these per concurrent
SES() call.

=back

=head2 METHODS

=over 4


=item SES(\@a,\@b)

Finds a Shortest Edit Script (SES), taking two arrayrefs as method
arguments. It returns an array reference of corresponding
indices, which are represented by 2-element array refs.

=item distance(\@a,\@b)

Calculates the edit distance, taking two arrayrefs as method
arguments. It returns an integer.

=item hunks2sequences(\@alignment)

Reformats the alignment returned by SES into an array of two sequences.

=item sequence2char(\@a)

Renders an array of strings into a string.

=item sequences2hunks(\@a,\@b)

Does the revers of method hunks2sequences.

=back

=head2 EXPORT

None by design.

=head1 STABILITY

Until release of version 1.00 the included methods, names of methods and their
interfaces are subject to change.

Beginning with version 1.00 the specification will be stable, i.e. not changed between
major versions.

=head1 REFERENCES

[Hyy03]
Hyyrö, Heikki. (2003).
A Bit-Vector Algorithm for Computing Levenshtein and Damerau Edit Distances.
In Nord. J. Comput. 10. 29-39.

[Hyy04a]
Hyyrö, Heikki. (2004).
A Note on Bit-Parallel Alignment Computation.
In M. Simanek and J. Holub, editors, Stringology, pages 79-87.
Department of Computer Science and Engineering, Faculty of Electrical
Engineering, Czech Technical University, 2004.

[Hyy04b]
Hyyrö, Heikki. (2004).
Bit-parallel LCS-length computation revisited.
In Proc. 15th Australasian Workshop on Combinatorial Algorithms (AWOCA 2004), 2004.

[HN02]
Hyyrö, Heikki and Navarro, Gonzalo.
Faster bit-parallel approximate string matching.
In Proc. 13th Combinatorial Pattern Matching (CPM 2002),
LNCS 2373, pages 203–224, 2002.


=head1 SEE ALSO

L<Text::Levenshtein>

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Text-Levenshtein-BV>

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut@wollmersdorfer.atE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT AND LICENSE

Copyright 2016-2020 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# [Hyy03]
# Hyyrö, Heikki. (2003).
# A Bit-Vector Algorithm for Computing Levenshtein and Damerau Edit Distances.
# In Nord. J. Comput. 10. 29-39.
## books/LCS/hyyrroe_PSC2002_article6.pdf

# [Hyy04a]
# Hyyrö, Heikki. (2004).
# A Note on Bit-Parallel Alignment Computation.
# In M. Simanek and J. Holub, editors, Stringology, pages 79-87.
# Department of Computer Science and Engineering, Faculty of Electrical
# Engineering, Czech Technical University, 2004.
## books/LCS/hyyroe_2004_bit_alignment_PSC2004_article7.pdf

# [Hyy04b]
# Hyyrö, Heikki. (2004).
# Bit-parallel LCS-length computation revisited.
# In Proc. 15th Australasian Workshop on Combinatorial Algorithms (AWOCA 2004), 2004.
## books/LCS/hyrroe_2004_bit_lcs_length.pdf

#### [HN02] Levenshtein Fig. 3
# [HN02]
# Hyyrö, Heikki and Navarro, Gonzalo.
# Faster bit-parallel approximate string matching.
# In Proc. 13th Combinatorial Pattern Matching (CPM 2002),
# LNCS 2373, pages 203–224, 2002.
# books/LCS/hyrroe_navarro_2002_cpm02.2.pdf

