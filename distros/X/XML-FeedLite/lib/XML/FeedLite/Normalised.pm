#########
# Author:        rmp@psyphi.net
# Maintainer:    rmp@psyphi.net
# Created:       2006-06-08
# Last Modified: $Date: 2009/01/09 14:38:54 $
# Id:            $Id: Normalised.pm,v 1.4 2009/01/09 14:38:54 zerojinx Exp $
# Source:        $Source: /cvsroot/xml-feedlite/xml-feedlite/lib/XML/FeedLite/Normalised.pm,v $
# $HeadURL$
#
package XML::FeedLite::Normalised;
use strict;
use warnings;
use base qw(XML::FeedLite);

our $VERSION  = do { my @r = (q$Revision: 1.4 $ =~ /\d+/smxg); sprintf '%d.'.'%03d' x $#r, @r };

sub entries {
  my ($self, @args) = @_;
  my $rawdata = $self->SUPER::entries(@args);

  for my $feed (keys %{$self->{'format'}}) {
    my $format = $self->{'format'}->{$feed};

    if($format !~ /^(atom|rss)/smx) {
      next;
    }

    my $method = "process_$format";

    $self->$method($rawdata->{$feed});
  }
  return $rawdata;
}

sub process_rss {
  my ($self, $feeddata) = @_;

  for my $entry (@{$feeddata}) {
    %{$entry} = (
		 'title'   => $entry->{'title'}->[0]->{'content'}       ||q(),
		 'content' => $entry->{'description'}->[0]->{'content'} ||q(),
		 'author'  => $entry->{'dc:creator'}->[0]->{'content'}  ||q(),
		 'date'    => $entry->{'dc:date'}->[0]->{'content'}     ||q(),
		 'link'    => [map { $_->{'content'}||q() } @{$entry->{'link'}}],
		);
  }
  return;
}

sub process_atom {
  my ($self, $feeddata) = @_;

  for my $entry (@{$feeddata}) {
    %{$entry} = (
		 'title'   => $entry->{'title'}->[0]->{'content'}   ||q(),
		 'content' => $entry->{'content'}->[0]->{'content'} ||q(),
		 'author'  => $entry->{'author'}->[0]->{'content'}  ||q(),
		 'date'    => $entry->{'updated'}->[0]->{'content'} ||q(),
		 'link'    => [map { $_->{'href'}||q() } @{$entry->{'link'}}],
		);
  }
  return;
}

1;

__END__

=head1 NAME

XML::FeedLite::Normalised

=head1 VERSION

$Revision: 1.4 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 entries - Data structure of processed feed entries

  my $hrEntries = $xfln->entries();

=head2 process_rss - Processor for RSS 1.0-format entries

  Used by X::FL::N::entries

  $xfln->process_rss([...]);

=head2 process_atom - Processor for Atom-format entries

  Used by X::FL::N::entries

  $xfln->process_atom([...]);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rmp@psyphi.netE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2005 by Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
