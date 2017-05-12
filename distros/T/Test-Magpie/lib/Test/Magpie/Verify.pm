package Test::Magpie::Verify;
{
  $Test::Magpie::Verify::VERSION = '0.11';
}
# ABSTRACT: Look into the invocation history of a mock for verification

use Moose;
use namespace::autoclean;

use aliased 'Test::Magpie::Invocation';

use MooseX::Types::Moose qw( Num Str CodeRef );
use Test::Builder;
use Test::Magpie::Types qw( NumRange );
use Test::Magpie::Util qw( extract_method_name get_attribute_value );

with 'Test::Magpie::Role::HasMock';

our $AUTOLOAD;

my $TB = Test::Builder->new;

has 'test_name' => (
    isa => Str,
    reader => '_test_name',
);

has 'times' => (
    isa => Num|CodeRef,
    reader => '_times',
);
has 'at_least' => (
    isa => Num,
    reader => '_at_least',
);
has 'at_most' => (
    isa => Num,
    reader => '_at_most',
);
has 'between' => (
    isa => NumRange,
    reader => '_between',
);

sub AUTOLOAD {
    my $self = shift;
    my $method_name = extract_method_name($AUTOLOAD);

    my $observe = Invocation->new(
        method_name => $method_name,
        arguments   => \@_,
    );

    my $mock        = get_attribute_value($self, 'mock');
    my $invocations = get_attribute_value($mock, 'invocations');

    my $matches = grep { $observe->satisfied_by($_) } @$invocations;

    my $test_name = $self->_test_name;

    if (defined $self->_times) {
        if ( CodeRef->check($self->_times) ) {
            # handle use of deprecated at_least() and at_most()
            $self->_times->(
                $matches, $observe->as_string, $test_name, $TB);
        }
        else {
            $test_name = sprintf '%s was called %u time(s)',
                $observe->as_string, $self->_times
                    unless defined $test_name;
            $TB->is_num( $matches, $self->_times, $test_name );
        }
    }
    elsif (defined $self->_at_least) {
        $test_name = sprintf '%s was called at least %u time(s)',
            $observe->as_string, $self->_at_least
                unless defined $test_name;
        $TB->cmp_ok( $matches, '>=', $self->_at_least, $test_name );
    }
    elsif (defined $self->_at_most) {
        $test_name = sprintf '%s was called at most %u time(s)',
            $observe->as_string, $self->_at_most
                unless defined $test_name;
        $TB->cmp_ok( $matches, '<=', $self->_at_most, $test_name );
    }
    elsif (defined $self->_between) {
        my ($lower, $upper) = @{$self->_between};
        $test_name = sprintf '%s was called between %u and %u time(s)',
            $observe->as_string, $lower, $upper
                unless defined $test_name;
        $TB->ok( $lower <= $matches && $matches <= $upper, $test_name );
    }
    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Magpie::Verify - Look into the invocation history of a mock for verification

=head1 DESCRIPTION

Spy objects allow you to look inside a mock and verify that certain methods have
been called. You create these objects by using C<verify> from L<Test::Magpie>.

Spy objects do not have a public API as such; they share the same method calls
as the mock object itself. The difference being, a method call now checks that
the method was invoked on the mock at some point in time, and if not, fails a
test.

You may use argument matchers in verifying method calls.

=head1 AUTHORS

=over 4

=item *

Oliver Charles <oliver.g.charles@googlemail.com>

=item *

Steven Lee <stevenwh.lee@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
