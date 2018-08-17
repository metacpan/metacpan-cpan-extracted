package Test::Mock::Two;
our $VERSION = '0.011';
use warnings;
use strict;

# ABSTRACT: Inspection module for Test::Mock::One

use Exporter 'import';
use Carp qw(croak carp);
use List::Util qw(any);

our @EXPORT_OK = qw(
    one_called
    one_called_ok
    one_called_times_ok
    one_called_params_ok
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    test => [ grep { $_ =~ /_ok$/ } @EXPORT_OK ],
);

use Test::Builder;
my $tb = Test::Builder->new();

sub one_called {
    my ($one, $method, $func) = @_;

    if (!UNIVERSAL::isa($one, 'Test::Mock::One')) {
        croak "We only play well with Test::Mock::One";
    }

    if (!$one->{'X-Mock-Called'}) {
        croak "Test::Mock::One object did not specify call tracing", $/;
    }

    if (!defined $method) {
        croak "Failed to provide a method";
    }

    if (my $cs = $one->{'X-Mock-Called-By'}) {
        my $rv = $cs->{$method};

        return unless $rv;
        return $rv if !defined $func;

        return $rv->{$func} if exists $rv->{$func};
    }

    return if !defined $func;

    $func =~ s#::#/#g;
    $func .= '.pm';
    if (any { $func eq $_ } keys %INC) {
        carp("Using Pkg::Name instead of Pkg::Name::Function");
    }
    return;
}

sub one_called_ok {
    my ($one, $method, $func, $msg) = @_;

    $msg //= "${func} called Test::Mock::One->$method";
    my $rv = one_called($one, $method, $func);
    $tb->ok($rv, $msg);
    return $rv if defined $rv;
    return ;
}

sub one_called_times_ok {
    my ($one, $method, $func, $times, $msg) = @_;

    $msg //= "${func} called $times on Test::Mock::One->$method";
    if (my $rv = one_called($one, $method, $func)) {
        $tb->is_eq(scalar @$rv, $times, $msg);
        return $rv;
    }
    else {
        $tb->is_eq(0, $times, $msg);
        return;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Mock::Two - Inspection module for Test::Mock::One

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use Test::Mock::One;
    use Test::Mock::Two qw(:all);
    use Test::Deep;

    my $mock = Test::Mock::One->new(
        'X-Mock-Called' => 1,
    );

    # Do things in your testsuite

    # You may omit the test message, it defaults to a sane value
    one_called_ok($mock, 'foo', 'Pkg::Foo::bar', "'foo' called by Pkg::Foo::bar");
    one_called_times_ok($mock, 'foo', 'Pkg::Foo::bar', 1, "'foo' called once by Pkg::Foo::bar");

    # Check if the arguments are correct
    # one_called_ok and one_called_times_ok return the same values
    my $rv = one_called_times_ok($mock, 'foo', "Pkg::Foo::bar", 1);
    cmp_deeply($rv->[0], [], "Called without arguments");

    $rv = one_called_ok($mock, 'foo', "Pkg::Foo::bar");
    cmp_deeply($rv->[0], [], "Called without arguments");

=head1 DESCRIPTION

This module does the introspection of the L<Test::Mock::One> object.
This is to keep L<Test::Mock::One> as empty as possible, implementing as
little as possible additional methods.

=head1 EXPORTS

This module exports nothing by default, and has two export tags:

=over

=item all

All functions

=item test

All test functions (everything ending with _ok)

=back

=head1 METHODS

=head2 one_called

    one_called($mock, 'mock_method', "Pkg::Name::method");

Check if C<Pkg::Name::method> called $mock->mock_method

=head2 one_called_ok

A L<Test::Builder> enabled version of C<one_called>.

=head2 one_called_times_ok

    one_called($mock, 'mock_method, "Pkg::Name::method", $times);

Test whether the mock object was called so many times for a given function.

=head1 SEE ALSO

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
