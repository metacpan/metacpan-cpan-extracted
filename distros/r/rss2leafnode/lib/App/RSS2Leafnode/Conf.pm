# Copyright 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde
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

package App::RSS2Leafnode::Conf;
use 5.010;
use strict;
use warnings;

our $VERSION = 79;

{
  package App::RSS2Leafnode::Conf::Tie;
  use Carp;
  sub TIESCALAR {
    my ($class, $field) = @_;
    return bless { field => $field }, $class;
  }
  sub FETCH {
    my ($self) = @_;
    my $r2l = $App::RSS2Leafnode::Conf::r2l
      || croak "Oops, \$App::RSS2Leafnode::Conf::r2l not set";
    return $r2l->{$self->{'field'}};
  }
  sub STORE {
    my ($self, $value) = @_;
    my $r2l = $App::RSS2Leafnode::Conf::r2l
      || croak "Oops, \$App::RSS2Leafnode::Conf::r2l not set";
    return $r2l->{$self->{'field'}} = $value;
  }
}

# config variables

our $r2l;
foreach my $field ('verbose',
                   'render',
                   'render_width',
                   'rss_get_links',
                   'rss_get_comments',
                   'rss_newest_only',
                   'rss_charset_override',
                   'get_icon',
                   'html_charset_from_content',
                   'html_extract_main',
                   'user_agent',

                   # secret variables
                   'msgidextra',
                   'status_filename',
                  ) {
  my $fullvar = __PACKAGE__."::$field";
  no strict 'refs';
  tie ${$fullvar}, 'App::RSS2Leafnode::Conf::Tie', $field;
}

sub fetch_html {
  $r2l->fetch_html(@_);
}
sub fetch_rss {
  $r2l->fetch_rss(@_);
}

1;
__END__

=for stopwords conf rss2leafnode rss leafnode config RSS Leafnode Ryde

=head1 NAME

App::RSS2Leafnode::Conf -- conf file environment for rss2leafnode

=head1 DESCRIPTION

The F<~/rss2leafnode.conf> file is run in package
C<App::RSS2Leafnode::Conf>.  The C<fetch_rss()> and C<fetch_html()>
functions and the config variables operate on an RSS2Leafnode object.

See L<rss2leafnode> for overall operation and L<rss2leafnode/CONFIG OPTIONS>
for the available variables.

=head1 SEE ALSO

L<rss2leafnode>,
L<App::RSS2Leafnode>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/rss2leafnode/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde

RSS2Leafnode is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

RSS2Leafnode is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
RSS2Leafnode.  If not, see L<http://www.gnu.org/licenses/>.

=cut
