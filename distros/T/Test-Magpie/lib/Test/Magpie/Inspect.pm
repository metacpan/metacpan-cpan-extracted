package Test::Magpie::Inspect;
{
  $Test::Magpie::Inspect::VERSION = '0.11';
}
# ABSTRACT: Inspect method invocations on mock objects

use Moose;
use namespace::autoclean;

use aliased 'Test::Magpie::Invocation';

use List::Util qw( first );
use Test::Magpie::Util qw( extract_method_name get_attribute_value );

with 'Test::Magpie::Role::HasMock';

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    my $inspect = Invocation->new(
        method_name => extract_method_name($AUTOLOAD),
        arguments   => \@_,
    );

    my $mock        = get_attribute_value($self, 'mock');
    my $invocations = get_attribute_value($mock, 'invocations');

    return first { $inspect->satisfied_by($_) } @$invocations;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Magpie::Inspect - Inspect method invocations on mock objects

=head1 SYNOPSIS

    my $mock = mock;
    $mock->something({ deep => { structure => [] }};
    my $invocation = inspect($mock)->something(anything);
    ok(defined $invocation, 'something was called');
    is_deeply(($invocation->arguments)[0],
        { deep => { structure => [] }})

=head1 DESCRIPTION

Inspecting a mock object allows you to write slightly clearer tests than having
a complex verification call.

L<Test::Magpie/inspect> gives back an object of this class that has the same
API as your mock object. When a method is called, it checks if any invocation
matches its name and argument specification (inspectors can use argument
matchers). If so it will return that invocation as a L<Test::Magpie::Invocation>
object. Otherwise, C<undef> is returned.

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
