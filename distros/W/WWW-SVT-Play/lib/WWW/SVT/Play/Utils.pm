package WWW::SVT::Play::Utils;

# Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use warnings FATAL => 'all';
use strict;
require Exporter;
our @ISA = 'Exporter';
our @EXPORT_OK = qw(playertype_map protocol_map);
our $VERSION = 0.12;

=head1 NAME

WWW::SVT::Play::Utils, helper functions for WWW::SVT::Play

=head1 DESRIPTION

This module contains some helper functions for use in other parts
of the WWW::SVT::Play application.

=head1 SUBROUTINES

=cut

# The translation map for supported
my %playertype_map = (
	'flash' => 'http',
	'ios'   => 'hls',
);
my %protocol_map = reverse %playertype_map;

=head2 playertype_map

Given an SVT Play internal name for a protocol (or playerType),
return the corresponding protocol name for it. E.g., flash gives
you 'hds'.

B<Note:> For the internal format "flash", it can be either HDS or
RTMP. You can determine this by looking at the protocol scheme
used by the URL. If it's RTMP, it's RTMP (duh), and if it's HTTP,
it's HDS. This function will return 'hds' either way.

=cut

sub playertype_map {
	my $type = lc(shift);
	return $playertype_map{$type};
}

=head2 protocol_map

Given a protocol nicename (e.g. HLS), return the SVT Play
internal name (for HLS, it's "ios"). That is, the opposite of
what playertype_map is doing.

=cut

sub protocol_map {
	my $type = lc(shift);
	return $protocol_map{$type};
}

=head1 COPYRIGHT

Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
