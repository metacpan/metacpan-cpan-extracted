package Test::Magpie::Role::HasMock;
{
  $Test::Magpie::Role::HasMock::VERSION = '0.11';
}
# ABSTRACT: A role for objects that wrap around a mock
use Moose::Role;
use namespace::autoclean;

has 'mock' => (
    is => 'bare',
    required => 1
);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Magpie::Role::HasMock - A role for objects that wrap around a mock

=head1 ATTRIBUTES

=head2 mock

The mock object itself. No accessor is generated. Required.

=head1 INTERNAL

This class is internal, and not meant for use outside Magpie.

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
