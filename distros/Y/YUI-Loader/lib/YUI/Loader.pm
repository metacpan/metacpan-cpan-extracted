package YUI::Loader;
BEGIN {
  $YUI::Loader::VERSION = '0.071';
}
# ABSTRACT: Load (and cache) the Yahoo JavaScript YUI framework

use warnings;
use strict;


use constant LATEST_YUI_VERSION => "2.8.1";

use Moose;

use YUI::Loader::Carp;
use YUI::Loader::Catalog;
use HTML::Declare qw/LINK SCRIPT/;

has catalog => qw/is ro required 1 isa YUI::Loader::Catalog lazy 1/, default => sub { shift->source->catalog };
has manifest => qw/is ro required 1 isa YUI::Loader::Manifest lazy 1/, handles => [qw/include exclude clear select parse schedule/], default => sub {
    my $self = shift;
    require YUI::Loader::Manifest;
    return YUI::Loader::Manifest->new(catalog => $self->catalog, loader => $self);
};
has list => qw/is ro required 1 isa YUI::Loader::List lazy 1/, default => sub {
    my $self = shift;
    require YUI::Loader::List;
    return YUI::Loader::List->new(loader => $self);
};
has source => qw/is ro required 1 isa YUI::Loader::Source/;
has cache => qw/is ro isa YUI::Loader::Cache/;
has filter => qw/is rw isa Str/, default => "";



sub new_from_yui_host {
    return shift->new_from_internet(@_);
}

sub new_from_internet {
    my $class = shift;

    my ($given, $catalog) = $class->_new_given_catalog(@_);

    my %source;
    $source{version} = delete $given->{version} if exists $given->{version};
    $source{base} = delete $given->{base} if exists $given->{base};
    require YUI::Loader::Source::Internet;
    my $source = YUI::Loader::Source::Internet->new(catalog => $catalog, %source);

    return $class->_new_finish($given, $source);
}


sub new_from_yui_dir {
    my $class = shift;

    my ($given, $catalog) = $class->_new_given_catalog(@_);

    my %source;
    $source{version} = delete $given->{version} if exists $given->{version};
    $source{base} = delete $given->{base} if exists $given->{base};
    $source{dir} = delete $given->{dir} if exists $given->{dir};
    require YUI::Loader::Source::YUIDir;
    my $source = YUI::Loader::Source::YUIDir->new(catalog => $catalog, %source);

    return $class->_new_finish($given, $source);
}


sub new_from_uri {
    my $class = shift;

    my ($given, $catalog) = $class->_new_given_catalog(@_);

    my %source;
    $source{base} = delete $given->{base} if exists $given->{base};
    require YUI::Loader::Source::URI;
    my $source = YUI::Loader::Source::URI->new(catalog => $catalog, %source);

    return $class->_new_finish($given, $source);
}


sub new_from_dir {
    my $class = shift;

    my ($given, $catalog) = $class->_new_given_catalog(@_);

    my %source;
    $source{base} = delete $given->{base} if exists $given->{base};
    $source{dir} = delete $given->{dir} if exists $given->{dir};
    require YUI::Loader::Source::Dir;
    my $source = YUI::Loader::Source::Dir->new(catalog => $catalog, %source);

    return $class->_new_finish($given, $source);
}



sub filter_min {
    my $self = shift;
    return $self->filter("min");
    return $self;
}


sub filter_debug {
    my $self = shift;
    $self->filter("debug");
    return $self;
}


sub no_filter {
    my $self = shift;
    $self->filter("");
    return $self;
}


sub uri {
    my $self = shift;
    return $self->cache_uri(@_) if $self->cache;
    return $self->source_uri(@_);
}


sub file {
    my $self = shift;
    return $self->cache_file(@_) if $self->cache;
    return $self->source_file(@_);
}


sub cache_uri {
    my $self = shift;
    my $name = shift;
    return $self->cache->uri([ $name => $self->filter ]) || croak "Unable to get uri for $name from cache ", $self->cache;
}


sub cache_file {
    my $self = shift;
    my $name = shift;
    return $self->cache->file([ $name => $self->filter ]) || croak "Unable to get file for $name from cache ", $self->cache;
}


sub source_uri {
    my $self = shift;
    my $name = shift;
    return $self->source->uri([ $name => $self->filter ]) || croak "Unable to get uri for $name from source ", $self->source;
}


sub source_file {
    my $self = shift;
    my $name = shift;
    return $self->source->file([ $name => $self->filter ]) || croak "Unable to get file for $name from source ", $self->source;
}


sub item {
    my $self = shift;
    my $name = shift;
    return $self->catalog->item([ $name => $self->filter ]);
}


sub item_path {
    my $self = shift;
    my $name = shift;
    return $self->item($name)->path;
}


sub item_file {
    my $self = shift;
    my $name = shift;
    return $self->item($name)->file;
}

sub name_list {
    my $self = shift;
    return $self->manifest->schedule;
}

sub _html {
    my $self = shift;
    my $uri_list = shift;
    my $separator = shift || "\n";
    my @uri_list = $self->list->uri;
    my @html;
    for my $uri (@uri_list) {
        if ($uri =~ m/\.css/) {
            push @html, LINK({ rel => "stylesheet", type => "text/css", href => $uri });
        }
        else {
            push @html, SCRIPT({ type => "text/javascript", src => $uri, _ => "" });
        }
    }
    return join $separator, @html;
}


sub html {
    my $self = shift;
    return $self->_html([ $self->list->uri ], @_);
}


sub source_html {
    my $self = shift;
    return $self->_html([ $self->list->source_uri ], @_);
}

sub _new_given {
    my $class = shift;
    return @_ == 1 && ref $_[0] eq "HASH" ? shift : { @_ };
}

sub _new_catalog {
    my $class = shift;
    my $given = shift;
    my $catalog = delete $given->{catalog} || {};
    return $given->{catalog} = $catalog if blessed $catalog;
    return $given->{catalog} = YUI::Loader::Catalog->new(%$catalog);
}

sub _build_cache {
    my $class = shift;
    my $given = shift;
    my $source = shift;

    my (%cache, $cache_class);

    if (ref $given eq "ARRAY") {
        $cache_class = "YUI::Loader::Cache::URI";
        my ($uri, $dir) = @$given;
        %cache = (uri => $uri, dir => $dir);
    }
    elsif (ref $given eq "HASH") {
        $cache_class = "YUI::Loader::Cache::URI";
        my ($uri, $dir) = @$given{qw/uri dir/};
        %cache = (uri => $uri, dir => $dir);
    }
    elsif (ref $given eq "Path::Resource") {
        $cache_class = "YUI::Loader::Cache::URI";
        %cache = (uri => $given->uri, dir => $given->dir);
    }
    else {
        $cache_class = "YUI::Loader::Cache::Dir";
        %cache = (dir => $given);
    }

    eval "require $cache_class;" or die $@;

    return $cache_class->new(source => $source, %cache);
}

sub _new_cache {
    my $class = shift;
    my $given = shift;
    my $source = shift;
    if (my $cache = delete $given->{cache}) {
        $given->{cache} = $class->_build_cache($cache, $source);
    }
}

sub _new_given_catalog {
    my $class = shift;
    my $given = $class->_new_given(@_);

    my $catalog = $class->_new_catalog($given);

    return ($given, $catalog);
}

sub _new_finish {
    my $class = shift;
    my $given = shift;
    my $source = shift;

    $class->_new_cache($given, $source);

    return $class->new(%$given, source => $source);
}



1;

__END__
=pod

=head1 NAME

YUI::Loader - Load (and cache) the Yahoo JavaScript YUI framework

=head1 VERSION

version 0.071

=head1 SYNOPSIS

    use YUI::Loader;

    my $loader = YUI::Loader->new_from_yui_host;
    $loader->include->yuitest->reset->fonts->base;
    print $loader->html;

    # The above will yield:
    # <link rel="stylesheet" href="http://yui.yahooapis.com/2.5.1/build/reset/reset.css" type="text/css"/>
    # <link rel="stylesheet" href="http://yui.yahooapis.com/2.5.1/build/fonts/fonts.css" type="text/css"/>
    # <link rel="stylesheet" href="http://yui.yahooapis.com/2.5.1/build/base/base.css" type="text/css"/>
    # <script src="http://yui.yahooapis.com/2.5.1/build/yahoo/yahoo.js" type="text/javascript"></script>
    # <script src="http://yui.yahooapis.com/2.5.1/build/dom/dom.js" type="text/javascript"></script>
    # <script src="http://yui.yahooapis.com/2.5.1/build/event/event.js" type="text/javascript"></script>
    # <script src="http://yui.yahooapis.com/2.5.1/build/logger/logger.js" type="text/javascript"></script>
    # <script src="http://yui.yahooapis.com/2.5.1/build/yuitest/yuitest.js" type="text/javascript"></script>

You can also cache YUI locally:

    my $loader = YUI::Loader->new_from_yui_host(cache => { dir => "htdocs/assets", uri => "http://example.com/assets" });
    $loader->include->yuitest->reset->fonts->base;
    print $loader->html;

    # The above will yield:
    # <link rel="stylesheet" href="http://example.com/assets/reset.css" type="text/css"/>
    # <link rel="stylesheet" href="http://example.com/assets/fonts.css" type="text/css"/>
    # <link rel="stylesheet" href="http://example.com/assets/base.css" type="text/css"/>
    # <script src="http://example.com/assets/yahoo.js" type="text/javascript"></script>
    # <script src="http://example.com/assets/dom.js" type="text/javascript"></script>
    # <script src="http://example.com/assets/event.js" type="text/javascript"></script>
    # <script src="http://example.com/assets/logger.js" type="text/javascript"></script>
    # <script src="http://example.com/assets/yuitest.js" type="text/javascript"></script>

=head1 DESCRIPTION

YUI::Loader is a tool for loading YUI assets within your application. Loader will either provide the URI/HTML to access http://yui.yahooapis.com directly,
or you can cache assets locally or serve them from an exploded yui_x.x.x.zip dir.

=head1 METHODS

=head2 YUI::Loader->new_from_yui_host([ base => <base>, version => <version> ])

=head2 YUI::Loader->new_from_internet([ base => <base>, version => <version> ])

Return a new YUI::Loader object configured to fetch and/or serve assets from http://yui.yahooapis.com/<version>

=head2 YUI::Loader->new_from_yui_dir([ dir => <dir>, version => <version> ])

Return a new YUI::Loader object configured to fetch/serve assets from a local, exploded yui_x.x.x.zip dir

As an example, for a dir of C<./assets>, the C<reset.css> asset should be available as:

    ./assets/reset/reset.css

=head2 YUI::Loader->new_from_uri([ base => <base> ])

Return a new YUI::Loader object configured to serve assets from an arbitrary uri

As an example, for a base of C<http://example.com/assets>, the C<reset.css> asset should be available as:

    http://example.com/assets/reset.css

=head2 YUI::Loader->new_from_dir([ dir => <dir> ])

Return a new YUI::Loader object configured to serve assets from an arbitrary dir

As an example, for a dir of C<./assets>, the C<reset.css> asset should be available as:

    ./assets/reset.css

=head2 select( <component>, <component>, ..., <component> )

Include each <component> in the "manifest" for the loader.

A <component> should correspond to an entry in the C<YUI component catalog> (see below)

=head2 include

Returns a chainable component selector that will include what is called

You can use the methods of the selector to choose components to include. See C<YUI component catalog> below 

You can return to the loader by using the special ->then method:

    $loader->include->reset->yuilogger->grids->fonts->then->html;

=head2 exclude

Returns a chainable component selector that will exclude what is called

You can use the methods of the selector to choose components to include. See C<YUI component catalog> below 

You can return to the loader by using the special ->then method:

    $loader->exclude->yuilogger->then->html;

=head2 filter_min 

Turn on the -min filter for all included components

For example:

    connection-min.js
    yuilogger-min.js
    base-min.css
    fonts-min.css

=head2 filter_debug 

Turn on the -debug filter for all included components

For example:

    connection-debug.js
    yuilogger-debug.js
    base-debug.css
    fonts-debug.css

=head2 no_filter 

Disable filtering of included components

For example:

    connection.js
    yuilogger.js
    base.css
    fonts.css

=head2 uri( <component> )

Attempt to fetch a L<URI> for <component> using the current filter setting of the loader (-min, -debug, etc.)

If the loader has a cache, then this method will try to fetch from the cache. Otherwise it will use the source.

=head2 file( <component> )

Attempt to fetch a L<Path::Class::File> for <component> using the current filter setting of the loader (-min, -debug, etc.)

If the loader has a cache, then this method will try to fetch from the cache. Otherwise it will use the source.

=head2 cache_uri( <component> )

Attempt to fetch a L<URI> for <component> using the current filter setting of the loader (-min, -debug, etc.) from the cache

=head2 cache_file( <component> )

Attempt to fetch a L<Path::Class::File> for <component> using the current filter setting of the loader (-min, -debug, etc.) from the cache

=head2 source_uri( <component> )

Attempt to fetch a L<URI> for <component> using the current filter setting of the loader (-min, -debug, etc.) from the source

=head2 source_file( <component> )

Attempt to fetch a L<Path::Class::File> for <component> using the current filter setting of the loader (-min, -debug, etc.) from the source

=head2 item( <component> )

Return a L<YUI::Loader::Item> for <component> using the current filter setting of the loader (-min, -debug, etc.)

=head2 item_path( <component> )

Return the item path for <component> using the current filter setting of the loader (-min, -debug, etc.)

=head2 item_file( <component> )

Return the item file for <component> using the current filter setting of the loader (-min, -debug, etc.)

=head2 html

Generate and return a string containing HTML describing how to include components. For example, you can use this in the <head> section
of a web page.

If the loader has a cache, then it will attempt to generate URIs from the cache, otherwise it will use the source.

Here is an example:

    <link rel="stylesheet" href="http://example.com/assets/reset.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/fonts.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/base.css" type="text/css"/>
    <script src="http://example.com/assets/yahoo.js" type="text/javascript"></script>
    <script src="http://example.com/assets/dom.js" type="text/javascript"></script>
    <script src="http://example.com/assets/event.js" type="text/javascript"></script>
    <script src="http://example.com/assets/logger.js" type="text/javascript"></script>
    <script src="http://example.com/assets/yuitest.js" type="text/javascript"></script>

=head2 source_html

Generate and return a string containing HTML describing how to include components. For example, you can use this in the <head> section
of a web page.

Here is an example:

    <link rel="stylesheet" href="http://example.com/assets/reset.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/fonts.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/base.css" type="text/css"/>
    <script src="http://example.com/assets/yahoo.js" type="text/javascript"></script>
    <script src="http://example.com/assets/dom.js" type="text/javascript"></script>
    <script src="http://example.com/assets/event.js" type="text/javascript"></script>
    <script src="http://example.com/assets/logger.js" type="text/javascript"></script>
    <script src="http://example.com/assets/yuitest.js" type="text/javascript"></script>

=head1 YUI component catalog

=head2 animation

Animation Utility (utility)

=head2 autocomplete

AutoComplete Control (widget)

=head2 base

Base CSS Package (css)

=head2 button

Button Control (widget)

=head2 calendar

Calendar Control (widget)

=head2 charts

Charts Control (widget)

=head2 colorpicker

Color Picker Control (widget)

=head2 connection

Connection Manager (utility)

=head2 container

Container Family (widget)

=head2 containercore

Container Core (Module, Overlay) (widget)

=head2 cookie

Cookie Utility (utility)

=head2 datasource

DataSource Utility (utility)

=head2 datatable

DataTable Control (widget)

=head2 dom

Dom Collection (core)

=head2 dragdrop

Drag &amp; Drop Utility (utility)

=head2 editor

Rich Text Editor (widget)

=head2 element

Element Utility (utility)

=head2 event

Event Utility (core)

=head2 fonts

Fonts CSS Package (css)

=head2 get

Get Utility (utility)

=head2 grids

Grids CSS Package (css)

=head2 history

Browser History Manager (utility)

=head2 imagecropper

ImageCropper Control (widget)

=head2 imageloader

ImageLoader Utility (utility)

=head2 json

JSON Utility (utility)

=head2 layout

Layout Manager (widget)

=head2 logger

Logger Control (tool)

=head2 menu

Menu Control (widget)

=head2 profiler

Profiler (tool)

=head2 profilerviewer

ProfilerViewer Control (tool)

=head2 reset

Reset CSS Package (css)

=head2 reset_fonts

=head2 reset_fonts_grids

=head2 resize

Resize Utility (utility)

=head2 selector

Selector Utility (utility)

=head2 simpleeditor

Simple Editor (widget)

=head2 slider

Slider Control (widget)

=head2 tabview

TabView Control (widget)

=head2 treeview

TreeView Control (widget)

=head2 uploader

Uploader (widget)

=head2 utilities

=head2 yahoo

Yahoo Global Object (core)

=head2 yahoo_dom_event

=head2 yuiloader

Loader Utility (utility)

=head2 yuiloader_dom_event

=head2 yuitest

YUI Test Utility (tool)

=head1 SEE ALSO

L<http://developer.yahoo.com/yui/>

L<http://developer.yahoo.com/yui/yuiloader/>

L<JS::jQuery::Loader>

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

