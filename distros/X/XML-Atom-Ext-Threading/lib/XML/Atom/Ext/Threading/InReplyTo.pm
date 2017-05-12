package XML::Atom::Ext::Threading::InReplyTo;

use strict;
use warnings;
use base 'XML::Atom::Base';
use XML::Atom::Ext::Threading;

our $VERSION = '0.01';

__PACKAGE__->mk_attr_accessors(qw( ref href type source ));

sub element_name { 'in-reply-to' }
sub element_ns { XML::Atom::Ext::Threading->element_ns }

1;

=head1 NAME

XML::Atom::Ext::Threading::InReplyTo

=head1 SYNOPSIS

  use XML::Atom::Entry;
  use XML::Atom::Ext::Threading;

  my $entry = XML::Atom::Entry->new;

  # "in-reply-to" extension element
  my $reply = XML::Atom::Ext::Threading::InReplyTo->new;
  $reply->ref('tag:example.org,2005:1');
  $reply->href('http://www.example.org/entries/1');
  $reply->type('application/xhtml+xml');
  $entry->in_reply_to($reply);

=head1 METHODS

=head2 ref($ref)

=head2 href($href)

=head2 type($type)

=head2 source($source)

=head2 element_name

returns 'in-reply-to'

=head2 element_ns

returns the Atom Threading namespace, C<http://purl.org/syndication/thread/1.0>

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::Atom::Ext::Threading>

=cut
