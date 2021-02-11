package XML::Loy::Atom::Threading;
use strict;
use warnings;

our $PREFIX;
BEGIN { $PREFIX = 'thr' };

use XML::Loy with => (
  prefix    => $PREFIX,
  namespace => 'http://purl.org/syndication/thread/1.0'
);

use Carp qw/carp/;


# No constructor
sub new {
  carp 'Only use ' . __PACKAGE__ . ' as an extension to Atom';
  return;
};


# Set 'in-reply-to' element
sub in_reply_to {
  my ($self, $ref, $param) = @_;

  # Add in-reply-to
  if ($ref) {

    # No ref defined
    return unless defined $ref;

    # Adding a related link as advised in the spec
    if (defined $param->{href}) {
      my $link = $self->link(related => $param->{href});
      $link->attr->{type} = $param->{type} if $param->{type};
    };

    $param->{ref} = $ref;
    return $self->add('in-reply-to' => $param );
  };

  # Current node is root
  unless ($self->parent) {
    return $self->at('*')->children('in-reply-to');
  };

  # Return collection
  return $self->children('in-reply-to');
};


# Add 'link' element for replies
sub replies {
  my $self = shift;
  my $href = shift;

  # Add link
  if ($href) {

    my %param = %{ shift(@_) };

    my %new_param = (href => $href);
    if (exists $param{count}) {
      $new_param{$PREFIX . ':count'} = delete $param{count};
    };

    # updated parameter exists
    if (exists $param{updated}) {
      my $date = delete $param{updated};

      # Date is no object
      $date = XML::Loy::Date::RFC3339->new($date) unless ref $date;

      # Set parameter
      $new_param{$PREFIX . ':updated'} = $date->to_string;
    };

    $new_param{type} = $param{type} // $self->mime;

    # Add atom link
    return $self->link(rel => 'replies',  %new_param );
  };

  # Get replies
  my $replies = $self->link('replies');

  # Return first link
  return $replies->[0] if $replies->[0];

  return;
};


# Add total value
sub total {
  my ($self, $count, $param) = @_;

  # Set count
  if ($count) {

    # Set new total element
    return $self->set(total => ($param || {}) => $count);
  };

  # Get total
  my $total;

  # Current node is root
  unless ($self->parent) {
    $total = $self->at('*')->children('total');
  }

  # Current node is entry or something
  else {
    $total = $self->children('total');
  };

  # No total set
  return 0 unless $total = $total->[0];

  # Return count
  return $total->text if $total->text;

  return 0;
};


1;


__END__

=pod

=head1 NAME

XML::Loy::Atom::Threading - Threading Extension for Atom


=head1 SYNOPSIS

  use XML::Loy::Atom;

  my $entry = XML::Loy::Atom->new('entry');

  # Add threading extension
  $entry->extension(-Atom::Threading);

  # Add Atom author and id
  $entry->author(name => 'Zoidberg');
  $entry->id('http://sojolicious.example/blog/2');

  # Add threading information
  $entry->in_reply_to('urn:entry:1' => {
    href => 'http://sojolicious.example/blog/1'
  });

  # Add replies information
  $entry->replies('http://sojolicious.example/blog/1/replies' => {
    count => 7,
    updated => time
  });

  # Get threading information
  print $entry->in_reply_to->[0]->attr('href');

  # Pretty print
  print $entry->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <entry xml:id="http://sojolicious.example/blog/2"
  #        xmlns="http://www.w3.org/2005/Atom"
  #        xmlns:thr="http://purl.org/syndication/thread/1.0">
  #   <author>
  #     <name>Zoidberg</name>
  #   </author>
  #   <id>http://sojolicious.example/blog/2</id>
  #   <link href="http://sojolicious.example/blog/1"
  #         rel="related" />
  #   <thr:in-reply-to href="http://sojolicious.example/blog/1"
  #                    ref="urn:entry:1" />
  #   <link href="http://sojolicious.example/blog/1/replies"
  #         rel="replies"
  #         thr:count="7"
  #         thr:updated="2013-03-10T09:55:13Z"
  #         type="application/atom+xml" />
  # </entry>

=head1 DESCRIPTION

L<XML::Loy::Atom::Threading> is an extension to
L<XML::Loy::Atom> and provides additional
functionality for the work with
L<Threading|https://www.ietf.org/rfc/rfc4685.txt>.


=head1 METHODS

L<XML::Loy::Atom::Threading> inherits all methods
from L<XML::Loy> and implements the following new ones.


=head2 in_reply_to

  $entry->in_reply_to('urn:entry:1' => {
    href => 'http://sojolicious.example/blog/1.html',
    type => 'application/xhtml+xml'
  });

  print $entry->in_reply_to->attr('href');

Adds an C<in-reply-to> element to the Atom object or returns it.
Accepts for adding a universally unique ID for the entry to be referred to,
and a hash reference containing attributes like C<href>, C<type> and C<source>.
Will automatically introduce a C<related> link, if a C<href> parameter is given.
Returns the newly added node.

On retrieval, returns the first C<in-reply-to> element.


=head2 replies

  $entry->replies('http://sojolicious.example/entry/1/replies' => {
    count   => 5,
    updated => '2011-08-30T16:16:40Z'
  });

  print $entry->replies->attr('thr:count');

Adds a C<link> element with a relation of C<replies> to the atom object
or returns it.
Accepts the reference URL for replies and optional parameters
like C<count> and C<update> of replies.

The update parameter accepts all valid parameters of
L<XML::Loy::Date::RFC3339::new|XML::Loy::Date::RFC3339/new>.

On retrieval returns the first C<replies> node.

B<This update attribute is experimental and may return another
object with a different API!>


=head2 total

  $entry->total(5);
  print $entry->total;

Sets the C<total> number of responses to the atom object
or returns it.


=head1 DEPENDENCIES

L<Mojolicious>.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2021, L<Nils Diewald|https://www.nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
