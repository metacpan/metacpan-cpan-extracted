use strict;
use warnings;
use Feature::Compat::Class;

our $VERSION = '0.1.2';

class WebServer::DirIndex::CSS {

  field $pretty :param = 0;

  field $standard_css :reader = <<CSS;
table {
  width: 100%;
}
.icon {
  width: 1.5em;
  text-align: center;
}
.name {
  text-align: left;
}
.size, .mtime {
  text-align: right;
}
.type {
  width: 11em;
}
.mtime {
  width: 15em;
}
CSS

  field $pretty_css :reader = <<CSS;
body {
  color: #000;
  background-color: #fff; 
  font-family: Calibri, Candara, Segoe, Segoe UI, Helvetica Neue, Helvetica, Optima, Arial, sans-serif;
  font-size: normal 1em sans-serif;
  text-align: center;
  padding: 0;
  margin: 0;
}

h2 {
 font-size: 2.000em;
 font-weight: 700;
}

table {
  width: 90%;
  margin: 3em;
  border: 1px solid #aaa;
  border-collapse: collapse;
  background-color: #eee;
}

thead {
  background-color: #bbb;
  font-weight: 700;
  font-size: 1.300em;
}

td, th {
  padding: 1em;
  text-align: left;
  border-bottom: 1px solid #999999;
  color: #000;
}

tr:nth-child(even) {
  background: #ccc;
}

.icon {
  width: 1.5em;
  text-align: center;
}

.size {
  text-align: right;
  padding-right: 1.700em;
}

a:link {
  font-size: 1.200em;
  font-weight: 500;
  color: #000;
  text-decoration: none;
}

a:link:hover {
  text-decoration: underline;
}

a:visited {
  font-size: 1.200em;
  font-weight: 500;
  color: #301934;
  text-decoration: none;
}
CSS

  method css {
    return $pretty ? $pretty_css : $standard_css;
  }
}

1;

__END__

=head1 NAME

WebServer::DirIndex::CSS - CSS stylesheets for directory index pages

=head1 SYNOPSIS

  use WebServer::DirIndex::CSS;

  my $css = WebServer::DirIndex::CSS->new->css;           # standard CSS
  my $css = WebServer::DirIndex::CSS->new(pretty => 1)->css;  # pretty CSS

=head1 DESCRIPTION

This module provides CSS stylesheets that can be used to style
directory index pages served by web servers.

=head1 CONSTRUCTOR

=over 4

=item new(%args)

Creates a new C<WebServer::DirIndex::CSS> object. Accepts the following
optional named parameter:

=over 4

=item pretty

If true, the C<css> method will return an enhanced stylesheet for a more
attractive appearance. Defaults to false.

=back

=back

=head1 METHODS

=over 4

=item css

Returns a CSS stylesheet suitable for directory listing pages. If the
C<pretty> attribute is true, returns an enhanced stylesheet for a more
attractive appearance; otherwise returns a minimal standard stylesheet.

=item standard_css

Returns the minimal standard CSS stylesheet string.

=item pretty_css

Returns the enhanced pretty CSS stylesheet string.

=back

=head1 SUBCLASSING

You can subclass this module to provide custom stylesheets. Override
C<standard_css>, C<pretty_css>, or both by declaring new fields with the
C<:reader> attribute, and override the C<css> method if you need different
selection logic.

Pass your subclass name as the C<css_class> parameter when constructing
L<WebServer::DirIndex>.

=head1 AUTHOR

Dave Cross E<lt>dave@perlhacks.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 Magnum Solutions Limited. All rights reserved.

=head1 LICENCE

This code is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item L<Plack::App::DirectoryIndex>

=back

=cut
