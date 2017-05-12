package Test::Magpie::Role::MethodCall;
{
  $Test::Magpie::Role::MethodCall::VERSION = '0.11';
}
# ABSTRACT: A role that represents a method call
use Moose::Role;
use namespace::autoclean;

use aliased 'Test::Magpie::ArgumentMatcher';

use Devel::PartialDump;
use MooseX::Types::Moose qw( ArrayRef Str );
use Test::Magpie::Util qw( match );

my $Dumper = Devel::PartialDump->new(objects => 0, stringify => 1);

has 'method_name' => (
    isa => Str,
    is  => 'ro',
    required => 1
);

has 'arguments' => (
    isa     => ArrayRef,
    traits  => ['Array'],
    handles => { arguments => 'elements' },
    default => sub { [] },
);

sub as_string {
    my ($self) = @_;
    return $self->method_name . '(' . $Dumper->dump($self->arguments) . ')';
}

sub satisfied_by {
    my ($self, $invocation) = @_;

    return unless $invocation->method_name eq $self->method_name;

    my @input = $invocation->arguments;
    my @expected = $self->arguments;
    while (@input && @expected) {
        my $matcher = shift @expected;

        if (ref($matcher) eq ArgumentMatcher) {
            @input = $matcher->match(@input);
        }
        else {
            my $value = shift @input;
            return '' if !match($value, $matcher);
        }
    }
    return @input == 0 && @expected == 0;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Magpie::Role::MethodCall - A role that represents a method call

=head1 ATTRIBUTES

=head2 arguments

An array reference of arguments, or argument matchers.

=head2 method_name

The name of the method.

=head1 METHODS

=head2 as_string

Stringifies this method call to something that roughly resembles what you'd type
in Perl.

=head2 satisfied_by (MethodCall $invocation)

Returns true if the given $invocation would satisfy this method call. Note that
while the $invocation could have arguments matchers in C<arguments>, they will
be passed into this method calls argument matcher. Which basically means, it
probably won't work.

=head1 INTERNAL

This class is internal and not meant for use outside Magpie.

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
