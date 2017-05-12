package Tie::Scalar::Random;
use strict;
use warnings;

our $VERSION = '0.02';

sub TIESCALAR {
    my $class = shift;
    my $remember_all = shift;
    if ($remember_all) {
        return bless {remember_all => 1, values => []}, $class;
    }
    else {
        return bless {assigned => 0, value => undef}, $class;
    }
}

sub FETCH {
    my $self = shift;

    if ($self->{remember_all}) {
        return $self->{values}->[ rand @{$self->{values}} ];
    }

    return $self->{value};
}

sub STORE {
    my $self = shift;
    my $value = shift;

    if ($self->{remember_all}) {
        push @{ $self->{values} }, $value;
    }
    elsif (rand(++$self->{assigned}) < 1) {
        $self->{value} = $value;
    }

    return $self->FETCH;
}

sub DESTROY {
    my $self = shift;
    %$self = ();
}

1;

__END__

=head1 NAME

Tie::Scalar::Random - fetch a randomly selected assigned value

=head1 SYNOPSIS

    use Tie::Scalar::Random;

    tie my $line, 'Tie::Scalar::Random';
    while (<>) {
        $line = $_;
    }
    print $line;           # a random line from STDIN
    die if $line ne $line; # should never die

    tie my $line, 'Tie::Scalar::Random', 1;
    while (<>) {
        $line = $_;
    }
    print $line;           # a random line from STDIN
    print $line;           # a possibly different random line from STDIN
    die if $line ne $line; # will probably die

=head1 USAGE

Any time you fetch a value out of a scalar tied by C<Tie::Scalar::Random>, it
will produce a random value that was assigned to that scalar.

Note that it is both memory efficient and fair. Only one such value is stored
at any given time. The scalar will also produce the same value until it is
assigned to again, in which case it may or may not begin producing the new
value.

It is essentially just the C<< rand($.) < 1 >> idiom. See the Perl Cookbook,
recipe 8.6, for an explanation.

Note that if you pass a true value to C<tie>, like so:

    tie my $line, 'Tie::Scalar::Random', 1;

Then every value assigned to the scalar I<will> be remembered. This means it
may use potentially a lot of memory. It also means every time the scalar is
fetched, it can produce any of the values that were assigned to it since C<tie>
time (so C<$line eq $line> may not hold true).

Once the variable has been tied, it will produce C<undef> (even if it had a
genuine value before C<tie>) until something is assigned to it.

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

