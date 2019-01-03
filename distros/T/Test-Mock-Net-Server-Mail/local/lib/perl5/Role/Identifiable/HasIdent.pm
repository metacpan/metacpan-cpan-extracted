package Role::Identifiable::HasIdent;
{
  $Role::Identifiable::HasIdent::VERSION = '0.007';
}
use Moose::Role;
# ABSTRACT: a thing with an ident attribute


use Moose::Util::TypeConstraints;

has ident => (
  is  => 'ro',
  isa => subtype('Str', where { length && /\A\S/ && /\S\z/ }),
  required => 1,
);

no Moose::Role;
use Moose::Util::TypeConstraints;
1;

__END__

=pod

=head1 NAME

Role::Identifiable::HasIdent - a thing with an ident attribute

=head1 VERSION

version 0.007

=head1 DESCRIPTION

This is an incredibly simple role.  It adds a required C<ident> attribute that
stores a simple string, meant to identify exceptions.

The string has to contain at least one character, and it can't start or end
with whitespace.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
