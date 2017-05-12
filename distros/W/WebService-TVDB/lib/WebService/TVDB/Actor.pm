use strict;
use warnings;

package WebService::TVDB::Actor;
{
  $WebService::TVDB::Actor::VERSION = '1.133200';
}

# ABSTRACT: Represents an Actor

# Assessors
# alphabetically, case insensitive
use Object::Tiny qw(
  id
  Image
  Name
  Role
  SortOrder
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TVDB::Actor - Represents an Actor

=head1 VERSION

version 1.133200

=head1 ATTRIBUTES

=head2 id

=head2 Image

=head2 Name

=head2 Role

=head2 SortOrder

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
