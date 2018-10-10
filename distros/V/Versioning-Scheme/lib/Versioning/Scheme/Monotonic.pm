package Versioning::Scheme::Monotonic;

our $DATE = '2018-10-11'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
use Role::Versioning::Scheme;

our $re = qr/\A([1-9][0-9]*)\.([1-9][0-9]*)(\.0)?(\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?\z/;

sub is_valid_version {
    my ($self, $v) = @_;
    $v =~ $re ? 1:0;
}

sub normalize_version {
    my ($self, $v, $opts) = @_;
    $opts //= {};

    die "Invalid version '$v'" unless $v =~ $re;

    "$1.$2" . ($4 || '');
}

sub cmp_version {
    my ($self, $v1, $v2) = @_;

    die "Invalid version '$v1'" unless my ($c1, $r1, undef, $m1) = $v1 =~ $re;
    die "Invalid version '$v2'" unless my ($c2, $r2, undef, $m2) = $v2 =~ $re;

    ($c1 <=> $c2) || ($r1 <=> $r2) || (($m1||'') cmp ($m2||''));
}

sub bump_version {
    my ($self, $v, $opts) = @_;
    $opts //= {};
    $opts->{num} //= 1;
    $opts->{part} //= 1;

    die "Invalid version '$v'" unless my ($c, $r, $z, $m) = $v =~ $re;
    die "Invalid 'num', must be non-zero" unless $opts->{num} != 0;
    die "Invalid 'part', must be 0|1" unless $opts->{part} =~ /\A(0|1)\z/;

    if ($opts->{part} == 0) {
        if ($c + $opts->{num} < 1) {
            die "Cannot decrease compatibility that would result in zero/negative number";
        }
        if ($r + ($opts->{num} < 0 ? -1 : 1) < 1) {
            die "Cannot decrease compatibility that would result in zero/negative release number";
        }
        $c = $c + $opts->{num};
        $r = $r + ($opts->{num} < 0 ? -1 : 1);
    } else {
        if ($r + $opts->{num} < 1) {
            die "Cannot decrease release that would result in zero/negative number";
        }
        $r = $r + $opts->{num};
    }
    join("", $c, ".", $r, ($z||''), ($m||''));
}

1;
# ABSTRACT: Monotonic versioning

__END__

=pod

=encoding UTF-8

=head1 NAME

Versioning::Scheme::Monotonic - Monotonic versioning

=head1 VERSION

This document describes version 0.005 of Versioning::Scheme::Monotonic (from Perl distribution Versioning-Scheme), released on 2018-10-11.

=head1 SYNOPSIS

 use Versioning::Scheme::Monotonic;

 # checking validity
 Versioning::Scheme::Monotonic->is_valid('1.2');   # 1
 Versioning::Scheme::Monotonic->is_valid('1.02');  # 0
 Versioning::Scheme::Monotonic->is_valid('1.2.0'); # 1
 Versioning::Scheme::Monotonic->is_valid('1.2.1'); # 0
 Versioning::Scheme::Monotonic->is_valid('1.2+foo.123'); # 1

 # normalizing
 Versioning::Scheme::Monotonic->normalize('1.2.0'); # => '1.2'
 Versioning::Scheme::Monotonic->normalize('1.2.0+foo.123'); # => '1.2+foo.123'

 # comparing
 Versioning::Scheme::Monotonic->compare('1.2', '1.2.0'); # 0
 Versioning::Scheme::Monotonic->compare('1.2', '1.13');  # -1
 Versioning::Scheme::Monotonic->compare('2.2', '1.13');  # 1
 Versioning::Scheme::Monotonic->compare('2.2+alpha', '2.2+beta');  # -1

 # bumping
 Versioning::Scheme::Monotonic->bump('1.2');            # => '1.3'
 Versioning::Scheme::Monotonic->bump('1.2', {num=>2});  # => '1.4'
 Versioning::Scheme::Monotonic->bump('1.2', {part=>0}); # => '2.3'
 Versioning::Scheme::Monotonic->bump('2.2', {num=>-1, part=>0}); # => '1.1'

You can also mix this role into your class.

=head1 DESCRIPTION

This role implements the monotonic versioning scheme as described in [1]. A
version number comprises two whole numbers:

 COMPATIBILITY.RELEASE

where COMPATIBILITY starts at 0 and RELEASE starts at 1 with no zero prefix. An
additional ".0" marker is allowed for compatibility with semantic versioning:

 COMPATIBILITY.RELEASE.0

And an additional metadata after the RELEASE or ".0" marker in the form of "+"
followed by a dot-separated series of identifiers. Identifier must comprise only
of [0-9A-Za-z-] and cannot be empty.

RELEASE is always increased. COMPATIBILITY is increased whenever there's a
backward-incompatibility introduced.

Normalizing just normalized COMPATIBILITY.RELEASE.0 into COMPATIBILITY.RELEASE.

Comparing is performed using this expression:

 (COMPATIBILITY1 <=> COMPATIBILITY2) || (RELEASE1 <=> RELEASE2) || (METADATA1 cmp METADATA2)

Bumping by default increases RELEASE by 1. You can specify option C<num> (e.g.
2) to bump RELEASE by that number. You can specify option C<part> (e.g. 0) to
increase COMPATIBILITY instead; but in that case RELEASE will still be bumped by
1.

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

[1] L<http://blog.appliedcompscilab.com/monotonic_versioning_manifesto/>

L<Version::Monotonic>, an older incantation of this module.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
