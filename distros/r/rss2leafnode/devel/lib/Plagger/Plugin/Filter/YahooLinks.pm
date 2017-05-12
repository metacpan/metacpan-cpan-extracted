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


package Plagger::Plugin::Filter::YahooLinks;
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
      && $link =~ m{^http://[^/]*yahoo\.com/.*\*(http://.*yahoo\.com.*)$}) {
    $entry->link ($1);
    $context->log(info => "Yahoo link rewritten to " . $entry->link);
  }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::YahooLinks - flatten Yahoo link redirection

=for test_synopsis 1

=for test_synopsis __END__

=head1 SYNOPSIS

 - module: Filter::YahooLinks

=head1 DESCRIPTION

This module flattens a Yahoo redirector link like

    http://au.rd.yahoo.com/finance/news/rss/financenews/*http://au.biz.yahoo.com/071003/30/1fdvx.html

down to

    http://au.biz.yahoo.com/071003/30/1fdvx.html

This is good for de-duplicating because the latter is unique, whereas the
redirector link varies with the originating feed when an article appears in
multiple feeds.

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
