package Test::Routine::Test::Role;
# ABSTRACT: role providing test attributes
$Test::Routine::Test::Role::VERSION = '0.025';
use Moose::Role;

has description => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  default => sub { $_[0]->name },
);

has _origin => (
  is  => 'ro',
  isa => 'HashRef',
  required => 1,
);

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Routine::Test::Role - role providing test attributes

=head1 VERSION

version 0.025

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
