package Versioning::Scheme::Semantic;

our $DATE = '2018-10-11'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
use Role::Versioning::Scheme;

our $re = qr/\A([0-9]|[1-9][0-9]*)\.([0-9]|[1-9][0-9]*)\.([0-9]|[1-9][0-9]*)\z/;

sub is_valid_version {
    my ($self, $v) = @_;
    $v =~ $re ? 1:0;
}

sub normalize_version {
    my ($self, $v, $opts) = @_;
    $opts //= {};

    die "Invalid version '$v'" unless $self->is_valid_version($v);
    $v;
}

sub cmp_version {
    my ($self, $v1, $v2) = @_;

    die "Invalid version '$v1'" unless my ($x1, $y1, $z1) = $v1 =~ $re;
    die "Invalid version '$v2'" unless my ($x2, $y2, $z2) = $v2 =~ $re;

    ($x1 <=> $x2) || ($y1 <=> $y2) || ($z1 <=> $z2);
}

sub bump_version {
    my ($self, $v, $opts) = @_;
    $opts //= {};
    $opts->{num} //= 1;
    $opts->{part} //= -1;
    $opts->{reset_smaller} //= 1;

    die "Invalid version '$v'" unless $self->is_valid_version($v);
    die "Invalid 'num', must be non-zero" unless $opts->{num} != 0;
    my @parts = split /\./, $v;
    die "Invalid 'part', must not be larger than ".$#parts
        if $opts->{part} > $#parts;
    die "Invalid 'part', must not be smaller than -".@parts
        if $opts->{part} < -@parts;

    my $idx = $opts->{part};
    $parts[$idx] //= 0;
    die "Cannot decrease version, would result in a negative number part"
        if $parts[$idx] + $opts->{num} < 0;
    $parts[$idx] = $parts[$idx]+$opts->{num};
    if ($opts->{reset_smaller} && $opts->{num} > 0) {
        $idx = @parts + $idx if $idx < 0;
        for my $i ($idx+1 .. $#parts) {
            $parts[$i] //= 0;
            $parts[$i] = sprintf("%0".length($parts[$i])."d", 0);
        }
    }
    join(".", map {$_//0} @parts);
}

1;
# ABSTRACT: Semantic versioning

__END__

=pod

=encoding UTF-8

=head1 NAME

Versioning::Scheme::Semantic - Semantic versioning

=head1 VERSION

This document describes version 0.005 of Versioning::Scheme::Semantic (from Perl distribution Versioning-Scheme), released on 2018-10-11.

=head1 SYNOPSIS

 use Versioning::Scheme::Semantic;

 # checking validity
 Versioning::Scheme::Semantic->is_valid('0.0.1');    # 1
 Versioning::Scheme::Semantic->is_valid('0.01.1');   # 0 (zero prefix not allowed)
 Versioning::Scheme::Semantic->is_valid('0.1.1.0');  # 0 (only X.Y.Z permitted)

 # normalizing (currently does nothing other than checking for validity)
 Versioning::Scheme::Semantic->normalize('1.2.0'); # => '1.2.0'

 # comparing
 Versioning::Scheme::Semantic->compare('1.2.3', '1.2.3');  # 0
 Versioning::Scheme::Semantic->compare('1.2.3', '1.2.12'); # -1
 Versioning::Scheme::Semantic->compare('1.3.0', '1.2.12'); # 1

 # bumping
 Versioning::Scheme::Semantic->bump('1.2.3');                               # => '1.2.4'
 Versioning::Scheme::Semantic->bump('1.2.3', {num=>2});                     # => '1.2.5'
 Versioning::Scheme::Semantic->bump('1.2.3', {num=>-1});                    # => '1.2.2'
 Versioning::Scheme::Semantic->bump('1.2.3', {part=>-2});                   # => '1.3.0'
 Versioning::Scheme::Semantic->bump('1.2.3', {part=>0});                    # => '2.0.0'
 Versioning::Scheme::Semantic->bump('1.2.3', {part=>-2, reset_smaller=>0}); # => '1.3.3'

You can also mix this role into your class.

=head1 DESCRIPTION

This role implements the semantic versioning scheme as described in [1]. Version
number comprises of three non-negative integers X.Y.Z where zero-prefix is not
allowed.

This scheme is B<not> the same as the Perl versioning scheme implemented by
L<version>, as the latter has some Perl-specific peculiarities.

Normalizing basically does nothing except checking the validity.

Comparing: Each part is compared numerically from the biggest (leftmost) part.

Bumping: By default the smallest (rightmost) part is increased by 1. You can
specify options: C<num>, C<part>, C<reset_smaller> like spacified in
L<Role::Versioning::Scheme>.

=head1 METHODS

=head2 is_valid_version

=head2 normalize_version

=head2 cmp_version

=head2 bump_version

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Versioning-Scheme>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Versioning-Scheme>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Versioning-Scheme>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

[1] L<https://semver.org/>

L<Versioning::Scheme::Dotted>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
