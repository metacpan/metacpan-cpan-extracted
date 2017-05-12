package Text::Diff3;
use 5.006;
use strict;
use warnings;

use version; our $VERSION = '0.10';

our @EXPORT_OK = qw(diff3 merge diff);

# Two way diff procedure for function style diff3.
# Change this as your like.
our $DIFF_PROC = \&_diff_heckel;

sub diff { return $DIFF_PROC->(@_) }

sub import {
    my($class, @arg) = @_;
    my $pkg = caller;
    my %opt = map { $_ => 1 } @arg;
    my %export;
    if (exists $opt{':factory'}) {
        # compatibility for old version's component style interface.
        warn "Text::Diff3 ':factory' is deprecated.\n";
        require Text::Diff3::Factory;
        return;
    }
    if (exists $opt{':all'}) {
        %export = map { $_ => 1 } @EXPORT_OK;
    }
    else {
        for my $func (@EXPORT_OK) {
            if (exists $opt{$func}) {
                $export{$func} = 1;
            }
        }
    }
    for my $func (keys %export) {
        no strict 'refs';
        *{"${pkg}::${func}"} = \&{"${class}::${func}"};
    }
    return;
}

# the three-way diff based on the GNU diff3.c by R. Smith.
sub diff3 {
    my($text0, $text2, $text1) = @_;
    # diff result => [[$cmd, $loA, $hiA, $loB, $hiB], ...]
    my @diff2 = (
        diff($text2, $text0),
        diff($text2, $text1),
    );
    my $diff3 = [];
    my $range3 = [undef,  0, 0,  0, 0,  0, 0];
    while (@{$diff2[0]} || @{$diff2[1]}) {
        # find a continual range in text2 $lo2..$hi2
        # changed by text0 or by text1.
        #
        #  diff2[0]     222    222222222
        #     text2  ...L!!!!!!!!!!!!!!!!!!!!H...
        #  diff2[1]       222222   22  2222222
        my @range2 = ([], []);
        my $i =
              ! @{$diff2[0]} ? 1
            : ! @{$diff2[1]} ? 0
            : $diff2[0][0][1] <= $diff2[1][0][1] ? 0
            : 1;
        my $j = $i;
        my $k = $i ^ 1;
        my $hi = $diff2[$j][0][2];
        push @{$range2[$j]}, shift @{$diff2[$j]};
        while (@{$diff2[$k]} && $diff2[$k][0][1] <= $hi + 1) {
            my $hi_k = $diff2[$k][0][2];
            push @{$range2[$k]}, shift @{$diff2[$k]};
            if ($hi < $hi_k) {
                $hi = $hi_k;
                $j = $k;
                $k = $k ^ 1;
            }
        }
        my $lo2 = $range2[$i][ 0][1];
        my $hi2 = $range2[$j][-1][2];
        # take the corresponding ranges in text0 $lo0..$hi0
        # and in text1 $lo1..$hi1.
        #
        #     text0  ..L!!!!!!!!!!!!!!!!!!!!!!!!!!!!H...
        #  diff2[0]     222    222222222
        #     text2  ...00!1111!000!!00!111111...
        #  diff2[1]       222222   22  2222222
        #     text1       ...L!!!!!!!!!!!!!!!!H...
        my($lo0, $hi0);
        if (@{$range2[0]}) {
            $lo0 = $range2[0][ 0][3] - $range2[0][ 0][1] + $lo2;
            $hi0 = $range2[0][-1][4] - $range2[0][-1][2] + $hi2;
        }
        else {
            $lo0 = $range3->[2] - $range3->[6] + $lo2;
            $hi0 = $range3->[2] - $range3->[6] + $hi2;
        }
        my($lo1, $hi1);
        if (@{$range2[1]}) {
            $lo1 = $range2[1][ 0][3] - $range2[1][ 0][1] + $lo2;
            $hi1 = $range2[1][-1][4] - $range2[1][-1][2] + $hi2;
        }
        else {
            $lo1 = $range3->[4] - $range3->[6] + $lo2;
            $hi1 = $range3->[4] - $range3->[6] + $hi2;
        }
        $range3 = [undef,  $lo0, $hi0,  $lo1, $hi1,  $lo2, $hi2];
        # detect type of changes.
        if (! @{$range2[0]}) {
            $range3->[0] = '1';
        }
        elsif (! @{$range2[1]}) {
            $range3->[0] = '0';
        }
        elsif ($hi0 - $lo0 != $hi1 - $lo1) {
            $range3->[0] = 'A';
        }
        else {
            $range3->[0] = '2';
            for my $d (0 .. $hi0 - $lo0) {
                my($i0, $i1) = ($lo0 + $d - 1, $lo1 + $d - 1);
                my $ok0 = 0 <= $i0 && $i0 <= $#{$text0};
                my $ok1 = 0 <= $i1 && $i1 <= $#{$text1};
                if ($ok0 ^ $ok1 || ($ok0 && $text0->[$i0] ne $text1->[$i1])) {
                    $range3->[0] = 'A';
                    last;
                }
            }
        }
        push @{$diff3}, $range3;
    }
    return $diff3;
}

sub merge {
    my($mytext, $origtext, $yourtext) = @_;
    my $text3 = [$mytext, $yourtext, $origtext];
    my $res = {conflict => 0, body => []};
    my $diff3 = diff3(@{$text3}[0, 2, 1]);
    my $i2 = 1;
    for my $r3 (@{$diff3}) {
        for my $lineno ($i2 .. $r3->[5] - 1) {
            push @{$res->{body}}, $text3->[2][$lineno - 1];
        }
        if ($r3->[0] eq '0') {
            for my $lineno ($r3->[1] .. $r3->[2]) {
                push @{$res->{body}}, $text3->[0][$lineno - 1];
            }
        }
        elsif ($r3->[0] ne 'A') {
            for my $lineno ($r3->[3] .. $r3->[4]) {
                push @{$res->{body}}, $text3->[1][$lineno - 1];
            }
        }
        else {
            _conflict_range($text3, $r3, $res);
        }
        $i2 = $r3->[6] + 1;
    }
    for my $lineno ($i2 .. $#{$text3->[2]} + 1) {
        push @{$res->{body}}, $text3->[2][$lineno - 1];
    }
    return $res;
}

sub _conflict_range {
    my($text3, $r3, $res) = @_;
    my $text2 = [
        [map { $text3->[1][$_ - 1] } $r3->[3] .. $r3->[4]], # yourtext
        [map { $text3->[0][$_ - 1] } $r3->[1] .. $r3->[2]], # mytext
    ];
    my $diff = diff(@{$text2});
    if (_assoc_range($diff, 'c') && $r3->[5] <= $r3->[6]) {
        $res->{conflict}++;
        push @{$res->{body}}, '<<<<<<<';
        for my $lineno ($r3->[1] .. $r3->[2]) {
            push @{$res->{body}}, $text3->[0][$lineno - 1];
        }
        push @{$res->{body}}, '|||||||';
        for my $lineno ($r3->[5] .. $r3->[6]) {
            push @{$res->{body}}, $text3->[2][$lineno - 1];
        }
        push @{$res->{body}}, '=======';
        for my $lineno ($r3->[3] .. $r3->[4]) {
            push @{$res->{body}}, $text3->[1][$lineno - 1];
        }
        push @{$res->{body}}, '>>>>>>>';
        return;
    }
    my $ia = 1;
    for my $r2 (@{$diff}) {
        for my $lineno ($ia .. $r2->[1] - 1) {
            push @{$res->{body}}, $text2->[0][$lineno - 1];
        }
        if ($r2->[0] eq 'c') {
            $res->{conflict}++;
            push @{$res->{body}}, '<<<<<<<';
            for my $lineno ($r2->[3] .. $r2->[4]) {
                push @{$res->{body}}, $text2->[1][$lineno - 1];
            }
            push @{$res->{body}}, '=======';
            for my $lineno ($r2->[1] .. $r2->[2]) {
                push @{$res->{body}}, $text2->[0][$lineno - 1];
            }
            push @{$res->{body}}, '>>>>>>>';
        }
        elsif ($r2->[0] eq 'a') {
            for my $lineno ($r2->[3] .. $r2->[4]) {
                push @{$res->{body}}, $text2->[1][$lineno - 1];
            }
        }
        $ia = $r2->[2] + 1;
    }
    for my $lineno ($ia .. $#{$text2->[0]} + 1) {
        push @{$res->{body}}, $text2->[0][$lineno - 1];
    }
    return;
}

sub _assoc_range {
    my($diff, $type) = @_;
    for my $r (@{$diff}) {
        return $r if $r->[0] eq $type;
    }
    return;
}

# the two-way diff based on the algorithm by P. Heckel.
sub _diff_heckel {
    my($text_a, $text_b) = @_;
    my $diff = [];
    my @uniq = ([$#{$text_a} + 1, $#{$text_b} + 1]);
    my(%freq, %ap, %bp);
    for my $i (0 .. $#{$text_a}) {
        my $s = $text_a->[$i];
        $freq{$s} += 2;
        $ap{$s} = $i;
    }
    for my $i (0 .. $#{$text_b}) {
        my $s = $text_b->[$i];
        $freq{$s} += 3;
        $bp{$s} = $i;
    }
    while (my($s, $x) = each %freq) {
        next if $x != 5;
        push @uniq, [$ap{$s}, $bp{$s}];
    }
    %freq = (); %ap = (); %bp = ();
    @uniq = sort { $a->[0] <=> $b->[0] } @uniq;
    my($a1, $b1) = (0, 0);
    while ($a1 <= $#{$text_a} && $b1 <= $#{$text_b}) {
        last if $text_a->[$a1] ne $text_b->[$b1];
        ++$a1;
        ++$b1;
    }
    for (@uniq) {
        my($a_uniq, $b_uniq) = @{$_};
        next if $a_uniq < $a1 || $b_uniq < $b1;
        my($a0, $b0) = ($a1, $b1);
        ($a1, $b1) = ($a_uniq - 1, $b_uniq - 1);
        while ($a0 <= $a1 && $b0 <= $b1) {
            last if $text_a->[$a1] ne $text_b->[$b1];
            --$a1;
            --$b1;
        }
        if ($a0 <= $a1 && $b0 <= $b1) {
            push @{$diff}, ['c', $a0 + 1, $a1 + 1, $b0 + 1, $b1 + 1];
        }
        elsif ($a0 <= $a1) {
            push @{$diff}, ['d', $a0 + 1, $a1 + 1, $b0 + 1, $b0];
        }
        elsif ($b0 <= $b1) {
            push @{$diff}, ['a', $a0 + 1, $a0, $b0 + 1, $b1 + 1];
        }
        ($a1, $b1) = ($a_uniq + 1, $b_uniq + 1);
        while ($a1 <= $#{$text_a} && $b1 <= $#{$text_b}) {
            last if $text_a->[$a1] ne $text_b->[$b1];
            ++$a1;
            ++$b1;
        }
    }
    return $diff;
}

1;

__END__

=pod

=head1 NAME

Text::Diff3 - three way text comparison and merging.

=head1 VERSION

0.10

=head1 SYNOPSIS

    # in default, this module does not export any symbol.
    use Text::Diff3;
    use Text::Diff3 qw(:all);
    use Text::Diff3 qw(diff3 merge diff);
    
    my $mytext   = [map {chomp; $_} <$input0>]);
    my $original = [map {chomp; $_} <$input1>]);
    my $yourtext = [map {chomp; $_} <$input2>]);
    
    my $diff3 = diff3($mytext, $origial, $yourtext);
    for my $r (@{$diff3}) {
        printf "%s %d,%d %d,%d %d,%d\n", @{$r};
        # lineno start from not zero but ONE!
        for my $lineno ($r->[1] .. $r->[2]) {
            print $mytext->[$lineno - 1], "\n";
        }
        for my $lineno ($r->[3] .. $r->[4]) {
            print $yourtext->[$lineno - 1], "\n";
        }
        for my $lineno ($r->[5] .. $r->[6]) {
            print $original->[$lineno - 1], "\n";
        }
    }
    
    my $merge = merge($mytext, $origial, $yourtext);
    if ($merge->{conflict}) {
        print STDERR "conflict\n";
    }
    for my $line (@{$merge->{body}}) {
        print "$line\n";
    }
    
    my $diff = diff($original, $mytext);
    for my $r (@{$diff}) {
        printf "%s%s%s\n",
            $r->[1] >= $r->[2] ? $r->[1] : "$r->[1],$r->[2]",
            $r->[0],
            $r->[3] >= $r->[4] ? $r->[3] : "$r->[3],$r->[4]";
        if ($r->[0] ne 'a') { # delete or change
            for my $lineno ($r->[1] .. $r->[2]) {
                print q{-}, $original->[$lineno - 1], "\n";
            }
        }
        if ($r->[0] ne 'd') { # append or change
            for my $lineno ($r->[3] .. $r->[4]) {
                print q{+}, $mytext->[$lineno - 1], "\n";
            }
        }
    }
    
    # component style (deprecated. no longer maintenance)
    use Text::Diff3 qw(:factory);

=head1 DESCRIPTION

This module provides you to compute difference sets between two
or three texts ported from GNU diff3.c written by R. Smith.

For users convenience, Text::Diff3 includes small diff procedure
based on the P. Heckel's algorithm. On the other hands,
many other systems use the popular Least Common Sequence (LCS) algorithm.
The merits for each algorithm are case by case. In author's experience,
two algorithms generate almost same results for small local changes
in the text. In some cases, such as moving blocks of lines,
it happened quite differences in results.

=head1 FUNCTIONS

=over

=item C< diff3(\@mytext, \@origial, \@yourtext) >

Calcurate three-way differences. This returns difference sets
as an array reference.

For example,

    my $diff3 = Text::Diff3::Lite::diff3(
        [qw(A A b c     f g h i j K l m n O p Q R s)],
        [qw(a   b c d e f g h i j k l m n o p q r s)],
        [qw(a   b c d   f       j K l M n o p 1 2 s t u)],
    );

returns a following reference:

    [
        [0,    1, 2,  1, 1,  1, 1],
        ['A',  5, 4,  4, 4,  4, 5],
        [1,    6, 8,  6, 5,  7, 9],
        [2,   10,10,  7, 7, 11,11],
        [1,   12,12,  9, 9, 13,13],
        [0,   14,14, 11,11, 15,15],
        ['A', 16,17, 13,14, 17,18],
        [1,   19,18, 16,17, 20,19],
    ]

where

    case $diff3->[$i][0]
    when 0: changes by my text.
    when 1: changes by your text.
    when 2: changes from original text.
    when 'A': conflict!
    end

=item C< merge(\@mytext, \@origial, \@yourtext) >

Merge changes by my or your texts on the original text.
This returns an hash reference.

For example,

    my $merge = Text::Diff3::Lite::merge(
        [qw(A A b c     f g h i j K l m n O p Q R s)],
        [qw(a   b c d e f g h i j k l m n o p q r s)],
        [qw(a   b c d   f       j K l M n o p 1 2 s t u)],
    );

returns a following reference:

    {
        'conflict' => 1,
        'body' => [
            qw(A A b c f j K l M n O p),
            '<<<<<<<',
            'Q',
            'R',
            '|||||||',
            'q',
            'r',
            '=======',
            '1',
            '2',
            '>>>>>>>',
            qw(s t u),
        ],
    }

=item C< diff(\@original, \@mytext) >

Calcurate two-way differences. This returns difference sets
as an array reference.

For example,

    my $diff = Text::Diff3::Lite::diff(
        [qw(a b c     f g h i j)],
        [qw(a B c d e f       j)],
    );

returns a following reference:

    [
        [qw(c 2 2 2 2)],
        [qw(a 4 3 4 5)],
        [qw(d 5 7 7 6)],
    ]

where

    case $diff->[$i][0]
    when 'a': append.
    when 'c': change.
    when 'd': delete.
    end

=back

=head1 VARIABLE

=over

=item C<$DIFF_PROC>

This holds a two-way diff procedure used in function style diff3.
Please change this as your like.

    $Text::Diff3::DIFF_PROC = sub {
        my($origtext, $mytext) = @_;
        # origtext => ['line1', 'line2', 'line3', ...];
        # mytext => ['line1', 'line2', 'line3', ...];
        
        # calcurate two way differences.
        
        # for example:
        my $diff_list = [
            [qw(c 2 2 2 2)],
            [qw(a 4 3 4 5)],
            [qw(d 5 7 7 6)],
        ];
        # where line numbers start from 1.
        return $diff_list;
    };

=back

=head1 SEE ALSO

GNU/diffutils/2.7/diff3.c

   Three way file comparison program (diff3) for Project GNU.
   Copyright (C) 1988, 1989, 1992, 1993, 1994 Free Software Foundation, Inc.
   Written by Randy Smith

P. Heckel. ``A technique for isolating differences between files.''
Communications of the ACM, Vol. 21, No. 4, page 264, April 1978.

=head1 AUTHOR

MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 MIZUTANI Tociyuki

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

=cut

