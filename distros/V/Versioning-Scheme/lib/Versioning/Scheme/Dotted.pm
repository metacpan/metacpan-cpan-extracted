package Versioning::Scheme::Dotted;

our $DATE = '2018-10-04'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Versioning::Scheme;

my $re = qr/\A[0-9]+(?:\.[0-9]+)*\z/;

sub is_valid {
    my ($self, $v) = @_;
    $v =~ $re ? 1:0;
}

sub normalize {
    my ($self, $v, $opts) = @_;
    $opts //= {};

    die "Invalid version '$v'" unless $self->is_valid($v);

    my @parts = split /\./, $v;
    if (defined $opts->{parts}) {
        die "parts must at least be 1" unless $opts->{parts} >= 1;
        if ($opts->{parts} < @parts) {
            splice @parts, $opts->{parts};
        } else {
            $parts[$opts->{parts}-1] //= 0;
        }
    }
    join(".", map { $_ // "0" } @parts);
}

sub cmp {
    my ($self, $v1, $v2) = @_;

    die "Invalid version '$v1'" unless $self->is_valid($v1);
    die "Invalid version '$v2'" unless $self->is_valid($v2);

    my @parts1 = split /\./, $v1;
    my @parts2 = split /\./, $v2;
    my $n = @parts1 < @parts2 ? @parts2 : @parts1;
    for my $i (0..$n-1) {
        my $cmp = ($parts1[$i] // 0) <=> ($parts2[$i] // 0);
        return $cmp if $cmp;
    }
    0;
}

sub bump {
    my ($self, $v, $opts) = @_;
    $opts //= {};
    $opts->{num} //= 1;
    $opts->{part} //= -1;
    $opts->{reset_smaller} //= 1;

    die "Invalid version '$v'" unless $self->is_valid($v);
    die "Invalid 'num', must be non-zero" unless $opts->{num} != 0;
    my @parts = split /\./, $v;
    die "Invalid 'part', must not be smaller than -".@parts
        if $opts->{part} < -@parts;

    my $idx = $opts->{part};
    $parts[$idx] //= 0;
    die "Cannot decrease version, would result in a negative part"
        if $parts[$idx] + $opts->{num} < 0;
    $parts[$idx] = sprintf("%0".length($parts[$idx])."d",
                           $parts[$idx]+$opts->{num});
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
# ABSTRACT: Version as dotted numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Versioning::Scheme::Dotted - Version as dotted numbers

=head1 VERSION

This document describes version 0.001 of Versioning::Scheme::Dotted (from Perl distribution Versioning-Scheme), released on 2018-10-04.

=head1 SYNOPSIS

 use Versioning::Scheme::Dotted;

 # checking validity
 Versioning::Scheme::Dotted->is_valid('0.001.2.0');  # 1
 Versioning::Scheme::Dotted->is_valid('v0.001.2.0'); # 0
 Versioning::Scheme::Dotted->is_valid('1.2beta');    # 0

 # normalizing
 Versioning::Scheme::Dotted->normalize('0.001.2.0');             # => '0.001.2.0'
 Versioning::Scheme::Dotted->normalize('0.001.2.0', {parts=>3}); # => '0.001.2'
 Versioning::Scheme::Dotted->normalize('0.001.2.0', {parts=>5}); # => '0.001.2.0.0'

 # comparing
 Versioning::Scheme::Dotted->compare('1.2.3', '1.2.3.0'); # 0
 Versioning::Scheme::Dotted->compare('1.2.3', '1.2.4');   # -1
 Versioning::Scheme::Dotted->compare('1.3.1', '1.2.4');   # 1

 # bumping
 Versioning::Scheme::Dotted->bump('1.2.3');                               # => '1.2.4'
 Versioning::Scheme::Dotted->bump('1.2.009');                             # => '1.2.010'
 Versioning::Scheme::Dotted->bump('1.2.999');                             # => '1.2.1000'
 Versioning::Scheme::Dotted->bump('1.2.3', {num=>2});                     # => '1.2.5'
 Versioning::Scheme::Dotted->bump('1.2.3', {num=>-1});                    # => '1.2.2'
 Versioning::Scheme::Dotted->bump('1.2.3', {part=>-2});                   # => '1.3.0'
 Versioning::Scheme::Dotted->bump('1.2.3', {part=>0});                    # => '2.0.0'
 Versioning::Scheme::Dotted->bump('1.2.3', {part=>-2, reset_smaller=>0}); # => '1.3.3'

=head1 DESCRIPTION

This is a general scheme where a version is specified as a series of
one or more non-negative integers separated by dots. Examples:

 1
 1.2
 1.100.0394
 3.4.5.6

This scheme is B<not> the same as the Perl versioning scheme implemented by
L<version>, as the latter has some Perl-specific peculiarities.

Normalizing basically does nothing except checking the validity. But it can
accept an option C<parts> to specify number of parts.

Comparing: Each part is compared numerically from the biggest (leftmost) part.

Bumping: By default the smallest (rightmost) part is increased by 1. You can
specify options: C<num>, C<part>, C<reset_smaller> like spacified in
L<Role::Versioning::Scheme>.

=head1 METHODS

=head2 is_valid

=head2 normalize

=head2 cmp

=head2 bump

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

L<Versioning::Scheme>, L<Role::Versioning::Scheme>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
