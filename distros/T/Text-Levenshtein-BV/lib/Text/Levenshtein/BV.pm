package Text::Levenshtein::BV;

use strict;
use warnings;
our $VERSION = '0.08';

use utf8;

#use standard;

use 5.010.001;

our $width = int 0.999 + log( ~0 ) / log(2);

use integer;
no warnings 'portable';    # for 0xffffffffffffffff

use Data::Dumper;

our @masks = (
    0x0000000000000000,
    0x0000000000000001, 0x0000000000000003, 0x0000000000000007, 0x000000000000000f,
    0x000000000000001f, 0x000000000000003f, 0x000000000000007f, 0x00000000000000ff,
    0x00000000000001ff, 0x00000000000003ff, 0x00000000000007ff, 0x0000000000000fff,
    0x0000000000001fff, 0x0000000000003fff, 0x0000000000007fff, 0x000000000000ffff,
    0x000000000001ffff, 0x000000000003ffff, 0x000000000007ffff, 0x00000000000fffff,
    0x00000000001fffff, 0x00000000003fffff, 0x00000000007fffff, 0x0000000000ffffff,
    0x0000000001ffffff, 0x0000000003ffffff, 0x0000000007ffffff, 0x000000000fffffff,
    0x000000001fffffff, 0x000000003fffffff, 0x000000007fffffff, 0x00000000ffffffff,
    0x00000001ffffffff, 0x00000003ffffffff, 0x00000007ffffffff, 0x0000000fffffffff,
    0x0000001fffffffff, 0x0000003fffffffff, 0x0000007fffffffff, 0x000000ffffffffff,
    0x000001ffffffffff, 0x000003ffffffffff, 0x000007ffffffffff, 0x00000fffffffffff,
    0x00001fffffffffff, 0x00003fffffffffff, 0x00007fffffffffff, 0x0000ffffffffffff,
    0x0001ffffffffffff, 0x0003ffffffffffff, 0x0007ffffffffffff, 0x000fffffffffffff,
    0x001fffffffffffff, 0x003fffffffffffff, 0x007fffffffffffff, 0x00ffffffffffffff,
    0x01ffffffffffffff, 0x03ffffffffffffff, 0x07ffffffffffffff, 0x0fffffffffffffff,
    0x1fffffffffffffff, 0x3fffffffffffffff, 0x7fffffffffffffff, 0xffffffffffffffff,
);

sub new {
    my $class = shift;

    return bless(
        @_ ? (@_ > 1 ? {@_} : {%{$_[0]}} ) : {}, $class
    );
}

sub SES {
    my ( $self, $a, $b ) = @_;

    if ( !scalar(@{$a}) && !scalar(@{$b}) ) { return [] }

    my ( $amin, $amax, $bmin, $bmax ) = ( 0, $#{$a}, 0, $#{$b} );

    if (1) {
        while ( $amin <= $amax and $bmin <= $bmax and $a->[$amin] eq $b->[$bmin] ) {
            $amin++;
            $bmin++;
        }
        while ( $amin <= $amax and $bmin <= $bmax and $a->[$amax] eq $b->[$bmax] ) {
            $amax--;
            $bmax--;
        }
    }

    if ( ( $amax < $amin ) && ( $bmax < $bmin ) ) {
        return [
            ( map { [ $_, $_ ] } (0 .. $#{$b})  ),
        ];
    }
    elsif ( ( $amax < $amin ) ) {
        return [
            ( map { [ $_,      $_ ] } (0 .. ( $bmin - 1 )) ),
            ( map { [ '-1',    $_ ] } ($bmin .. $bmax)     ),
            ( map { [ ++$amax, $_ ] } ($bmax+1 .. $#{$b})  ),
        ];
    }
    elsif ( ( $bmax < $bmin ) ) {
        return [
            ( map { [ $_, $_      ] } (0 .. ( $amin - 1 )) ),
            ( map { [ $_, '-1'    ] } ($amin .. $amax)     ),
            ( map { [ $_, ++$bmax ] } ($amax+1  .. $#{$a}) ),
        ];
    }

    my $positions;

    if ( ( $amax - $amin ) < $width ) {
        $positions->{ $a->[ $_ + $amin ] } |= 1 << $_ for 0 .. ( $amax - $amin );

        my $VPs = [];
        my $VNs = [];
        my $VP  = ~0;
        my $VN  = 0;

        my ( $PM, $X, $D0, $HN, $HP );

        # outer loop [HN02] Fig. 7
        for my $j ( $bmin .. $bmax ) {
            $PM        = $positions->{ $b->[$j] } // 0;
            $X         = $PM | $VN;
            $D0        = ( ( $VP + ( $X & $VP ) ) ^ $VP ) | $X;
            $HN        = $VP & $D0;
            $HP        = $VN | ~( $VP | $D0 );
            $X         = ( $HP << 1 ) | 1;
            $VN        = $X & $D0;
            $VP        = ( $HN << 1 ) | ~( $X | $D0 );

            $VPs->[$j-$bmin] = $VP;
            $VNs->[$j-$bmin] = $VN;
        }
        return [
            ( map { [ $_, $_      ] } (0 .. ($bmin-1)) ),
            _backtrace( $VPs, $VNs, $amin, $amax, $bmin, $bmax ),
            ( map { [ ++$amax, $_ ] } (($bmax+1) .. $#{$b}) ),
        ];
    }
    else {

        my $m    = $amax - $amin + 1;
        my $diff = $m;

        my $kmax = ($m) / $width;
        $kmax++ if ( ($m) % $width );

        $positions->{ $a->[ $_ + $amin ] }->[ $_ / $width ] |= 1 << ( $_ % $width )
            for 0 .. ( $amax - $amin );

        my @mask;

        $mask[$_] = 0 for ( 0 .. $kmax - 1 );
        $mask[ $kmax - 1 ] = 1 << ( ( $m - 1 ) % $width );

        my @VPs;
        $VPs[ $_ / $width ] |= 1 << ( $_ % $width ) for 0 .. $m - 1;

        my @VNs;
        $VNs[$_] = 0 for ( 0 .. $kmax - 1 );

        my $VPS = [];
        my $VNS = [];

        my ( $PM, $X, $D0, $HN, $HP );

        my $HNcarry;
        my $HPcarry;

        for my $j ( $bmin .. $bmax ) {

            $HNcarry = 0;
            $HPcarry = 1;
            for ( my $k = 0; $k < $kmax; $k++ ) {
                $PM      = $positions->{ $b->[$j] }->[$k] // 0;
                $X       = $PM | $HNcarry | $VNs[$k];
                $D0      = ( ( $VPs[$k] + ( $X & $VPs[$k] ) ) ^ $VPs[$k] ) | $X;
                $HN      = $VPs[$k] & $D0;
                $HP      = $VNs[$k] | ~( $VPs[$k] | $D0 );
                $X       = ( $HP << 1 ) | $HPcarry;
                $HPcarry = $HP >> ( $width - 1 ) & 1;
                $VNs[$k] = ( $X & $D0 );
                $VPs[$k] = ( $HN << 1 ) | ($HNcarry) | ~( $X | $D0 );

                $VPS->[$j-$bmin][$k] = $VPs[$k];
                $VNS->[$j-$bmin][$k] = $VNs[$k];

                $HNcarry = $HN >> ( $width - 1 ) & 1;
            }
        }
        return [
            ( map { [ $_, $_      ] } (0 .. ($bmin-1)) ),
            _backtrace2( $VPS, $VNS, $amin, $amax, $bmin, $bmax, $kmax ),
            ( map { [ ++$amax, $_ ] } (($bmax+1) .. $#{$b}) ),
        ];
    }
}

# Hyyrö, Heikki. (2004). A Note on Bit-Parallel Alignment Computation. 79-87.
# Fig. 3
sub _backtrace {
    my ( $VPs, $VNs, $amin, $amax, $bmin, $bmax ) = @_;

    # recover alignment
    my $i = $amax;
    my $j = $bmax;

    my @ses = ();

    my $none = '-1';

    while ( $i >= $amin && $j >= $bmin ) {

        if ( $VPs->[$j-$bmin] & ( 1 << ($i-$amin) ) ) {
            unshift @ses, [ $i, $none ];
            $i--;
        }
        else {
            if ( ( $j > $bmin  ) && ( $VNs->[ $j - $bmin - 1 ]
                & ( 1 << ($i-$amin) ) ) ) {
                unshift @ses, [ $none, $j ];
                $j--;
            }
            else {
                unshift @ses, [ $i, $j ];
                $i--;
                $j--;
            }
        }
    }

    while ( $i >= $amin ) {
        unshift @ses, [ $i + $amin, $none ];
        $i--;
    }
    while ( $j >= $bmin ) {
        unshift @ses, [ $none, $j ];
        $j--;
    }

    return @ses;
}

sub _backtrace2 {
    my ( $VPs, $VNs, $amin, $amax, $bmin, $bmax, $kmax ) = @_;

    # recover alignment
    my $i = $amax;
    my $j = $bmax;

    my @ses = ();

    my $none = '-1';

    while ( $i >= $amin && $j >= $bmin ) {
        my $k = ($i - $amin) / $width;

        if ( $VPs->[$j-$bmin]->[$k] & ( 1 << ( ($i - $amin) % $width ) ) ) {
            unshift @ses, [ $i, $none ];
            $i--;
        }
        else {
            if ( ( $j > $bmin ) && ( $VNs->[ $j - $bmin - 1 ]->[$k]
                & ( 1 << ( ($i - $amin) % $width ) ) ) ) {
                unshift @ses, [ $none, $j ];
                $j--;
            }
            else {
                unshift @ses, [ $i, $j ];
                $i--;
                $j--;
            }
        }
    }
    while ( $i >= $amin ) {
        unshift @ses, [ $i, $none ];
        $i--;
    }
    while ( $j >= $bmin ) {
        unshift @ses, [ $none, $j ];
        $j--;
    }

    return @ses;
}

# [HN02] Fig. 3 -> Fig. 7
sub distance {
    my ( $self, $a, $b ) = @_;

    my ( $amin, $amax, $bmin, $bmax ) = ( 0, $#{$a}, 0, $#{$b} );

    if (1) {
        while ( $amin <= $amax and $bmin <= $bmax and $a->[$amin] eq $b->[$bmin] ) {
            $amin++;
            $bmin++;
        }
        while ( $amin <= $amax and $bmin <= $bmax and $a->[$amax] eq $b->[$bmax] ) {
            $amax--;
            $bmax--;
        }
    }

    # if one of the sequences is a complete subset of the other,
    # return difference of lengths.
    if ( ( $amax < $amin ) || ( $bmax < $bmin ) ) { return abs( @{$a} - @{$b} ); }

    my $positions;

    if ( ( $amax - $amin ) < $width ) {

        $positions->{ $a->[ $_ + $amin ] } |= 1 << $_ for 0 .. ( $amax - $amin );

        my $m    = $amax - $amin + 1;
        my $diff = $m;

        my $m_mask = 1 << $m - 1;

        my $VP = 0;

        $VP = $masks[$m];    # mask from cached table

        my $VN = 0;

        my ( $PM, $X, $D0, $HN, $HP );

        # outer loop [HN02] Fig. 7
        # 22 instructions
        for my $j ( $bmin .. $bmax ) {
            $PM = $positions->{ $b->[$j] } // 0;
            $X  = $PM | $VN;
            $D0 = ( ( $VP + ( $X & $VP ) ) ^ $VP ) | $X;
            $HN = $VP & $D0;
            $HP = $VN | ~( $VP | $D0 );
            $X  = ( $HP << 1 ) | 1;
            $VN = $X & $D0;
            $VP = ( $HN << 1 ) | ~( $X | $D0 );

            if    ( $HP & $m_mask ) { $diff++; }
            elsif ( $HN & $m_mask ) { $diff--; }

        }
        return $diff;
    }
    else {

        my $m    = $amax - $amin + 1;
        my $diff = $m;

        my $kmax = ($m) / $width;
        $kmax++ if ( ($m) % $width );

        # m * 3
        $positions->{ $a->[ $_ + $amin ] }->[ $_ / $width ] |= 1 << ( $_ % $width )
            for 0 .. ( $amax - $amin );

        my @mask;

        $mask[$_] = 0 for ( 0 .. $kmax - 1 );
        $mask[ $kmax - 1 ] = 1 << ( ( $m - 1 ) % $width );

        my @VPs;
        $VPs[ $_ / $width ] |= 1 << ( $_ % $width ) for 0 .. $m - 1;

        my @VNs;
        $VNs[$_] = 0 for ( 0 .. $kmax - 1 );

        my ( $PM, $X, $D0, $HN, $HP );

        my $HNcarry;
        my $HPcarry;

        for my $j ( $bmin .. $bmax ) {

            $HNcarry = 0;
            $HPcarry = 1;
            for ( my $k = 0; $k < $kmax; $k++ ) {
                $PM      = $positions->{ $b->[$j] }->[$k] // 0;
                $X       = $PM | $HNcarry | $VNs[$k];
                $D0      = ( ( $VPs[$k] + ( $X & $VPs[$k] ) ) ^ $VPs[$k] ) | $X;
                $HN      = $VPs[$k] & $D0;
                $HP      = $VNs[$k] | ~( $VPs[$k] | $D0 );
                $X       = ( $HP << 1 ) | $HPcarry;
                $HPcarry = $HP >> ( $width - 1 ) & 1;
                $VNs[$k] = ( $X & $D0 );
                $VPs[$k] = ( $HN << 1 ) | ($HNcarry) | ~( $X | $D0 );
                $HNcarry = $HN >> ( $width - 1 ) & 1;

                if    ( $HP & $mask[$k] ) { $diff++; }
                elsif ( $HN & $mask[$k] ) { $diff--; }
            }
        }
        return $diff;
    }
}

sub sequences2hunks {
    my ( $self, $a, $b ) = @_;

    return [ map { [ $a->[$_], $b->[$_] ] } 0 .. $#{$a} ];
}

sub hunks2sequences {
    my ( $self, $hunks ) = @_;

    my $a = [];
    my $b = [];

    for my $hunk (@{$hunks}) {
        push @{$a}, $hunk->[0];
        push @{$b}, $hunk->[1];
    }
    return ( $a, $b );
}

sub sequence2char {
    my ( $self, $a, $sequence, $gap ) = @_;

    $gap = ( defined $gap ) ? $gap : '_';

    return [ map { ( $_ >= 0 ) ? $a->[$_] : $gap } @{$sequence} ];
}

sub hunks2distance {
    my ( $self, $a, $b, $hunks ) = @_;

    my $distance = 0;

    if ( scalar(@{$hunks} ) == 0) { return 0; }

    for my $hunk ( @{$hunks} ) {
        if ( scalar(@{$hunk} ) == 0) { next; }
        elsif    ( ( $hunk->[0] < 0 ) || ( $hunk->[1] < 0 ) ) { $distance++ }
        elsif ( $a->[ $hunk->[0] ] ne $b->[ $hunk->[1] ] ) { $distance++ }
    }
    return $distance;
}

sub hunks2char {
    my ( $self, $a, $b, $hunks ) = @_;

    my $chars = [];

    for my $hunk (@{$hunks}) {
        my $char1 = ( $hunk->[0] >= 0 ) ? $a->[ $hunk->[0] ] : '_';
        my $char2 = ( $hunk->[1] >= 0 ) ? $a->[ $hunk->[1] ] : '_';

        push @{$chars}, [ $char1, $char2 ];
    }
    return $chars;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Levenshtein::BV - Bit Vector (BV) implementation of the
                 Levenshtein Algorithm

=begin html

<a href='http://cpants.cpanauthors.org/dist/Text-Levenshtein-BV'><img src='http://cpants.cpanauthors.org/dist/Text-Levenshtein-BV.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Text-Levenshtein-BV"><img src="https://badge.fury.io/pl/Text-Levenshtein-BV.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

  use Text::Levenshtein::BV;

  my $lev = Text::Levenshtein::BV->new;
  my $ses = $lev->SES(\@a,\@b);

=head1 ABSTRACT

Text::Levenshtein::BV implements the Levenshtein algorithm using bit vectors and
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

Does the reverse of method hunks2sequences.

=item hunks2char(\@a,\@b,\@alignment)

Returns hunks of aligned characters.

=item hunks2distance(\@a,\@b,\@alignment)

Calculates the distance from alignment.

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

[Myers99]
Myers, Gene.
A fast bit-vector algorithm for approximate string matching based on dynamic progamming.
Journal of the ACM, 46(3):395–415, 1999.


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

Copyright 2016-2022 by Helmut Wollmersdorfer

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

#### [Myers99]
# Myers, Gene.
# A fast bit-vector algorithm for approximate string matching based on dynamic progamming.
# Journal of the ACM, 46(3):395–415, 1999.


