use strict;
use warnings;
use Feature::Compat::Class;

class WebServer::DirIndex {

  our $VERSION = '0.1.3';

  use Path::Tiny;
  use HTTP::Date;
  use HTML::Escape qw(escape_html);
  use MIME::Types;
  use URI::Escape;
  use WebServer::DirIndex::CSS;
  use WebServer::DirIndex::File;
  use WebServer::DirIndex::HTML;

  my $mime_types = MIME::Types->new;

  field $dir        :param;
  field $dir_url    :param;
  field $icons      :param = undef;
  field $pretty     :param = 0;
  field $html_class :param = 'WebServer::DirIndex::HTML';
  field $css_class  :param = 'WebServer::DirIndex::CSS';
  field $_html_obj;
  field $_css_obj;
  field @files;

  ADJUST {
    $icons = 1 if !defined($icons) && $pretty;  # pretty implies icons when unset
    $icons //= 1;                                 # default to enabled otherwise
    $_html_obj = $html_class->new(icons => $icons);
    $_css_obj  = $css_class->new(pretty => $pretty);
    @files = ( WebServer::DirIndex::File->parent_dir(
      html_class => $html_class,
      icons      => $icons,
    ) );

    my @children = map { $_->basename } path($dir)->children;

    for my $basename (sort { $a cmp $b } @children) {
      my $file = "$dir/$basename";
      my $url  = $dir_url . $basename;

      my $is_dir = -d $file;
      my @stat   = stat $file;

      $url = join '/', map { uri_escape($_) } split m{/}, $url;

      if ($is_dir) {
        $basename .= '/';
        $url      .= '/';
      }

      my $type_obj  = $is_dir ? undef : $mime_types->mimeTypeOf($file);
      my $mime_type = $is_dir
        ? 'directory'
        : ($type_obj ? $type_obj->type : 'text/plain');

      push @files, WebServer::DirIndex::File->new(
        url        => $url,
        name       => $basename,
        size       => $stat[7],
        mime_type  => $mime_type,
        mtime      => HTTP::Date::time2str($stat[9]),
        html_class => $html_class,
        icons      => $icons,
      );
    }
  }

  method files { return @files }

  method to_html ($path_info) {
    my $path = escape_html("Index of $path_info");
    my $files_html = join "\n", map { $_->to_html } @files;
    my $css = $_css_obj->css;
    return sprintf $_html_obj->dir_html, $path, $css, $path, $files_html;
  }
}

1;

__END__

=head1 NAME

WebServer::DirIndex - Directory index data for web server listings

=head1 SYNOPSIS

  use WebServer::DirIndex;

  my $di = WebServer::DirIndex->new(
    dir     => '/path/to/dir',
    dir_url => '/some/dir/',
    icons   => 1,          # optional, defaults to 1 (enabled)
    pretty  => 0,          # optional, defaults to 0 (standard CSS)
  );

  # Get the list of file entries
  my @files = $di->files;

  # Generate an HTML directory index page
  my $html = $di->to_html('/some/dir/');

=head1 DESCRIPTION

This module reads a filesystem directory and builds the data required
to render a directory index page for a web server. It provides access
to the list of file entries and can generate an HTML page via
L<WebServer::DirIndex::HTML>.

=head1 CONSTRUCTOR

=over 4

=item new(%args)

Creates a new C<WebServer::DirIndex> object and reads the directory.
Accepts the following named parameters:

=over 4

=item dir

The filesystem path to the directory to index.

=item dir_url

The URL path corresponding to the directory (e.g. C</some/dir/>).
Used to construct file URLs.

=item icons

Optional. When true, each file row includes a Font Awesome icon chosen based on
the file's MIME type, and the rendered page links to the Font Awesome CDN
stylesheet. Set to a false value to disable icons entirely. If not supplied (or
explicitly set to C<undef>), icons are enabled when C<pretty> is true and
enabled by default otherwise. Pass C<0> to explicitly disable icons even when
C<pretty> is true.

=item pretty

Optional. When true, C<to_html> uses an enhanced CSS stylesheet for a more
attractive appearance. Defaults to false.

=item html_class

Optional. The class name to use for HTML templates. Defaults to
C<WebServer::DirIndex::HTML>. Must provide C<file_html> and C<dir_html>
methods that return C<sprintf> format strings.

=item css_class

Optional. The class name to use for CSS stylesheets. Defaults to
C<WebServer::DirIndex::CSS>. Must provide a C<new(pretty =E<gt> $bool)>
constructor and a C<css> method that returns a stylesheet string.

=back

=back

=head1 METHODS

=over 4

=item files

Returns the list of file entries for the directory. Each entry is a
L<WebServer::DirIndex::File> object. The first entry is always the
parent directory (C<../>).

=item to_html($path_info)

Generates and returns a complete HTML directory index page using
L<WebServer::DirIndex::HTML> for templates and L<WebServer::DirIndex::CSS>
for styling. C<$path_info> is the request path info used as the page title
and heading. The C<pretty> and C<icons> options are set at construction time.

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

=item L<WebServer::DirIndex::File>

=item L<WebServer::DirIndex::HTML>

=item L<WebServer::DirIndex::CSS>

=item L<Plack::App::DirectoryIndex>

=back

=cut
