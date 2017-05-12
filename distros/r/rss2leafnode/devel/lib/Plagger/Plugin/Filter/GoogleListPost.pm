# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.


package Plagger::Plugin::Filter::GoogleListPost;
use 5.006;
use strict;
use warnings;
use base 'Plagger::Plugin';

our $VERSION = 79;

sub register {
  my ($self, $context) = @_;
  $context->register_hook ($self, 'update.entry.fixup' => \&fixup);
}

sub fixup {
  my ($self, $context, $args) = @_;
  my $entry = $args->{entry};

  my $link = $entry->link;
  if (defined $link
      && $link =~ m{^http://groups\.google\.com/group/([^/]+)/msg/}) {
    ## no critic (RequireInterpolationOfMetachars)
    $entry->meta->{'mail_headers'}->{'List-Post:'} = $1 . '@googlegroups.com';
    $context->log(info => "Google List-Post: " . $entry->meta->{'List-Post'});
  }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::GoogleListPost - List-Post header for Google list links

=for test_synopsis 1

=for test_synopsis __END__

=head1 SYNOPSIS

 - module: Filter::GoogleListPost

=head1 DESCRIPTION

This module sets up a List-Post header for use by Publish::Rnews (or
similar) on entries which are Google Groups mailing list messages.  Such
entries are identified from their link like

    http://groups.google.com/group/cfcdev/msg/445d4ccfdabf086b

which becomes

    List-Post: cfcdev@googlegroups.com

Such a List-Post might let your mailer or news reader send a "followup to
mailing list" to the right place.  The link itself is left pointing to the
message.

=head1 SEE ALSO

L<Plagger>

=head1 HOME PAGE

http://user42.tuxfamily.org/rss2leafnode/index.html

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde

RSS2Leafnode is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

RSS2Leafnode is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

=cut
