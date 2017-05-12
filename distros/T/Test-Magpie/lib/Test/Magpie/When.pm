package Test::Magpie::When;
{
  $Test::Magpie::When::VERSION = '0.11';
}
# ABSTRACT: The process of stubbing a mock method call

use Moose;
use namespace::autoclean;

use aliased 'Test::Magpie::Stub';
use Test::Magpie::Util qw( extract_method_name get_attribute_value );

with 'Test::Magpie::Role::HasMock';

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $method_name = extract_method_name($AUTOLOAD);

    my $stub = Stub->new(
        method_name => $method_name,
        arguments   => \@_,
    );

    my $mock  = get_attribute_value($self, 'mock');
    my $stubs = get_attribute_value($mock, 'stubs');

    push @{ $stubs->{$method_name} }, $stub;

    return $stub;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Magpie::When - The process of stubbing a mock method call

=head1 DESCRIPTION

A mock object in stub mode to declare a stubbed method. You generate this by
calling C<when> in L<Test::Magpie> with a mock object.

This object has the same API as the mock object - any method call will start the
creation of a L<Test::Magpie::Stub>, which can be modified to tailor the stub
call. You are probably more interested in that documentation.

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
