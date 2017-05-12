package WebService::Simple;
use strict;
use warnings;
use base qw(LWP::UserAgent Class::Data::ConfigHash);
use Class::Inspector;
use Data::Dumper ();
use Digest::MD5  ();
use URI::Escape;
use URI::QueryParam;
use HTTP::Message;
use Hash::MultiValue;
use WebService::Simple::Response;
use UNIVERSAL::require;

our $VERSION = '0.25';

__PACKAGE__->config(
    base_url        => '',
    response_parser => { module => "XML::Simple" },
);

sub new {
    my $class    = shift;
    my %args     = @_;
    my $base_url = delete $args{base_url}
      || $class->config->{base_url}
      || Carp::croak("base_url is required");
    $base_url = URI->new($base_url);
    my $basic_params = delete $args{params} || delete $args{param} || {};
    my $debug = delete $args{debug} || 0;

    my $response_parser = delete $args{response_parser}
      || $class->config->{response_parser};
    if (   !$response_parser
        || !eval { $response_parser->isa('WebService::Simple::Parser') } )
    {
        my $config = $response_parser || $class->config->{response_parser};
        if ( !ref $config ) {
            $config = { module => $config };
        }
        my $module = $config->{module};
        if ( $module !~ s/^\+// ) {
            $module = __PACKAGE__ . "::Parser::$module";
        }
        if ( !Class::Inspector->loaded($module) ) {
            $module->require or die;
        }
        $response_parser = $module->new( %{ $config->{args} || {} } );
    }

    my $cache = delete $args{cache};
    if ( !$cache || ref $cache eq 'HASH' ) {
        my $config = ref $cache eq 'HASH' ? $cache : $class->config->{cache};
        if ($config) {
            if ( !ref $config ) {
                $config = { module => $config };
            }

            my $module = $config->{module};
            if ( !Class::Inspector->loaded($module) ) {
                $module->require or die;
            }
            $cache =
              $module->new( $config->{hashref_args}
                ? $config->{args}
                : %{ $config->{args} } );
        }
    }

    my $self = $class->SUPER::new(%args);
    $self->{base_url}        = $base_url;
    $self->{basic_params}    = $basic_params;
    $self->{response_parser} = $response_parser;
    $self->{cache}           = $cache;
    $self->{compression}     = delete $args{compression};
    $self->{content_type}    = delete $args{content_type};
    $self->{croak}           = delete $args{croak};
    $self->{debug}           = $debug;

    if($self->{content_type} && $self->{content_type} eq 'application/json'){
	$self->__init_request_parser_json();
    }else{
        $self->{request_parser} = sub { return \$_[0] };
    }

    return $self;
}

sub _agent       { "libwww-perl/$LWP::VERSION+". __PACKAGE__ .'/'.$VERSION }

sub base_url        { $_[0]->{base_url} }
sub basic_params    { $_[0]->{basic_params} }
sub response_parser { $_[0]->{response_parser} }
sub request_parser  { $_[0]->{request_parser} }
sub cache           { $_[0]->{cache} }

sub __cache_get {
    my $self  = shift;
    my $cache = $self->cache;
    return unless $cache;

    my $key = $self->__cache_key(shift);
    return $cache->get( $key, @_ );
}

sub __cache_set {
    my $self  = shift;
    my $cache = $self->cache;
    return unless $cache;

    my $key = $self->__cache_key(shift);
    return $cache->set( $key, @_ );
}

sub __cache_remove {
    my $self  = shift;
    my $cache = $self->cache;
    return unless $cache;

    my $key = $self->__cache_key(shift);
    return $cache->remove( $key, @_ );
}

sub __cache_key {
    my $self = shift;
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Sortkeys = 1;
    return Digest::MD5::md5_hex( Data::Dumper::Dumper( $_[0] ) );
}

sub __init_request_parser_json {
    my $self = shift;
    require WebService::Simple::Parser::JSON;
    my $json_parser = WebService::Simple::Parser::JSON->new();
    $self->{request_parser_json} = sub { $json_parser->parse_request(@_); }
}

sub request_url {
    my $self = shift;
    my %args = @_;
    
    my $uri = ref($args{url}) =~ m/^URI/ ? $args{url}->clone() : URI->new($args{url});
    if ( my $extra_path = $args{extra_path} ) {
        $extra_path =~ s!^/!!;
        $uri->path( $uri->path . $extra_path );
    }
    if($args{params}) {
        if(ref $args{params} eq 'Hash::MultiValue') {
            for my $key ($args{params}->keys) {
                $uri->query_param_append($key, $args{params}->get($key));
            }
        }else{
            $uri->query_form(%{$args{params}});
        }
    }
    return $uri;
}

sub get {
    my $self = shift;
    my ($url, $extra) = ("", {});

    if ( ref $_[0] eq 'HASH' ) {
        $extra = shift @_;
    }
    else {
        $url = shift @_;
        if ( ref $_[0] eq 'HASH' ) {
            $extra = shift @_;
        }
    }

    my $uri = $self->request_url(
        url => $self->base_url,
        extra_path => $url,
        params => Hash::MultiValue->new(%{$self->basic_params}, %$extra),
    );

    warn "Request URL is $uri\n" if $self->{debug};

    my @headers = @_;
    unless(defined($self->{compression}) && !$self->{compression}){
        my $can_accept = HTTP::Message::decodable();
        push @headers, ('Accept-Encoding' => $can_accept) ;
    }

    my $response;
    $response = $self->__cache_get( [ $uri, @headers ] );
    if ($response) {
        if ($response->isa('WebService::Simple::Response')) { # backward compatibility
            return $response;
        } else {
            return WebService::Simple::Response->new_from_response(
                response => $response,
                parser => $self->response_parser
            );
        }
    }

    $response = $self->SUPER::get( $uri, @headers );

    if ( $response->is_success ) {
        $self->__cache_set( [ $uri, @headers ], $response );
        $response = WebService::Simple::Response->new_from_response(
            response => $response,
            parser   => $self->response_parser
        );
    }else{
        Carp::croak("request to $uri failed") unless defined($self->{croak}) && !$self->{croak};
    }

    return $response;
}

sub post {
    my $self = shift;
    my ( $url, $extra ) = ( '', {} );

    if ( ref $_[0] eq 'HASH' ) { # post(\%arg [, @header ])
        $extra = shift @_;
    }
    elsif ( ref $_[1] eq 'HASH' ) { # post($url, \%arg [, @header ])
        $url = shift @_;
        $extra = shift @_;
    }
    elsif ( @_ % 2 ) { # post($url [, @header ])
        $url = shift @_;
    }

    my @headers = @_;
    unless(defined($self->{compression}) && !$self->{compression}){
        my $can_accept = HTTP::Message::decodable();
        push @headers, ('Accept-Encoding' => $can_accept) ;
    }
    my %headers = @headers;

    # Content-Type tells us where "extra params" go: form-urlencoded -> $uri / json/xml -> $content
    my ($uri,$response);
  
    if( ($self->{content_type} && $self->{content_type} eq 'application/json') || ($headers{'Content-Type'} && $headers{'Content-Type'} eq 'application/json') ){
	$self->__init_request_parser_json() unless $self->{request_parser_json};

        $uri = $self->request_url(
	    url => $self->base_url,
            extra_path => $url,
            # params => Hash::MultiValue->new(%{$self->basic_params}, %$extra), # this'll go to content
        );
        # $uri->query_form(undef); # we'll leave all params on the url

        my $req = HTTP::Request->new(POST => $uri, \@headers);
        $req->content_type('application/json');
        $req->content($self->{request_parser_json}->({ %{$self->basic_params}, %$extra }));
        $response = $self->SUPER::request($req);
    }else{
        $uri = $self->request_url(
	    url => $self->base_url,
            extra_path => $url,
            params => Hash::MultiValue->new(%{$self->basic_params}, %$extra),
        );
        my $content = $uri->query_form_hash();
        $uri->query_form(undef);

	push(@headers, 'Content-Type' => $self->{content_type}) if $self->{content_type};

        $response = $self->SUPER::post( $uri, $content, @headers );
    }

    if ( $response->is_success ) {
        $response = WebService::Simple::Response->new_from_response(
            response => $response,
            parser   => $self->response_parser
        );
    }else{
        Carp::croak("request to $uri failed") unless defined($self->{croak}) && !$self->{croak};
    }

    return $response;
}

1;

__END__

=head1 NAME

WebService::Simple - Simple Interface To Web Services APIs

=head1 SYNOPSIS

  use WebService::Simple;

  # Simple use case
  my $flickr = WebService::Simple->new(
    base_url => "http://api.flickr.com/services/rest/",
    param    => { api_key => "your_api_key", }
  );

  # send GET request to 
  # http://api.flickr.com/service/rest/?api_key=your_api_key&method=flickr.test.echo&name=value
  $flickr->get( { method => "flickr.test.echo", name => "value" } );

  # send GET request to 
  # http://api.flickr.com/service/rest/extra/path?api_key=your_api_key&method=flickr.test.echo&name=value
  $flickr->get( "extra/path",
    { method => "flickr.test.echo", name => "value" });

=head1 DESCRIPTION

WebService::Simple is a simple class to interact with web services.

It's basically an LWP::UserAgent that remembers recurring API URLs and
parameters, plus sugar to parse the results.

=head1 METHODS

=over 4

=item new(I<%args>)

    my $flickr = WebService::Simple->new(
        base_url => "http://api.flickr.com/services/rest/",
        param    => { api_key => "your_api_key", },
        # compression  => 0
        # content_type => 'application/json'
        # croak        => 0
        # debug        => 1
    );

Create and return a new WebService::Simple object.
"new" Method requires a base_url of Web Service API.

By default, the module calls Carp::croak (dies) on unsuccessful HTTP requests. If
you want to change this behaviour, set croak to FALSE and get() or post() will return
the HTTP::Response object on success and failure, just like the base LWP::UserAgent.

By default the module will attempt to use HTTP compression if the Compress::Zlib
module is available. Pass compress => 0 to ->new() to disable this feature.

If debug is set, the request URL will be dumped via warn() on get or post method calls .

=item get(I<[$extra_path,] $args>)

    my $response =
      $flickr->get( { method => "flickr.test.echo", name => "value" } );

Send a GET request, and you can get the WebService::Simple::Response object.
If you want to add a path to base URL, use an option parameter.

    my $lingr = WebService::Simple->new(
        base_url => "http://www.lingr.com/",
        param    => { api_key => "your_api_key", format => "xml" }
    );
    my $response = $lingr->get( 'api/session/create', {} );

=item post(I<$args_ref, @headers>)

=item post(I<$extra_path, $args_ref, @headers>)

=item post(I<$extra_path, @headers>)

Send a POST request.

    my $ws = WebService::Simple->new(
        base_url => 'http://example.com/',
        param   =>  { aaa => 'zzz' },
    );
    my $response = $ws->post('api/echo', { hello => 'world'});

By default, POST requests will have Content-Type application/x-www-form-urlencoded.
That means, the content of a post request, the message body, is a string of your
urlencoded parameters. You can change this by setting a different default value
upon construction by passing content_type => 'application/json' to ->new(). Or on
a per-request basis by setting the Content-Type header. JSON request encoding is
currently the only supported content type for this feature.

    my $ws = WebService::Simple->new(
        base_url => 'http://example.com/',
        param   =>  { aaa => 'zzz' },
    #   content_type => 'application/json', # either here
    );
    my $response = $ws->post('api/echo', { hello => 'world' }, 'Content-Type' => 'application/json'); # or here

=item request_url(I<$extra_path, $args>)

Return request URL.

=item base_url

=item basic_params

=item cache

Each request is prepended by an optional cache look-up. If you supply a Cache
object to new(), the module will look into the cache first.

  my $cache   = Cache::File->new(
      cache_root      => '/tmp/mycache',
      default_expires => '30 min',
  );
  
  my $flickr = WebService::Simple->new(
      base_url => "http://api.flickr.com/services/rest/",
      cache    => $cache,
      param    => { api_key => "your_api_key, }
  );

=item response_parser

See PARSERS below.

=back

=head1 SUBCLASSING

For better encapsulation, you can create subclass of WebService::Simple to
customize the behavior

  package WebService::Simple::Flickr;
  use base qw(WebService::Simple);
  __PACKAGE__->config(
    base_url => "http://api.flickr.com/services/rest/",
    upload_url => "http://api.flickr.com/services/upload/",
  );

  sub test_echo
  {
    my $self = shift;
    $self->get( { method => "flickr.test.echo", name => "value" } );
  }

  sub upload
  {
    my $self = shift;
    local $self->{base_url} = $self->config->{upload_url};
    $self->post( 
      Content_Type => "form-data",
      Content => { title => "title", description => "...", photo => ... },
    );
  }


=head1 PARSERS

Web services return their results in various different formats. Or perhaps
you require more sophisticated results parsing than what WebService::Simple
provides.

WebService::Simple by default uses XML::Simple, but you can easily override
that by providing a parser object to the constructor:

  my $service = WebService::Simple->new(
    response_parser => AVeryComplexParser->new,
    ...
  );
  my $response = $service->get( ... );
  my $thing = $response->parse_response;

For example. If you want to set XML::Simple options, use WebService::Simple::Parser::XML::Simple
including this module:

  use WebService::Simple;
  use WebService::Simple::Parser::XML::Simple;
  use XML::Simple;
  
  my $xs = XML::Simple->new( KeyAttr => [], ForceArray => ['entry'] );
  my $service = WebService::Simple->new(
      base_url => "http://gdata.youtube.com/feeds/api/videos",
      param    => { v => 2 },
      response_parser =>
        WebService::Simple::Parser::XML::Simple->new( xs => $xs ),
  );

This allows great flexibility in handling different Web Services


=head1 REPOSITORY

https://github.com/yusukebe/WebService-Simple

=head1 AUTHOR

Yusuke Wada  C<< <yusuke@kamawada.com> >>

Daisuke Maki C<< <daisuke@endeworks.jp> >>

Matsuno Tokuhiro

Naoki Tomita (tomi-ru)

=head1 COPYRIGHT AND LICENSE

This module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
See L<perlartistic>.

=cut
