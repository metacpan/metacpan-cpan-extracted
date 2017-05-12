package XML::OverHTTP;
use strict;
use vars qw( $VERSION @ISA );
$VERSION = '0.08';
use XML::TreePP;
use CGI;
# use Data::Page;
# use Data::Pageset;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( xml tree code param ));

if ( $XML::TreePP::VERSION < 0.26 ) {
    Carp::croak( 'XML::TreePP version 0.26 or later is required' );
}

package XML::OverHTTP::Default;
use strict;
use vars qw( $VERSION );
$VERSION = $XML::OverHTTP::VERSION;

sub http_method { 'GET'; }
sub url { undef; }
sub query_class { undef; }
sub default_param { {}; }
sub notnull_param { []; }
sub force_array { []; }
sub force_hash { []; }
sub attr_prefix { ''; }
sub text_node_key { '#text'; }
sub elem_class { undef; }
sub root_elem { undef; }
sub is_error { undef; }
sub total_entries { undef; }
sub entries_per_page { undef; }
sub current_page { undef; }
sub page_param { undef; }

package XML::OverHTTP;  # again
use strict;
use base qw( XML::OverHTTP::Default );

sub new {
    my $package = shift;
    my $self    = {};
    bless $self, $package;
    my $default = $self->default_param();
    $self->add_param( %$default ) if ref $default;
    $self->add_param( @_ ) if scalar @_;
    $self;
}

sub new_param {
    my $self  = shift;
    my $class = $self->query_class();
    return {} unless defined $class;
    $class->new();
}

sub add_param {
    my $self  = shift;
    my $param = $self->param() || $self->new_param();
    %$param = ( %$param, @_ ) if scalar @_;
    $self->param( $param );
}

sub get_param {
    my $self  = shift;
    my $key   = shift;
    my $param = $self->param() or return;
    $param->{$key} if exists $param->{$key};
}

sub treepp {
    my $self = shift;
    $self->{treepp} = shift if scalar @_;
    return $self->{treepp} if ref $self->{treepp};
    $self->{treepp} = XML::TreePP->new();
}

sub init_treepp {
    my $self   = shift;
    my $treepp = $self->treepp();

    my $force_array   = $self->force_array();
    my $force_hash    = $self->force_hash();
    my $attr_prefix   = $self->attr_prefix();
    my $text_node_key = $self->text_node_key();
#   my $base_class    = $self->base_class();
    my $elem_class    = $self->elem_class();
    $treepp->set( force_array   => $force_array );
    $treepp->set( force_hash    => $force_hash );
    $treepp->set( attr_prefix   => $attr_prefix );
    $treepp->set( text_node_key => $text_node_key );
#   $treepp->set( base_class    => $base_class );
    $treepp->set( elem_class    => $elem_class );

    $treepp;
}

sub request {
    my $self   = shift;
    $self->{tree}    = undef;
    $self->{xml}     = undef;
    $self->{code}    = undef;
    $self->{page}    = undef;
    $self->{pageset} = undef;

    $self->check_param();
    my $req = $self->http_request();
    my $treepp = $self->init_treepp();
    my( $tree, $xml, $code ) = $treepp->parsehttp( @$req );

    $self->{tree} = $tree;
    $self->{xml}  = $xml;
    $self->{code} = $code;
    $tree;
}

sub http_request {
    my $self   = shift;

    my $method = $self->http_method();
    my $url    = $self->url();
    my $query  = $self->query_string();
    Carp::croak( 'HTTP method is not defined' ) unless defined $method;
    Carp::croak( 'Request url is not defined' ) unless defined $url;

    my $req;
    if ( uc($method) eq 'GET' ) {
        $url .= '?'.$query if length($query);
        $req = [ $method, $url ];
    }
    else {
        $req = [ $method, $url, $query ];
    }
    $req;
}

sub root {
    my $self = shift;
    my $tree = $self->tree();
    Carp::croak( 'Empty response' ) unless ref $tree;
    my $root = $self->root_elem();
    Carp::croak( 'Root element is not defined' ) unless defined $root;
    Carp::croak( 'Root element seems empty' ) unless ref $tree->{$root};
    $tree->{$root};
}

sub root_elem {
    my $self = shift;
    my $tree = $self->tree();
    Carp::croak( 'Empty response' ) unless ref $tree;
    Carp::croak( 'Multiple root elements found' ) if ( scalar keys %$tree > 1 );
    # root element auto discovery by default
    ( keys %$tree )[0];
}

sub query_string {
    my $self  = shift;
    my $param = $self->param() or return;
    local $CGI::USE_PARAM_SEMICOLONS = 0;
    my $hash = { %$param };                     # copy for blessed hash
    CGI->new( $hash )->query_string();
}

sub check_param {
    my $self  = shift;
    my $param = $self->param() or return;
    my $check = $self->notnull_param() or return;
    my $error = [ grep {
        ! exists $param->{$_}  || 
        ! defined $param->{$_} || 
        $param->{$_} eq '' 
    } @$check ];
    return unless scalar @$error;
    my $join  = join( ' ' => @$error );
    Carp::croak "Invalid request: empty parameters - $join\n";
}

sub page {
    my $self = shift;
    my $page = shift;
    if ( ! defined $page ) {
        return $self->{page} if ref $self->{page};
        local $@;
        eval { require Data::Page; } unless $Data::Page::VERSION;
        Carp::croak( "Data::Page is required: $@" ) unless $Data::Page::VERSION;
        $page = Data::Page->new();
    }
    my $total_entries    = $self->total_entries();
    my $entries_per_page = $self->entries_per_page();
    my $current_page     = $self->current_page();
    $page->total_entries( $total_entries );
    $page->entries_per_page( $entries_per_page );
    $page->current_page( $current_page );
    $self->{page} = $page;
}

sub pageset {
    my $self = shift;
    my $mode = shift;   # default 'fixed', or 'slide'
    return $self->{pageset} if ref $self->{pageset};
    my $total_entries    = $self->total_entries();
    my $entries_per_page = $self->entries_per_page();
    my $current_page     = $self->current_page();
    my $hash = {
        total_entries    => $total_entries,
        entries_per_page => $entries_per_page,
        current_page     => $current_page,
        mode             => $mode,
    };
    local $@;
    eval { require Data::Pageset; } unless $Data::Pageset::VERSION;
    Carp::croak( "Data::Pageset is required: $@" ) unless $Data::Pageset::VERSION;
    $self->{pageset} = Data::Pageset->new( $hash );
}

sub page_query {
    my $self = shift;
    my $param = $self->page_param( @_ );
    local $CGI::USE_PARAM_SEMICOLONS = 0;
    CGI->new( $param )->query_string();
}

=head1 NAME

XML::OverHTTP - A base class for XML over HTTP-styled web service interface

=head1 DESCRIPTION

This module is not used directly from end-users. 
As a child class of this, module authors can easily write own interface module 
for XML over HTTP-styled web service.

=head1 METHODS PROVIDED

This module provides some methods and requires other methods overridden by child classes.
The following methods are to be called in your module or by its users.

=head2 new

This constructor method returns a new object for your users.
It accepts query parameters by hash.

    my $api = MyAPI->new( %param );

MyAPI.pm inherits this XML::OverHTTP modules.

=head2 add_param

This method adds query parameters for the request.

    $api->add_param( %param );

It does not validate key names.

=head2 get_param

This method returns a current query parameter.

    $api->get_param( 'key' );

=head2 treepp

This method returns an L<XML::TreePP> object to make the request.

    $api->treepp->get( 'key' );

And you can set its object as well.

    my $mytpp = XML::TreePP->new;
    $api->treepp( $mytpp );

total_entries, entries_per_page and current_page parameters 
in C<$mytpp> are updated.

=head2 request

This method makes the request for the web service and returns its response tree.

    my $tree = $api->request;

After calling this method, the following methods are available.

=head2 tree

This method returns the whole of the response parsed by L<XML::TreePP> parser.

    my $tree = $api->tree;

Every element is blessed when L</elem_class> is defined.

=head2 root

This method returns the root element in the response.

    my $root = $api->root;

=head2 xml

This method returns the response context itself.

    print $api->xml, "\n";

=head2 code

This method returns the response status code.

    my $code = $api->code; # usually "200" when succeeded

=head2 page

This method returns a L<Data::Page> object to create page navigation.

    my $pager = $api->page;
    print "Last page: ", $pager->last_page, "\n";

And you can set its object as well.

    my $pager = Data::Page->new;
    $api->page( $pager );

=head2 pageset

This method returns a L<Data::Pageset> object to create page navigation.
The paging mode is C<fixed> as default.

    my $pager = $api->pageset;
    $pager->pages_per_set( 10 );
    print "First page of next page set: ",  $page_info->next_set, "\n";

Or set it to C<slide> mode if you want.

    my $pager = $api->pageset( 'slide' );

=head2 page_param

This method returns pair(s) of query key and value to set the page number 
for the next request.

    my $hash = $api->page_param( $page );

The optional second argument specifies the number of entries per page.

    my $hash = $api->page_param( $page, $size );

The optional third argument incluedes some other query parameters.

    my $newhash = $api->page_param( $page, $size, $oldhash );

=head2 page_query

This method returns a processed query string which is joined by '&' delimiter.

    my $query = $api->page_query();                         # current page
    my $query = $api->page_query( $page, $size, $hash );    # specified page

=head1 METHOD YOU MUST OVERRIDE

You B<MUST> override at least one method below:

=head2 url

This is a method to specify the url for the request to the web service.
E.g.,

    sub url { 'http://www.example.com/api/V1/' }

=head1 METHODS YOU SHOULD OVERRIDE

The methods that you B<SHOULD> override in your module are below:

=head2 root_elem

This is a method to specify a root element name in the response.
E.g.,

    sub root_elem { 'rdf:RDF' }

=head2 is_error

This is a method to return C<true> value when the response seems 
to have error. This returns C<undef> when it succeeds.
E.g.,

    sub is_error { $_[0]->root->{status} != 'OK' }

=head2 total_entries

This is a method to return the number of total entries for C<Data::Page>.
E.g.,

    sub total_entries { $_[0]->root->{hits} }

=head2 entries_per_page

This is a method to return the number of entries per page for C<Data::Page>.
E.g.,

    sub entries_per_page { $_[0]->root->{-count} }

=head2 current_page

This is a method to return the current page number for C<Data::Page>.
E.g.,

    sub current_page { $_[0]->root->{-page} }

=head2 page_param

This is a method to return paging parameters for the next request.
E.g.,

    sub page_param {
        my $self = shift;
        my $page = shift || $self->current_page();
        my $size = shift || $self->entries_per_page();
        my $hash = shift || {};
        $hash->{page}  = $page if defined $page;
        $hash->{count} = $size if defined $size;
        $hash;
    }

When your API uses SQL-like query parameters, offset and limit:

    sub page_param {
        my $self = shift;
        my $page = shift || $self->current_page() or return;
        my $size = shift || $self->entries_per_page() or return;
        my $hash = shift || {};
        $hash->{offset} = ($page-1) * $size;
        $hash->{limit}  = $size;
        $hash;
    }

=head1 METHODS YOU CAN OVERRIDE

You B<CAN> override the following methods as well.

=head2 http_method

This is a method to specify the HTTP method, 'GET' or 'POST', for the request.
This returns 'GET' as default.
E.g.,

    sub http_method { 'GET' }

=head2 default_param

This is a method to specify pairs of default query parameter and its value 
for the request.
E.g.,

    sub default_param { { method => 'search', lang => 'perl' } }

=head2 notnull_param

This is a method to specify a list of query parameters which are required 
by the web service.
E.g.,

    sub notnull_param { [qw( api_key secret query )] }

These keys are checked before makeing a request for safe. 

=head2 query_class

This is a method to specify a class name for query parameters.
E.g.,

    sub elem_class { 'MyAPI::Query' }

The default value is C<undef>, it means 
a normal hash is used instead.

=head2 attr_prefix

This is a method to specify a prefix for each attribute 
in the response tree. L<XML::TreePP> uses it.
E.g.,

    sub attr_prefix { '' }

The default prefix is zero-length string C<""> which is recommended.

=head2 text_node_key

This is a method to specify a hash key for text nodes
in the response tree. L<XML::TreePP> uses it.
E.g.,

    sub text_node_key { '_text' }

The default key is C<"#text">.

=head2 elem_class

This is a method to specify a base class name for each element 
in the response tree. L<XML::TreePP> uses it.
E.g.,

    sub elem_class { 'MyAPI::Element' }

The default value is C<undef>, it means 
each elements is a just hashref and not bless-ed.

=head2 force_array

This is a method to specify a list of element names which should always 
be forced into an array representation in the response tree. 
L<XML::TreePP> uses it.
E.g.,

    sub force_array { [qw( rdf:li item xmlns )] }

=head2 force_hash

This is a method to specify a list of element names which should always 
be forced into an hash representation in the response tree. 
L<XML::TreePP> uses it.
E.g.,

    sub force_hash { [qw( item image )] }

=head1 SEE ALSO

L<XML::TreePP>

L<http://www.kawa.net/works/perl/overhttp/overhttp-e.html>

=head1 AUTHOR

Yusuke Kawasaki L<http://www.kawa.net/>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
1;
