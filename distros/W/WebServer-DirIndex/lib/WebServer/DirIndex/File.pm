use strict;
use warnings;
use Feature::Compat::Class;
use WebServer::DirIndex::HTML;

our $VERSION = '0.1.2';

class WebServer::DirIndex::File {

  use HTML::Escape qw(escape_html);

  my %ICON_MAP = (
    'directory'                                                                    => 'fa-solid fa-folder',
    ''                                                                             => 'fa-solid fa-arrow-up',
    'text/plain'                                                                   => 'fa-solid fa-file-lines',
    'text/html'                                                                    => 'fa-solid fa-file-code',
    'text/css'                                                                     => 'fa-solid fa-file-code',
    'text/csv'                                                                     => 'fa-solid fa-file-csv',
    'text/javascript'                                                              => 'fa-solid fa-file-code',
    'application/pdf'                                                              => 'fa-solid fa-file-pdf',
    'application/msword'                                                           => 'fa-solid fa-file-word',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'     => 'fa-solid fa-file-word',
    'application/vnd.ms-excel'                                                     => 'fa-solid fa-file-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'           => 'fa-solid fa-file-excel',
    'application/vnd.ms-powerpoint'                                                => 'fa-solid fa-file-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation'   => 'fa-solid fa-file-powerpoint',
    'application/javascript'                                                       => 'fa-solid fa-file-code',
    'application/json'                                                             => 'fa-solid fa-file-code',
    'application/xml'                                                              => 'fa-solid fa-file-code',
    'application/zip'                                                              => 'fa-solid fa-file-zipper',
    'application/x-tar'                                                            => 'fa-solid fa-file-zipper',
    'application/gzip'                                                             => 'fa-solid fa-file-zipper',
    'application/x-bzip2'                                                          => 'fa-solid fa-file-zipper',
    'application/x-rar-compressed'                                                 => 'fa-solid fa-file-zipper',
  );

  my %ICON_PREFIX_MAP = (
    'image/' => 'fa-solid fa-file-image',
    'audio/' => 'fa-solid fa-file-audio',
    'video/' => 'fa-solid fa-file-video',
    'text/'  => 'fa-solid fa-file-lines',
  );

  sub _icon_class {
    my ($mime_type) = @_;
    return $ICON_MAP{$mime_type} if exists $ICON_MAP{$mime_type};
    for my $prefix (keys %ICON_PREFIX_MAP) {
      return $ICON_PREFIX_MAP{$prefix} if index($mime_type, $prefix) == 0;
    }
    return 'fa-solid fa-file';
  }

  field $url        :param :reader;
  field $name       :param :reader;
  field $size       :param :reader;
  field $mime_type  :param :reader;
  field $mtime      :param :reader;
  field $icon       :param :reader = undef;
  field $icons      :param = 0;
  field $html_class :param = 'WebServer::DirIndex::HTML';
  field $_html_obj = $html_class->new(icons => $icons);

  ADJUST {
    if ($icons && !defined $icon) {
      $icon = _icon_class($mime_type);
    }
  }

  method to_html {
    if (defined $icon) {
      return sprintf $_html_obj->file_html_icons,
        map { escape_html($_) }
          ($icon, $url, $name, $size, $mime_type, $mtime);
    }
    return sprintf $_html_obj->file_html,
      map { escape_html($_) }
        ($url, $name, $size, $mime_type, $mtime);
  }

  sub parent_dir {
    my ($class, %args) = @_;
    return WebServer::DirIndex::File->new(
      url       => '../',
      name      => 'Parent Directory',
      size      => '',
      mime_type => '',
      mtime     => '',
      %args,
    );
  }
}

1;

__END__

=head1 NAME

WebServer::DirIndex::File - A file entry in a directory index

=head1 SYNOPSIS

  use WebServer::DirIndex::File;

  my $file = WebServer::DirIndex::File->new(
    url       => 'file.txt',
    name      => 'file.txt',
    size      => 1234,
    mime_type => 'text/plain',
    mtime     => 'Thu, 01 Jan 2026 00:00:00 GMT',
  );

  my $parent = WebServer::DirIndex::File->parent_dir;

=head1 DESCRIPTION

This module represents a single file entry in a directory index. It stores
the five pieces of information needed to render a directory listing row.

=head1 CONSTRUCTOR

=over 4

=item new(%args)

Creates a new C<WebServer::DirIndex::File> object. Accepts the following
named parameters:

=over 4

=item url

The URL for the file (possibly URI-escaped).

=item name

The display name of the file.

=item size

The file size in bytes, or an empty string for directories and the parent
entry.

=item mime_type

The MIME type of the file, C<'directory'> for directories, or an empty
string for the parent entry.

=item mtime

The last-modified time as a formatted string, or an empty string for the
parent entry.

=item icon

Optional. The Font Awesome CSS class string used to render an icon for this
entry (e.g. C<'fa-solid fa-file-pdf'>). Defaults to C<undef>, which causes
C<to_html> to use the icon-less C<file_html> template.

=item icons

Optional. When true, the icon for this entry is automatically derived from
C<mime_type> using a built-in mapping of MIME types to Font Awesome 6 CSS
classes. Defaults to false. Ignored if C<icon> is supplied explicitly.

=item html_class

Optional. The class name to use for HTML templates. Defaults to
C<WebServer::DirIndex::HTML>. Must provide a C<file_html> method that
returns a C<sprintf> format string with five C<%s> placeholders
(url, name, size, mime_type, mtime).

=back

=item parent_dir

A class method that returns a C<WebServer::DirIndex::File> object
representing the parent directory entry (C<../>).

=back

=head1 METHODS

=over 4

=item url

Returns the URL of the file.

=item name

Returns the display name of the file.

=item size

Returns the file size.

=item mime_type

Returns the MIME type.

=item mtime

Returns the last-modified time string.

=item icon

Returns the Font Awesome CSS class string for the icon, or C<undef> if icons
are not enabled.

=item to_html

Returns an HTML table row string representing this file entry, with all
fields HTML-escaped, ready for inclusion in a directory index page.

=back

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

=item L<WebServer::DirIndex::HTML>

=back

=cut
