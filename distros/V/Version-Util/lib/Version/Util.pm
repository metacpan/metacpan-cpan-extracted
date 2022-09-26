package Version::Util;

use 5.010001;
use strict;
use version 0.77;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-22'; # DATE
our $DIST = 'Version-Util'; # DIST
our $VERSION = '0.732'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(
                       cmp_version
                       version_eq version_ne
                       version_lt version_le version_gt version_ge
                       version_between version_in

                       min_version max_version

                       add_version subtract_version
               );

sub cmp_version {
    my $res; eval { $res = version->parse($_[0]) <=> version->parse($_[1]) }; die "Can't cmp_version $_[0] & $_[1]: $@" if $@; $res;
}

sub version_eq {
    my $res; eval { $res = version->parse($_[0]) == version->parse($_[1]) }; die "Can't version_eq $_[0] & $_[1]: $@" if $@; $res;
}

sub version_ne {
    my $res; eval { $res = version->parse($_[0]) != version->parse($_[1]) }; die "Can't version_ne $_[0] & $_[1]: $@" if $@; $res;
}

sub version_lt {
    my $res; eval { $res = version->parse($_[0]) <  version->parse($_[1]) }; die "Can't version_lt $_[0] & $_[1]: $@" if $@; $res;
}

sub version_le {
    my $res; eval { $res = version->parse($_[0]) <= version->parse($_[1]) }; die "Can't version_le $_[0] & $_[1]: $@" if $@; $res;
}

sub version_gt {
    my $res; eval { $res = version->parse($_[0]) >  version->parse($_[1]) }; die "Can't version_gt $_[0] & $_[1]: $@" if $@; $res;
}

sub version_ge {
    my $res; eval { $res = version->parse($_[0]) >= version->parse($_[1]) }; die "Can't version_ge $_[0] & $_[1]: $@" if $@; $res;
}

sub version_between {
    my $v0 = shift;
    my $v; eval { $v = version->parse($v0) };
    die "Can't version_between for $v0: $@" if $@;
    while (@_) {
        my $v1 = shift;
        my $v2 = shift;
        my $return; eval { $return++ if $v >= version->parse($v1) && $v <= version->parse($v2) };
        return 1 if $return;
        die "Can't version_between $v1 <= $v0 <= $v2: $@" if $@;
    }
    0;
}

sub version_in {
    my $v0 = shift;
    my $v; eval { $v = version->parse($v0) };
    die "Can't version_in for $v0: $@" if $@;
    for (@_) {
        my $return; eval { $return++ if $v == version->parse($_) };
        return 1 if $return;
        die "Can't version_in: $v0 == $_: $@" if $@;
    }
    0;
}

sub _max2 {
    $_[0] > $_[1] ? $_[0] : $_[1];
}

sub min_version {
    my @v = sort {
        my $res; eval { $res = version->parse($a) <=> version->parse($b) };
        die "Can't min_version: Can't sort $a vs $b: $@" if $@;
        $res;
    } @_;
    @v ? $v[0] : undef;
}

sub max_version {
    my @v = sort {
        my $res; eval { $res = version->parse($a) <=> version->parse($b) };
        die "Can't max_version: Can't sort $a vs $b: $@" if $@;
        $res;
    } @_;
    @v ? $v[-1] : undef;
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

This document describes version 0.732 of Version::Util (from Perl distribution Version-Util), released on 2022-09-22.

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

=head2 min_version($v1, ...) => $max_v

=head2 max_version($v1, ...) => $max_v

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

=head1 SEE ALSO

L<version>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2018, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Version-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
