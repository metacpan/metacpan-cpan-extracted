package XML::Loy::OStatus;
use strict;
use warnings;

use XML::Loy with => (
  prefix => 'ostatus',
  namespace => 'http://ostatus.org/schema/1.0/'
);

use Carp qw/carp/;

# No constructor
sub new {
  carp 'Only use ' . __PACKAGE__ . ' as an extension to Atom';
  return;
};


# Add 'attention' link
sub attention {
  shift->_ostatus_link( attention => @_ );
};


# Add 'conversation' link
sub conversation {
  shift->_ostatus_link( conversation => @_ );
};


# Link elements
sub _ostatus_link {
  my $self = shift;
  my $rel = 'ostatus:' . shift;

  # Get href from link element
  unless (@_) {
    my $att = $self->link($rel) or return;
    $att = $att->[0] or return;
    return $att->attr('href');
  };

  # Create new link element
  return $self->link(
    rel  => $rel,
    href => shift,
    @_
  );
};


# OStatus activity 'leave'
sub verb_leave {
  shift->verb( __PACKAGE__->_namespace . 'leave');
};


# OStatus activity 'unfollow'
sub verb_unfollow {
  shift->verb( __PACKAGE__->_namespace . 'unfollow');
};


# OStatus activity 'unfavorite'
sub verb_unfavorite {
  shift->verb( __PACKAGE__->_namespace . 'unfavorite');
};


1;


__END__

=pod

=head1 NAME

XML::Loy::OStatus - OStatus Format Extension


=head1 SYNOPSIS

  use XML::Loy::Atom;

  my $atom = XML::Loy::Atom->new('entry');
  $atom->extension(-OStatus);

  $atom->author(name => 'Akron');
  $atom->attention('http://sojolicio.us/user/peter');
  $atom->conversation('http://sojolicio.us/conv/34');

  say $atom->to_pretty_xml;
  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <entry xmlns="http://www.w3.org/2005/Atom"
  #        xmlns:ostatus="http://ostatus.org/schema/1.0/">
  #   <author>
  #     <name>Akron</name>
  #   </author>
  #   <link href="http://sojolicio.us/user/peter"
  #         rel="ostatus:attention" />
  #   <link href="http://sojolicio.us/conv/34"
  #         rel="ostatus:conversation" />
  # </entry>


=head1 DESCRIPTION

L<XML::Loy::OStatus> is an extension
for L<XML::Loy::Atom> and provides several functions
for the work with OStatus as described in the
L<specification|http://www.w3.org/community/ostatus/wiki/images/9/93/OStatus_1.0_Draft_2.pdf>.

B<This module is an early release! There may be significant changes in the future.>


=head1 METHODS

L<XML::Loy::OStatus> inherits all methods
from L<XML::Loy> and implements the
following new ones.


=head2 C<attention>

  $entry->attention('http://sojolicio.us/user/peter');

  say $entry->attention;

Add or get attention link.


=head2 C<conversation>

  $entry->conversation('http://sojolicio.us/conv/34');

  say $entry->conversation;

Add or get conversation link.


=head2 C<verb_leave>

  $entry->verb_leave;

Add OStatus C<leave> verb for ActivityStreams.
This needs the L<ActivityStreams|XML::Loy::ActivityStreams> extension.

=head2 C<verb_unfavorite>

  $entry->verb_unfavorite;

Add OStatus C<unfavorite> verb for ActivityStreams.
This needs the L<ActivityStreams|XML::Loy::ActivityStreams> extension.


=head2 C<verb_unfollow>

  $entry->verb_unfollow;

Add OStatus C<unfollow> verb for ActivityStreams.
This needs the L<ActivityStreams|XML::Loy::ActivityStreams> extension.


=head1 DEPENDENCIES

L<Mojolicious>.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016, Nils Diewald.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
