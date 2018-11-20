package Versioning::Scheme::Python;

our $DATE = '2018-11-18'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
use Role::Tiny::With;
with 'Role::Versioning::Scheme';
use PerlX::Maybe;
use Python::Version;

sub is_valid_version {
    my ($self, $v) = @_;
    eval { Python::Version->parse($v) };
    $@ ? 0:1;
}

sub parse_version {
    my ($self, $v) = @_;

    my $vp;
    eval { $vp = Python::Version->parse($v) };
    return undef if $@;
    +{
        maybe epoch          => $vp->{_epoch},
        maybe base           => $vp->{_base_version},
        maybe prerelease     => $vp->{_prerelease},
        maybe postrelease    => $vp->{_postrelease},
        maybe devrelease     => $vp->{_devrelease},
        maybe local          => $vp->{_local_version},
    };
}

sub normalize_version {
    my ($self, $v) = @_;
    Python::Version->parse($v)->normal;
}

sub cmp_version {
    my ($self, $v1, $v2) = @_;

    Python::Version->parse($v1) <=> Python::Version->parse($v2);
}

sub bump_version {
    my ($self, $v, $opts) = @_;
    $opts //= {};
    $opts->{num} //= 1;
    $opts->{part} //= -1;
    $opts->{reset_smaller} //= 1;

    my $vp = Python::Version->parse($v);
    die "Invalid 'num', must be non-zero" unless $opts->{num} != 0;

    if ($opts->{part} =~ /\A-?\d+\z/) {
        die "Invalid 'part', must not be smaller than -".@{$vp->{_base_version}}
            if $opts->{part} < -@{ $vp->{_base_version} };
        die "Invalid 'part', must not be larger than ".$#{$vp->{_base_version}}
            if $opts->{part} > $#{$vp->{_base_version}};

        my $idx = $opts->{part}; $idx = @{$vp->{_base_version}} + $idx if $idx < 0;
        # for now, we do not allow decreasing that overflow to the next more
        # significant part
        die "Cannot decrease version, would result in a negative part"
            if $vp->{_base_version}[$idx] + $opts->{num} < 0;
        my $i = $idx;
        my $left = $opts->{num};
        while (1) {
            if ($i == 0 || $vp->{_base_version}[$i]+$left < 1000) {
                $vp->{_base_version}[$i] += $left;
                $left = 0;
                last;
            } else {
                my $tmp = $vp->{_base_version}[$i] + $left;
                $vp->{_base_version}[$i] = $tmp % 1000;
                $left = int($tmp / 1000);
                $i--;
                next;
            }
        }
        if ($opts->{reset_smaller} && $opts->{num} > 0) {
            $idx = @{$vp->{_base_version}} + $idx if $idx < 0;
            for my $i ($idx+1 .. $#{$vp->{_base_version}}) {
                $vp->{_base_version}[$i] = 0;
            }
        }
    } elsif ($opts->{part} =~ /\A(a|b|rc)\z/) {
        die "Can't bump version: no $opts->{part} part"
            unless $vp->{_prerelease} && $vp->{_prerelease}[0] eq $opts->{part};
        die "Cannot decrease version, would result in a negative $opts->{part} part"
            if $vp->{_prerelease}[1] + $opts->{num} < 0;
        $vp->{_prerelease}[1] += $opts->{num};
    } elsif ($opts->{part} eq 'post') {
        die "Can't bump version: no $opts->{part} part"
            unless $vp->{_postrelease};
        die "Cannot decrease version, would result in a negative $opts->{part} part"
            if $vp->{_postrelease}[1] + $opts->{num} < 0;
        $vp->{_postrelease}[1] += $opts->{num};
    } elsif ($opts->{part} eq 'dev') {
        die "Can't bump version: no $opts->{part} part"
            unless $vp->{_devrelease};
        die "Cannot decrease version, would result in a negative $opts->{part} part"
            if $vp->{_devrelease}[1] + $opts->{num} < 0;
        $vp->{_devrelease}[1] += $opts->{num};
    } elsif ($opts->{part} eq 'epoch') {
        $vp->{_epoch} //= 0;
        die "Cannot decrease version, would result in a negative $opts->{part} part"
            if $vp->{_epoch} + $opts->{num} < 0;
        $vp->{_epoch} += $opts->{num};
    } else {
        die "Invalid part '$opts->{part}'";
    }
    $vp->normal;
}

1;
# ABSTRACT: Python (PEP 440) version numbering

__END__

=pod

=encoding UTF-8

=head1 NAME

Versioning::Scheme::Python - Python (PEP 440) version numbering

=head1 VERSION

This document describes version 0.001 of Versioning::Scheme::Python (from Perl distribution Versioning-Scheme-Python), released on 2018-11-18.

=head1 SYNOPSIS

 use Versioning::Scheme::Python;

 # checking validity
 Versioning::Scheme::Perl->is_valid_version('1.2.1a1');  # 1
 Versioning::Scheme::Perl->is_valid_version('foo1');     # 0

 # parsing
 $parsed = Versioning::Scheme::Perl->parse_version('1.2.1a1');  # => {base=>[1, 2, 1], prerelease=>["a",1]}

 # normalizing
 Versioning::Scheme::Perl->normalize_version('1.001');  # => '1.1'

 # comparing
 Versioning::Scheme::Perl->cmp_version('1.2.1', '1.2.01');    # 0
 Versioning::Scheme::Perl->cmp_version('1.2.1', '1.2.1a1');   # 1
 Versioning::Scheme::Perl->cmp_version('1.2.1', '1!1.1.0');   # -1

 # bumping
 Versioning::Scheme::Perl->bump_version('1.2.3');                               # => '1.2.4'
 Versioning::Scheme::Perl->bump_version('1.2.3', {num=>2});                     # => '1.2.5'
 Versioning::Scheme::Perl->bump_version('1.2.3', {num=>-1});                    # => '1.2.2'
 Versioning::Scheme::Perl->bump_version('1.2.3', {part=>-2});                   # => '1.3.0'
 Versioning::Scheme::Perl->bump_version('1.2.3', {part=>0});                    # => '2.0.0'
 Versioning::Scheme::Perl->bump_version('1.2.3', {part=>-2, reset_smaller=>0}); # => '1.3.3'
 Versioning::Scheme::Perl->bump_version('1.2.3a1', {part=>'a'});                # => '1.2.3a2'

You can also mix this role into your class.

=head1 DESCRIPTION

This role handles Python versioning scheme (as defined in PEP 440) which can be
used to version Python-based projects. The role uses L<Python::Version>
internally.

=head1 METHODS

=head2 is_valid_version

=head2 parse_version

=head2 normalize_version

=head2 parse_version

=head2 cmp_version

=head2 bump_version

Usage:

 Versioning::Scheme::Python->bump_version($v [ , \%opts ]);

Options:

=over

=item * num => int (default: 1)

=item * part => int|str (default: -1)

Use number to bump base version, e.g.:

 Versioning::Scheme::Python->bump_version('1.2.7', {part=>1});                   # => 1.3.0
 Versioning::Scheme::Python->bump_version('1.2.7', {part=>1, reset_smaller=>0}); # => 1.3.7

 Versioning::Scheme::Python->bump_version('1.2.7', {part=>-3});                  # => 2.0.0

Use C<dev>, C<post>, C<a>, C<b>, C<rc> to bump dev/post/alpha/beta/rc numbers,
respectively. Will die if version does not have those elements.

Use C<epoch> to bump epoch number.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Versioning-Scheme-Python>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Versioning-Scheme-Python>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Versioning-Scheme-Python>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Python::Version>

Python PEP 440, L<https://www.python.org/dev/peps/pep-0440/>

L<Role::Versioning::Scheme>

Other C<Versioning::Scheme::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
