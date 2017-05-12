package Text::TOC::Role::OutputHandler;
{
  $Text::TOC::Role::OutputHandler::VERSION = '0.10';
}

use strict;
use warnings;
use namespace::autoclean;

use Moose::Role;

requires qw( process_node_list );

1;

# ABSTRACT: A role for output handlers


__END__
=pod

=head1 NAME

Text::TOC::Role::OutputHandler - A role for output handlers

=head1 VERSION

version 0.10

=head1 DESCRIPTION

This role defines the API for output handlers.

=head1 REQUIRED METHODS

This role requires one method:

=head2 $handler->process_node_list($nodes)

This method takes an array reference of objects which implement the
L<Text::TOC::Role::Node> API and does something with them. Typically, that
"something" will be to construct a representation of the table of contents,
and to insert anchors for the nodes into the source document.

Note that this latter feature requires that the nodes reference the source
document somehow. For example, with an HTML document, the implementation uses
HTML::DOM, which means that nodes are able to access their entire containing
document.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

