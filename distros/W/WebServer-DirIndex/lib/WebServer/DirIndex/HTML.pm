use strict;
use warnings;
use Feature::Compat::Class;

class WebServer::DirIndex::HTML v0.1.1 {

  field $icons :param = 0;

  field $_file_html = <<'FILE';
  <tr>
    <td class='name'><a href='%s'>%s</a></td>
    <td class='size'>%s</td>
    <td class='type'>%s</td>
    <td class='mtime'>%s</td>
  </tr>
FILE

  field $file_html_icons :reader = <<'FILE';
  <tr>
    <td class='icon'><i class='%s'></i></td>
    <td class='name'><a href='%s'>%s</a></td>
    <td class='size'>%s</td>
    <td class='type'>%s</td>
    <td class='mtime'>%s</td>
  </tr>
FILE

  field $_dir_html = <<'DIR';
<html>
  <head>
    <title>%s</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <style type='text/css'>
%s
    </style>
  </head>
  <body>
    <h1>%s</h1>
    <hr />
    <table>
      <thead>
        <tr>
          <th class='name'>Name</th>
          <th class='size'>Size</th>
          <th class='type'>Type</th>
          <th class='mtime'>Last Modified</th>
        </tr>
      </thead>
      <tbody>
%s
      </tbody>
    </table>
    <hr />
  </body>
</html>
DIR

  field $dir_html_icons :reader = <<'DIR';
<html>
  <head>
    <title>%s</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css" />
    <style type='text/css'>
%s
    </style>
  </head>
  <body>
    <h1>%s</h1>
    <hr />
    <table>
      <thead>
        <tr>
          <th class='icon'></th>
          <th class='name'>Name</th>
          <th class='size'>Size</th>
          <th class='type'>Type</th>
          <th class='mtime'>Last Modified</th>
        </tr>
      </thead>
      <tbody>
%s
      </tbody>
    </table>
    <hr />
  </body>
</html>
DIR

  method file_html { return $icons ? $file_html_icons : $_file_html }
  method dir_html  { return $icons ? $dir_html_icons  : $_dir_html  }
}

1;

__END__

=head1 NAME

WebServer::DirIndex::HTML - HTML rendering for directory index pages

=head1 SYNOPSIS

  use WebServer::DirIndex::HTML;

  my $html      = WebServer::DirIndex::HTML->new;
  my $file_tmpl = $html->file_html;   # non-icon template
  my $dir_tmpl  = $html->dir_html;

  my $html_icons = WebServer::DirIndex::HTML->new(icons => 1);
  my $file_tmpl_icons = $html_icons->file_html;  # icon template
  my $dir_tmpl_icons  = $html_icons->dir_html;

=head1 DESCRIPTION

This module provides HTML template strings used to render a directory
index page. The actual rendering is performed by L<WebServer::DirIndex>.

=head1 CONSTRUCTOR

=over 4

=item new(%args)

Creates a new C<WebServer::DirIndex::HTML> object. Accepts the following
optional named parameter:

=over 4

=item icons

If true, C<file_html> and C<dir_html> return icon-aware templates (with a
Font Awesome icon column). Defaults to false.

=back

=back

=head1 METHODS

=over 4

=item file_html

Returns a C<sprintf> format string used to render a single file row.
When C<icons> is true, returns the icon-aware template (6 C<%s> placeholders:
C<icon_class>, C<url>, C<name>, C<size>, C<mime_type>, C<mtime>).
Otherwise returns the standard template (5 C<%s> placeholders:
C<url>, C<name>, C<size>, C<mime_type>, C<mtime>).

=item dir_html

Returns a C<sprintf> format string used to render the full directory
index page. When C<icons> is true, returns the icon-aware template
(with Font Awesome CDN link and icon column header). Otherwise returns
the standard template. Both variants have 4 C<%s> placeholders:
page C<title>, inline C<css>, page C<heading>, C<file rows>.

=item file_html_icons

Returns the icon-aware C<sprintf> format string for a single file row,
regardless of the C<icons> field. Contains 6 C<%s> placeholders:
C<icon_class>, C<url>, C<name>, C<size>, C<mime_type>, C<mtime>.

=item dir_html_icons

Returns the icon-aware C<sprintf> format string for the full directory
index page, regardless of the C<icons> field. Includes a Font Awesome CDN
link and icon column header. Contains 4 C<%s> placeholders:
page C<title>, inline C<css>, page C<heading>, C<file rows>.

=back

=head1 SUBCLASSING

You can subclass this module to provide custom HTML templates. Override
C<file_html> and/or C<dir_html> by declaring new fields with the C<:reader>
attribute in your subclass.

Pass your subclass name as the C<html_class> parameter when constructing
L<WebServer::DirIndex> or L<WebServer::DirIndex::File>. The C<icons>
parameter is passed to the constructor automatically.

=head1 AUTHOR

Dave Cross E<lt>dave@perlhacks.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 Magnum Solutions Limited. All rights reserved.

=head1 LICENCE

This code is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item L<WebServer::DirIndex>

=item L<WebServer::DirIndex::CSS>

=item L<Plack::App::DirectoryIndex>

=back

=cut
