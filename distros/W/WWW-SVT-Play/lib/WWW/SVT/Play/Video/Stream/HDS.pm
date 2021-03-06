package WWW::SVT::Play::Video::Stream::HDS;

# Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=head1 NAME

WWW::SVT::Play::Video::Stream::HDS, HDS class representing a stream

=head1 SYNOPSIS

 use WWW::SVT::Play::Video;

 my $svtp = WWW::SVT::Play::Video->new($url);
 my $stream = $svtp->stream(protocol => 'HDS');

=head1 DESCRIPTION

=cut

use warnings FATAL => 'all';
use strict;
use parent 'WWW::SVT::Play::Video::Stream';

our $VERSION = 0.12;
use Carp;

=head2 is_hds

Is stream using HDS protocol? Yes.

=cut

sub is_hds { 1 }

=head1 COPYRIGHT

Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
