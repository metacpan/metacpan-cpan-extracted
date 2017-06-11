package Tie::Array::Expire;

our $DATE = '2017-06-07'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Time::HiRes 'time';

sub TIEARRAY {
    my $class = shift;
    my $expiry = shift;

    die "Please specify a positive expiry time" unless $expiry > 0;
    return bless {
        EXPIRY => $expiry,
        ARRAY => [], # each elem is [val, time]
    }, $class;
}

sub _expire_items {
    my $self = shift;

    my $time = time() - $self->{EXPIRY};
    my $i = 0;
    while (1) {
        last if $i >= @{ $self->{ARRAY} };
        if ($self->{ARRAY}[$i][1] < $time) {
            splice @{ $self->{ARRAY} }, $i, 1;
        } else {
            $i++;
        }
    }
}

sub FETCH {
    my ($self, $index) = @_;
    $self->_expire_items;
    $self->{ARRAY}[$index][0];
}

sub STORE {
    my ($self, $index, $value) = @_;
    $self->_expire_items;
    my $time = time();
    if ($index > @{ $self->{ARRAY} }) {
        for my $i ($#{ $self->{ARRAY} } .. $index-1) {
            $self->{ARRAY}[$i] = [undef, $time];
        }
    }
    $self->{ARRAY}[$index] = [$value, $time];
}

sub FETCHSIZE {
    my $self = shift;
    $self->_expire_items;
    scalar @{ $self->{ARRAY} };
}

sub STORESIZE {
    my ($self, $count) = @_;
    $self->_expire_items;
    my $time = time();
    if ($count > @{ $self->{ARRAY} }) {
        for my $i ($#{ $self->{ARRAY} } .. $count) {
            $self->{ARRAY}[$i] = [undef, $time];
        }
    } elsif ($count < @{ $self->{ARRAY} }) {
        splice @{ $self->{ARRAY} }, $count;
    }
}

# sub EXTEND this, count

# sub EXISTS this, key

# sub DELETE this, key

sub PUSH {
    my $self = shift;
    $self->_expire_items;
    my $time = time();
    push @{ $self->{ARRAY} }, map { [$_, $time] } @_;
}

sub POP {
    my $self = shift;
    $self->_expire_items;
    my $elem = pop @{ $self->{ARRAY} };
    $elem ? $elem->[0] : undef;
}

sub UNSHIFT {
    my $self = shift;
    $self->_expire_items;
    my $time = time();
    unshift @{ $self->{ARRAY} }, map { [$_, $time] } @_;
}

sub SHIFT {
    my $self = shift;
    $self->_expire_items;
    my $elem = shift @{ $self->{ARRAY} };
    $elem ? $elem->[0] : undef;
}

sub SPLICE {
    my $self   = shift;
    my $offset = shift;
    my $length = shift;
    $self->_expire_items;
    my $time = time();

    my @spliced = map { $_->[0] } splice @{ $self->{ARRAY} }, $offset, $length, map { [$_, $time] } @_;
    @spliced;
}

1;
# ABSTRACT: Array with expiring elements

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Array::Expire - Array with expiring elements

=head1 VERSION

This document describes version 0.001 of Tie::Array::Expire (from Perl distribution Tie-Array-Expire), released on 2017-06-07.

=head1 SYNOPSIS

 use Tie::Array::Expire;

 # the elements will expire/disappear after 5 minutes (300 seconds)
 tie my @ary, 'Tie::Array::Expire', 300;

 push @ary, 1, 2, 3;

 # 3 minutes later
 push @ary, 4, 5;
 unshift @ary, 6;

 # 3 minutes later
 print @ary; # (6 5 4) (the elements 1, 2, 3 have expired)

 # 5 minutes later
 print @ary; # () (the elements 6, 5, 4 have also expired)

=head1 DESCRIPTION

This module allows you to create an array with the elements autodisappearing
after a specified expiry time. This array can be used in, e.g.: rate control
checking ("maximum sending 20 emails in 4 hours").

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Array-Expire>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Array-Expire>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Array-Expire>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Algorithm::FloodControl>

L<Tie::Array::QueueExpire>

L<CHI>

L<Tie::Scalar::Expire>, L<Tie::Hash::Expire>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
