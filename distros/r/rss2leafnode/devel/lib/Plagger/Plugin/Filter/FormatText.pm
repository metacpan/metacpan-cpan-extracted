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


package Plagger::Plugin::Filter::FormatText;
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
  my $body = $entry->body || return;

  my $conf = $self->conf;
  my $width = $conf->{'width'} || 60;

  my $text;
  if ($body->is_html) {
    $text = $body->html;
    if ($text !~ /<html>/i) {
      $text =
        "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">
<html><body>$text</body></html>";
    }
    my $class = $conf->{'class'} || 'HTML::FormatText';
    require Module::Load;
    Module::Load::load ($class);
    $text = $class->format_string (leftmargin => 0,
                                   rightmargin => $width);

  } else {
    require Text::Wrap;
    local $Text::Wrap::huge = 'overflow';
    local $Text::Wrap::columns = $width;
    $text = Text::Wrap::wrap ('', '', split /\n/, $body->plaintext);
  }
  $body = Plagger::Text->new (type => 'text', data => $text);
  $entry->body ($body);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::FormatText - format or line wrap text parts

=for test_synopsis 1

=for test_synopsis __END__

=head1 SYNOPSIS

 - module: Filter::FormatText

=head1 DESCRIPTION

...

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
