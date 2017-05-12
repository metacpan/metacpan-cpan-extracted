package XML::API::RSS;
use strict;
use warnings;
use 5.006;
use base qw(XML::API);

our $VERSION = '0.30';

my $xsd = {};

sub _doctype {
    return '';
}

sub _xsd {
    return $xsd;
}

sub _root_element {
    return 'rss';
}

sub _root_attrs {
    return { version => '2.0' };
}

sub _content_type {
    return 'application/rss+xml';
}

1;

__END__


=head1 NAME

XML::API::RSS - RSS feed generation through an object API

=head1 VERSION

0.30 (2016-04-11)

=head1 SYNOPSIS

  use XML::API;
  my $x = XML::API->new(doctype => 'rss');
  
  $x->rss_open;
  $x->channel_open;

  $x->title('Liftoff News');
  $x->link('http://liftoff.msfc.nasa.gov/');
  $x->description('Liftoff to Space Exploration.');
  $x->language('en-us');
  $x->pubDate('Tue, 10 Jun 2003 04:00:00 GMT');
  $x->lastBuildDate('Tue, 10 Jun 2003 09:41:01 GMT');
  $x->docs('http://blogs.law.harvard.edu/tech/rss');
  $x->generator('Weblog Editor 2.0');
  $x->managingEditor('editor@example.com');
  $x->webMaster('webmaster@example.com');

  $x->item_open;
  $x->title('Star City');
  $x->link('http://liftoff.msfc.nasa.gov/news/2003/news-starcity.asp');
  $x->description('A description of sorts.');
  $x->pubDate('Tue, 03 Jun 2003 09:39:21 GMT');
  $x->guid('http://liftoff.msfc.nasa.gov/2003/06/03.html#item573');
  $x->item_close;

  $x->channel_close;
  $x->rss_close;

  print $x;

=head1 DESCRIPTION

B<XML::API::RSS> is a perl object class for creating RSS documents.
This module is not normally used directly, but automatically required
by L<XML::API> as needed. See that class for documentation instead.

=head1 SEE ALSO

L<XML::API>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008,2015,2016 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=cut

