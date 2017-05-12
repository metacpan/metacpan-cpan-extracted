package Text::TOC::Role::Filter;
{
  $Text::TOC::Role::Filter::VERSION = '0.10';
}

use strict;
use warnings;
use namespace::autoclean;

use Moose::Role;

requires 'node_is_interesting';

1;

# ABSTRACT: A role for node filters


__END__
=pod

=head1 NAME

Text::TOC::Role::Filter - A role for node filters

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This role defines the API for node filters.

=head1 REQUIRED METHODS

This role requires one method:

=head2 $filter->node_is_interesting($node)

This method should take an object which does the L<Text::TOC::Role::Node> role
and return true or false. If it returns true, the node will be included in the
table of contents.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

