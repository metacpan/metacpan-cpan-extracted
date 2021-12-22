package URL::XS;

use 5.026000;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(parse_url split_url_path parse_url_query);

our $VERSION = '0.3.1';

require XSLoader;
XSLoader::load('URL::XS', $VERSION);

1;

__END__

=encoding UTF-8

=head1 NAME

URL::XS - Parsing URLs with zero-copy and no mallocs

=head1 DESCRIPTION

This is a perl binding to libyaurel (simple C library for parsing URLs with zero-copy and no mallocs).
Might parse: url, url paths and url queries.

=head1 SYNOPSIS

  use URL::XS (parse_url split_url_path parse_url_query);

  my $url = 'https://peter:bro@localhost:8989/some/path/to/resource?q1=yes&q2=no&q3=maybe#frag=1';

  # Basic parse
  my $parsed_url = parse_url($url);

  say Dumper $parsed_url;

  # $VAR1 = {
  #  'scheme' => 'https',
  #  'username' => 'peter',
  #  'password' => 'bro',
  #  'host' => 'localhost',
  #  'port' => 8989,
  #  'path' => 'some/path/to/resource'
  #  'query' => 'q1=yes&q2=no&q3=maybe',
  #  'fragment' => 'frag=1',
  # };

  # Parse relative url path
  my $url_path = split_url_path($parsed_url->{path});

  say Dumper $url_path;

  # $VAR1 = [ 'some', 'path', 'to', 'resource' ];

  # Parse url query
  my $url_queries = parse_url_query($parsed_url->{query});

  say Dumper $url_queries;

  # $VAR1 = {
  #  'q1' => 'yes',
  #  'q2' => 'no',
  #  'q3' => 'maybe'
  # };

=head1 FUNCTIONS

=head2 parse_url($url)

Parse absolute URL string:

  scheme ":" ["//"] [user ":" passwd "@"] host [":" port] ["/"] [path] ["?" query] ["#" fragment]

Returns hasref with parsed url data.

=head2 split_url_path($url_path, [$split_separator])

Split relative url path (with optionally separator) with '/' path separator by default.

Returns arrayeref with splitted relative url path.

=head2 parse_url_query($url_query, [$query_separator])

Parse URL query part (with optionally separator). Symbol '&' is a default query separator.

Returns hashref with parsed query.

=head1 SEE ALSO

L<libyuarel |https://github.com/jacketizer/libyuarel>

=head1 AUTHOR

Peter P. Neuromantic <p.brovchenko@protonmail.com>

=head1 LICENSE AND COPYRIGHT

The MIT License (MIT)

Copyright (c) 2021 Peter P. Neuromantic E<lt>p.brovchenko@protonmail.comE<gt>.
All rights reserved.

See LICENSE file for more information.

=cut
