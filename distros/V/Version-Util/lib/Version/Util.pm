package Version::Util;

our $DATE = '2018-01-09'; # DATE
our $VERSION = '0.730'; # VERSION

use 5.010001;
use strict;
use version 0.77;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       cmp_version
                       version_eq version_ne
                       version_lt version_le version_gt version_ge
                       version_between version_in

                       add_version subtract_version
               );

sub cmp_version {
    version->parse($_[0]) <=> version->parse($_[1]);
}

sub version_eq {
    version->parse($_[0]) == version->parse($_[1]);
}

sub version_ne {
    version->parse($_[0]) != version->parse($_[1]);
}

sub version_lt {
    version->parse($_[0]) <  version->parse($_[1]);
}

sub version_le {
    version->parse($_[0]) <= version->parse($_[1]);
}

sub version_gt {
    version->parse($_[0]) >  version->parse($_[1]);
}

sub version_ge {
    version->parse($_[0]) >= version->parse($_[1]);
}

sub version_between {
    my $v = version->parse(shift);
    while (@_) {
        my $v1 = shift;
        my $v2 = shift;
        return 1 if $v >= version->parse($v1) && $v <= version->parse($v2);
    }
    0;
}

sub version_in {
    my $v = version->parse(shift);
    for (@_) {
        return 1 if $v == version->parse($_);
    }
    0;
}

sub _max2 {
    $_[0] > $_[1] ? $_[0] : $_[1];
}

sub _add_or_subtract_version {
    my ($which, $v, $inc) = @_;

    state $re = qr/\Av?(\d{1,15})(?:\.(\d{1,3}))?(?:\.(\d{1,3}))?\z/;

    $v =~ $re or die "Invalid version '$v', must match $re";
    my ($v_maj, $v_min, $v_pl) = ($1, $2, $3);
    $v_min //= '';
    $v_pl //= '';

    $inc =~ $re or die "Invalid increment '$inc', must match $re";
    my ($inc_maj, $inc_min, $inc_pl) = ($1, $2, $3);
    $inc_min //= '';
    $inc_pl //= '';

    my $width_min = _max2(length($v_min), length($inc_min));
    my $width_pl  = _max2(length($v_pl ), length($inc_pl ));

    $v_min .= "0" x ($width_min-length($v_min)) if $width_min;
    $v_pl  .= "0" x ($width_pl -length($v_pl )) if $width_pl;
    $inc_min .= "0" x ($width_min-length($inc_min)) if $width_min;
    $inc_pl  .= "0" x ($width_pl -length($inc_pl )) if $width_pl;

    if ($which eq 'subtract') {
        $inc_min = "-$inc_min" if length($inc_min);
        $inc_pl  = "-$inc_pl"  if length($inc_pl );

    }
    $v_min = 0 if !length($v_min) && $width_min;
    $v_pl  = 0 if !length($v_pl)  && $width_pl;
    $inc_min = 0 if !length($inc_min) && $width_min;
    $inc_pl  = 0 if !length($inc_pl)  && $width_pl;

    if ($width_pl) {
        my $limit = "1" . ("0" x $width_pl);
        $v_pl += $inc_pl;
        if ($v_pl < 0) {
            $v_pl += $limit;
            $v_min--;
        } elsif ($v_pl >= $limit) {
            $v_pl -= $limit;
            $v_min++;
        }
        $v_pl = ("0" x ($width_pl -length($v_pl))) . $v_pl
    }
    if ($width_min) {
        my $limit = "1" . ("0" x $width_min);
        $v_min += $inc_min;
        if ($v_min < 0) {
            $v_min += $limit;
            $v_maj--;
        } elsif ($v_min >= $limit) {
            $v_min -= $limit;
            $v_maj++;
        }
        $v_min = ("0" x ($width_min -length($v_min))) . $v_min;
    }
    $v_maj += $inc_maj;
    die "Version subtraction results in negative version ($v - $inc)"
        if $v_maj < 0;

    $v_maj . ($width_min ? ".$v_min" : '') . ($width_pl ? ".$v_pl" : "");
}

sub add_version {
    _add_or_subtract_version('add', @_);
}

sub subtract_version {
    _add_or_subtract_version('subtract', @_);
}

1;
# ABSTRACT: Version-number utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

Version::Util - Version-number utilities

=head1 VERSION

This document describes version 0.730 of Version::Util (from Perl distribution Version-Util), released on 2018-01-09.

=head1 DESCRIPTION

This module provides several convenient functions related to version numbers,
e.g. for comparing them.

=head1 FUNCTIONS

=head2 cmp_version($v1, $v2) => -1|0|1

Equivalent to:

 version->parse($v1) <=> version->parse($v2)

=head2 version_eq($v1, $v2) => BOOL

=head2 version_ne($v1, $v2) => BOOL

=head2 version_lt($v1, $v2) => BOOL

=head2 version_le($v1, $v2) => BOOL

=head2 version_gt($v1, $v2) => BOOL

=head2 version_ge($v1, $v2) => BOOL

=head2 version_between($v, $v1, $v2[, $v1b, $v2b, ...]) => BOOL

=head2 version_in($v, $v1[, $v2, ...]) => BOOL

=head2 add_version($v, $increment) => $new_v

Add C<$increment> to version C<$v>. Both increment and version must match:

 /\Av?\d{1,3}(?:\.\d{1,3}){0,2}\z/

so trial/dev releases like C<v1.2.3_1> are not currently supported. Some
examples:

 0.1 + 0.1 -> 0.2
 0.01 + 0.001 -> 0.011
 0.01 + 0.1 -> 0.11
 0.9 + 0.1 -> 1.0
 0.99 + 0.1 -> 1.09
 1.1.0 + 0.0.1 -> 1.1.1

=head2 subtract_version($v, $decrement) => $new_v

Subtract C<$decrement> from version C<$v>. This is the reverse operation for
C<add_version>.

Will die if the result is negative.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Version-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Version-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Version-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<version>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
