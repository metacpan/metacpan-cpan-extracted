package Web::Library;
use MooseX::Singleton;
use Params::Validate qw(:all);
use Web::Library::Item;
our $VERSION = '0.06';
has 'libraries' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Web::Library::Item]',
    default => sub { [] },
    handles => {
        all_libraries => 'elements',
        push_library  => 'push',
        reset         => 'clear',
    },
);

sub mount_library {
    my $self = shift;
    my %args = validate(@_, { name => 1, version => 0 });
    $self->push_library(Web::Library::Item->new(%args));
}

sub include_paths {
    my $self = shift;
    my @paths = map { $_->include_path } $self->all_libraries;
    wantarray ? @paths : \@paths;
}

sub library_map {
    my ($self, $code, @libs) = @_;
    my %lib_by_name = map { $_->name => $_ } $self->all_libraries;
    my @result;
    for my $lib (@libs) {
        my $item = $lib_by_name{$lib} // die "unknown library [$lib]";
        local $_ = $item;    # so you can use $_ as well as $_[0] in $code
        push @result, $code->($item);
    }
    @result;
}

sub css_assets_for {
    my ($self, @libs) = @_;
    $self->library_map(sub { $_->css_assets }, @libs);
}

sub javascript_assets_for {
    my ($self, @libs) = @_;
    $self->library_map(sub { $_->javascript_assets }, @libs);
}

sub css_link_tags_for {
    my ($self, @libs) = @_;
    join "\n",
      map { qq!<link href="$_" rel="stylesheet">! }
      $self->css_assets_for(@libs);
}

sub script_tags_for {
    my ($self, @libs) = @_;
    join "\n",
      map { qq!<script src="$_" type="text/javascript"></script>! }
      $self->javascript_assets_for(@libs);
}
1;

=pod

=head1 NAME

Web::Library - Manager for wrappers around client-side libraries

=head1 SYNOPSIS

    # in your Catalyst application:

    my $library_manager = Web::Library->instance;

    $library_manager->mount_library({ name => 'jQuery' });
    $library_manager->mount_library(
        { name => 'Bootstrap', version => '2.3.0' });

    __PACKAGE__->config(
        'Plugin::Static::Simple' => {
            include_path => [ $library_manager->include_paths ] },
        ...
    );

    # in an HTML template

    <head>
        ...
        [% web_library.css_link_tags_for('Bootstrap', 'jQuery') %]
    </head>
    <body>
        ...
        [% web_library.script_tags_for('Bootstrap', 'jQuery') %]
    </body>

=head1 DESCRIPTION

There are well-established ways for web applications to manage server-side
dependencies, like C<Makefile.PL> or C<cpanfile> - but what about client-side
dependencies?

So you develop and maintain a number of web applications, and all of them use
some client-side libraries like jQuery or Twitter Bootstrap or Underscore.js.
You have to copy the relevant JavaScript, CSS and image files to a directory
containing static files for each web application. This involves quite a bit of
copying around and version maintenance. Web::Library can help you.

The idea behind Web::Library and its related distributions is that client-side
libraries are installed as shared files of standard CPAN distributions.
Web::Library itself is a manager for those libraries. A web application that
wishes to use one or more client-side libraries can tell Web::Library to
include either the latest or a specific version of those libraries. These
managed libraries can then be used as static files with web application
frameworks. In the case of L<Catalyst> you might use
L<Catalyst::Plugin::Static::Simple> as shown in the synopsis.

Web::Library is a singleton object, so you can add client-side libraries in
different parts of your application. For example, you might have common
librares that are included in all of your web applications, but then also want
to manage application-specific libraries.

Only client-side libraries whose license permits redistribution can be managed
this way. Forunately, most, if not all, popular client-side libraries have such
permissive licenses.

=head1 METHODS

=over 4

=item instance

Returns the singleton Web::Library object that manages all client-side libraries.

=item mount_library

Adds a specific version of a client-side library to the list of managed
libraries. Takes a hashref of named parameters. Valid parameters are:

=over 4

=item name

The name of the client-side library. The manager will try to load the
C<Web::Library::$name> class. For example, L<Web::Library::Bootstrap> is a
distribution wrapper for Twitter Bootstrap.

=item version

A distribution wrapper will contain various versions of the wrapped client-side
library. Using this parameter you can specify the version you want. Refer to
the relevant distribution's documentation to see which versions are available.
This parameter is optional; if omitted, the latest version is used.

=back

=item include_paths

Client-side library files are installed as shared files as described in
L<File::ShareDir>. The C<include_paths> method returns the absolute paths to
shared directories for all managed libraries.

Returns a list in list context and an array reference in scalar context.

=item reset

Clears all mounted libraries.

=back

=head2 ASSET-RELATED METHODS

Web::Library can also help you with including a library's CSS and JavaScript
files in the web page templates.

If you expose an instance of Web::Library to your templates, you can add the
relevant C<< <link> >> and C<< <script> >> tags as shown in the synopsis.

This is convenient, but it's only intended for some basic default set of CSS
and JavaScript files. For example, if the library provides responsive versions
or other customized versions, you can still use them by writing the HTML tags
manually. A list of which files are included for each version is found in the
documentation of the wrapper distributions like L<Web::Library::Bootstrap>.

=over 4

=item css_assets_for

Takes a list of library names like those you give to C<mount_library()> and
returns a list of CSS files for the specific versions of the mounted libraries.

For example:

    $manager->css_link_tags_for('Bootstrap', 'jQueryUI');

might return:

    qw(/css/bootstrap.min.css /css/jquery-ui.min.css)

=item javascript_assets_for

Takes a list of library names like those you give to C<mount_library()> and
returns a list of JavaScript files for the specific versions of the mounted
libraries.

For example:

    $manager->javascript_assets_for('Bootstrap', 'jQueryUI');

might return:

    qw(/js/bootstrap.min.js /js/jquery-ui.min.js)

=item css_link_tags_for

Takes a list of library names like those you give to C<mount_library()> and
returns a string containing C<< <link> >> tags for the CSS files for the
specific versions of the mounted libraries.

For example:

    $manager->css_link_tags_for('Bootstrap', 'jQueryUI');

might return:

    <link href="/css/bootstrap.min.css" rel="stylesheet">
    <link href="/css/jquery-ui.min.css" rel="stylesheet">

=item script_tags_for

Takes a list of library names like those you give to C<mount_library()> and
returns a string containing C<< <script> >> tags for the JavaScript files for
the specific versions of the mounted libraries.

For example:

    $manager->script_tags_for('Bootstrap', 'jQueryUI');

might return:

    <script src="/js/bootstrap.min.js" type="text/javascript></script>
    <script src="/js/jquery-ui.min.js" type="text/javascript></script>

=back

=head1 WRITING YOUR OWN LIBRARY DISTRIBUTION

If you want to write a distribution wrapper for a client-side library, it will
be easiest if you look at existing library distributions such as the ones
mentioned below and follow their example.

Make sure that the library's license allows you to redistribute it and provide
a link to the library's web site and include other relevant attribution.

Only add the files that are actually necessary - the bare minimum of CSS,
JavaScript and image files.

=head1 SEE ALSO

=over 4

=item L<Web::Library::jQuery>

=item L<Web::Library::jQueryUI>

=item L<Web::Library::Bootstrap>

=item L<Web::Library::DataTables>

=item L<Web::Library::UnderscoreJS>

=back

=head1 AUTHORS

The following person is the author of all the files provided in
this distribution unless explicitly noted otherwise.

Marcel Gruenauer C<< <marcel@cpan.org> >>, L<http://marcelgruenauer.com>

=head1 COPYRIGHT AND LICENSE

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

This software is copyright (c) 2013 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

