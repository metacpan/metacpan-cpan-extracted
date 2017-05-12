package Test::TinyMocker;

use strict;
use warnings;

use Carp qw{ croak };

use vars qw(@EXPORT $VERSION);
use base 'Exporter';

$VERSION = '0.03';
my $mocks = {};

@EXPORT = qw(mock unmock should method methods);

sub method($)  {@_}
sub methods($) {@_}
sub should(&)  {@_}

sub mock {
    croak 'useless use of mock with one or less parameter'
      if scalar @_ < 2;

    # if the last element is a HashRef, it's options to process
    my $options   = {};
    my $last_elem = $_[-1];
    if ( ref($last_elem) eq ref( {} ) ) {
        $options = pop @_;
    }

    # the last element is now the subroutine to use for the mock
    my $sub = pop;

    my @symbols = _flat_symbols(@_);
    my $ignore_unknown = $options->{ignore_unknown} || 0;

    foreach my $symbol (@symbols) {
        croak "unknown symbol: $symbol"
          if !$ignore_unknown && !_symbol_exists($symbol);

        _save_sub($symbol);
        _bind_coderef_to_symbol( $symbol, $sub );
    }
}

sub unmock {
    croak 'useless use of unmock without parameters'
      unless scalar @_;

    my @symbols = _flat_symbols(@_);
    foreach my $symbol (@symbols) {
        croak "unkown method $symbol"
          unless $mocks->{$symbol};

        {
            no strict 'refs';
            no warnings 'redefine', 'prototype';
            *{$symbol} = delete $mocks->{$symbol};
        }
    }
}

sub _flat_symbols {
    if ( @_ == 2 ) {
        return ref $_[1] eq 'ARRAY'
          ? map {qq{$_[0]::$_}} @{ $_[1] }
          : qq{$_[0]::$_[1]};
    }
    else {
        return ref $_[0] eq 'ARRAY'
          ? @{ $_[0] }
          : $_[0];
    }
}

sub _symbol_exists {
    my ($symbol) = @_;
    {
        no strict 'refs';
        no warnings 'redefine', 'prototype';

        return defined *{$symbol}{CODE};
    }
}

sub _bind_coderef_to_symbol {
    my ( $symbol, $sub ) = @_;
    {
        no strict 'refs';
        no warnings 'redefine', 'prototype';

        *{$symbol} = $sub;
    }
}

sub _save_sub {
    my ($name) = @_;

    {
        no strict 'refs';
        $mocks->{$name} ||= *{$name}{CODE};
    }

    return $name;
}

1;


=pod

=head1 NAME

Test::TinyMocker

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use Test::More;
    use Test::TinyMocker;

    mock 'Some::Module'
        => method 'some_method'
        => should {
            return $mocked_value;
        };

    # or

    mock 'Some::Module'
        => methods [ 'this_method', 'that_method' ]
        => should {
            return $mocked_value;
        };

    # or 

    mock 'Some::Module::some_method'
        => should {
            return $mocked_value;
        };

    # Some::Module::some_method() will now always return $mocked_value;

	# To restore the original method
	
	unmock 'Some::Module::some_method';

    # or
	
	unmock 'Some::Module' => method 'some_method';

    # or

    unmock 'Some::Module' => methods [ 'this_method', 'that_method' ];

=head1 NAME

Test::TinyMocker - a very simple tool to mock external modules

=head1 EXPORT

=head2 mock($module, $method_or_methods, $sub, $options)

This function allows you to overwrite the given method with an arbitrary code
block. This lets you simulate soem kind of behaviour for your tests.

Alternatively, this method can be passed only two arguments, the first one will
be the full path of the method (pcakge name + method name) and the second one
the coderef.

An options HashRef can be passed as the last argument. Currently one option is
supported: C<ignore_unknown> (default false) which when sets to true allows to
mock an unknown symbol.

Syntactic sugar is provided (C<method>, C<methods> and C<should>) in order to
let you write sweet mock statements:

    # This:
    mock('Foo::Bar', 'a_method', sub { return 42;});

    # is the same as:
    mock 'Foo::Bar' => method 'a_method' => should { return 42 };

    # or:
    mock 'Foo::Bar::a_method' => should { return 42 };

    # or also:
    mock('Foo::Bar::a_method', sub { return 42;});

Using multiple methods at the same time can be done with arrayrefs:

    # This:
    mock('Foo::Bar', ['a_method', 'b_method'], sub { 42 } );

    # is the same as:
    mock 'Foo::Bar' => methods ['a_method', 'b_method'] => should { 42 };

=head2 unmock($module, $method_or_methods)

Syntactic sugar is provided (C<method> and C<methods>) in order to let you write
sweet unmock statements:

    # This:
    unmock('Foo::Bar', 'a_method');

    # is the same as:
    unmock 'Foo::Bar' => method 'a_method';

And using multiple methods at the same time:

    unmock 'Foo::Bar' => methods ['a_method', 'b_method'];

=head2 method

Syntactic sugar for mock()

=head2 methods

Syntactic sugar for mock()

=head2 should

Syntactic sugar for mock()

=head1 AUTHOR

Alexis Sukrieh, C<< <sukria at sukria.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-tinymocker at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-TinyMocker>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::TinyMocker

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-TinyMocker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-TinyMocker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-TinyMocker>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-TinyMocker/>

=back

=head1 ACKNOWLEDGEMENTS

This module was inspired by Gugod's blog, after the article published about
mocking in Ruby and Perl: L<http://gugod.org/2009/05/mocking.html>

This module was first part of the test tools provided by Dancer in its own t
directory (previously named C<t::lib::EasyMocker>). A couple of developers asked
me if I could released this module as a real Test:: distribution on CPAN, so
here it is.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Alexis Sukrieh <sukria@sukria.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
