package XAS::Service::Resource;

use strict;
use warnings;

use XAS::Factory;
use Data::Dumper;
use Hash::MultiValue;
use parent 'Web::Machine::Resource';
use Web::Machine::Util 'create_header';

# -------------------------------------------------------------------------
# Web::Machine::Resource overrides
# ------------------------------------------------------------------------

sub init {
    my $self = shift;
    my $args = shift;

    $self->{'tt'} = exists $args->{'template'}
      ? $args->{'template'}
      : undef;

    $self->{'json'} = exists $args->{'json'}
      ? $args->{'json'}
      : undef;

    $self->{'app_name'} = exists $args->{'app_name'}
      ? $args->{'app_name'}
      : 'Test App';

    $self->{'app_description'} = exists $args->{'app_description'}
      ? $args->{'app_description'}
      : 'Testing Testing 1 2 3';

    $self->{'alias'} = exists $args->{'alias'}
      ? $args->{'alias'}
      : 'resource';

    $self->errcode(0);
    $self->errstr('');

    $self->{'env'} = XAS::Factory->module('environment');
    $self->{'log'} = XAS::Factory->module('logger');

}

sub is_authorized {
    my $self = shift;
    my $auth = shift;

    my $stat = 0;

    if ($auth) {

        warn "is_authorized - override this please\n";
        warn sprintf("username: %s, password: %s\n", $auth->username, $auth->password);

        $stat = 1;

        return $stat;

    }

    return create_header('WWWAuthenticate' => [ 'Basic' => ( realm => 'XAS Rest' ) ] );

}

sub options {
    my $self = shift;

    my $options;
    my @accepted;
    my @provided;
    my $allowed = $self->allowed_methods;

    foreach my $hash (@{$self->content_types_accepted}) {

        my ($key) = keys %$hash;
        push(@accepted, $key);

    }

    foreach my $hash (@{$self->content_types_provided}) {

        my ($key) = keys %$hash;
        push(@provided, $key);

    }

    $options->{'allow'}    = join(',', @$allowed);
    $options->{'accepted'} = join(',', @accepted);
    $options->{'provides'} = join(',', @provided);

    return $options;

}

sub allowed_methods { [qw[ OPTIONS GET HEAD ]] }

sub post_is_create {

    # uses "content_types_accepted" methods for procssing

    return 1;

}

sub content_types_accepted {

    return [
        { 'application/json'                  => 'from_json' },
        { 'application/x-www-form-urlencoded' => 'from_html' },
    ];

}

sub content_types_provided {

    return [
        { 'text/html'            => 'to_html' },
        { 'application/hal+json' => 'to_json' },
    ];

}

sub charset_provided { return ['UTF-8']; }

sub finish_request {
    my $self     = shift;
    my $metadata = shift;

    my $alias  = $self->alias;
    my $user   = $self->request->user || 'unknown';
    my $uri    = $self->request->uri;
    my $method = $self->request->method;
    my $code   = $self->response->code;
    my $path   = $uri->path;

    my $fixup = sub {
        my $status = shift;
        my $format = shift;
        my $data   = shift;

        my $output;

        if ($format eq 'json') {

            $output = $self->format_json($data);
            $self->response->content_type('application/hal+json');

        } else {

            $output = $self->format_html($data);
            $self->response->content_type('text/html');

        }

        $self->response->body($output);
        $self->response->header('Location' => $uri->path);
        $self->response->status($status);

        {
            use bytes;
            $self->response->header('Content-Length' => length($output));
        }

    };

    $self->log->info(
        sprintf('%s: %s requested a %s for %s with a status of %s',
            $alias, $user, $method, $path, $code)
    );

    if (defined($metadata->{'exception'})) {

        my $data;
        my $ex     = $metadata->{'exception'};
        my $ref    = ref($metadata->{'exception'});
        my $status = $self->errcode || 403;
        my $type   = $self->request->header('accept');
        my $format = ($type =~ /json/) ? 'json' : 'html';

        $data->{'_links'}     = $self->get_links();
        $data->{'navigation'} = $self->get_navigation();

        if (($ref eq 'XAS::Exception') or ($ref eq 'Badger::Exception')) {

            $data->{'_embedded'}->{'errors'} = [{
                title  => $self->errstr,
                status => $status,
                code   => $ex->type,
                detail => $ex->info
            }];

        } else {

            $data->{'_embedded'}->{'errors'} = [{
                title  => $self->errstr,
                status => $status,
                code   => 'unknown error',
                detail => sprintf('%s', $ex)
            }];

        }

        $fixup->($status, $format, $data);

    } elsif ($self->response->status >= 400) {

        my $data;
        my $body   = join('<br>', @{$self->response->body});
        my $code   = ($self->response->status >= 500) ? 'http internal server error' : 'http client error';
        my $status = $self->response->status;
        my $type   = $self->request->header('accept');
        my $format = ($type =~ /json/) ? 'json' : 'html';

        $data->{'_links'}     = $self->get_links();
        $data->{'navigation'} = $self->get_navigation();

        $data->{'_embedded'}->{'errors'} = [{
            title  => sprintf('HTTP Error: %s', $self->response->status),
            status => $self->response->status,
            code   => $code,
            detail => $body,
        }];

        $fixup->($status, $format, $data);

    }

}

# -------------------------------------------------------------------------
# methods
# -------------------------------------------------------------------------

sub process_exception {
    my $self   = shift;
    my $title  = shift;
    my $status = shift;

    $self->{'errcode'} = $$status;
    $self->{'errstr'}  = $title;

}

sub process_params {
    my $self   = shift;
    my $params = shift;

    return 1;

}

sub get_navigation {
    my $self = shift;

    return [{
        link => '/',
        text => 'Root',
    }];

}

sub get_links {
    my $self = shift;

    return {
        self => {
            title => 'Root',
            href  => '/',
        },
    };

}

sub get_response {
    my $self = shift;

    my $data;

    $data->{'_links'}     = $self->get_links();
    $data->{'navigation'} = $self->get_navigation();

    return $data;

}

sub json_to_multivalue {
    my $self = shift;
    my $json = shift;

    my $decoded = $self->json->decode($json);
    my $params  = Hash::MultiValue->new();

    while (my ($key, $value) = each(%$decoded)) {

        $params->add($key, $value);

    }

    return $params;

}

sub from_json {
    my $self = shift;

    # get the post parameters

    my $content = $self->request->content;
    my $params  = $self->json_to_multivalue($content);

    return $self->process_params($params);

}

sub from_html {
    my $self = shift;

    # get the post parameters

    my $params = $self->request->parameters;

    return $self->process_params($params);

}

sub to_json {
    my $self = shift;

    my $data = $self->get_response();
    my $json = $self->format_json($data);

    return $json;

}

sub to_html {
    my $self = shift;

    my $data = $self->get_response();
    my $html = $self->format_html($data);

    return $html;

}

sub format_json {
    my $self = shift;
    my $data = shift;

    delete $data->{'navigation'};

    return $self->json->encode($data);

}

sub format_html {
    my $self = shift;
    my $data = shift;

    my $html;
    my $view = {
        view => {
            title       => $self->app_name,
            description => $self->app_description,
            template    => 'dispatcher.tt',
            data        => $data,
        }
    };

    $self->tt->process('wrapper.tt', $view, \$html);

    return $html;

}

sub format_body {
    my $self = shift;
    my $data = shift;

    my $body;
    my $type   = $self->request->header('accept');
    my $format = ($type =~ /json/) ? 'json' : 'html';;

    if ($format eq 'json') {

        $body = $self->format_json($data);

    } else {

        $body = $self->format_html($data);

    }

    return $body;

}

# -------------------------------------------------------------------------
# accessors
# -------------------------------------------------------------------------

sub app_name {
    my $self = shift;

    return $self->{'app_name'};

}

sub app_description {
    my $self = shift;

    return $self->{'app_description'};

}

sub json {
    my $self = shift;

    return $self->{'json'};

}

sub tt {
    my $self = shift;

    return $self->{'tt'};

}

sub env {
    my $self = shift;

    return $self->{'env'};

}

sub log {
    my $self = shift;

    return $self->{'log'};

}

sub alias {
    my $self = shift;

    return $self->{'alias'};

}

# -------------------------------------------------------------------------
# mutators
# -------------------------------------------------------------------------

sub errcode {
    my $self = shift;
    my $code = shift;

    $self->{'errcode'} = $code if (defined($code));

    return $self->{'errcode'};

}

sub errstr {
    my $self   = shift;
    my $string = shift;

    $self->{'errstr'} = $string if (defined($string));

    return $self->{'errstr'};

}

1;

__END__

=head1 NAME

XAS::Service::Resource - Perl extension for the XAS environment

=head1 SYNOPSIS

 use Plack;
 use Template;
 use JSON::XS;
 use Plack::App;
 use Web::Machine;
 use XAS::Service::Server;
 use XAS::Service::Resource::Root;
 use Badger::Filesystem 'File';

 my $base = 'web';
 my $name = 'testing',
 my $description = 'test web service';

 sub build_app {
    my $self = shift;

    # define base, name and description

    my $base = $self->cfg->val('app', 'base', '/home/kevin/dev/XAS-Service/trunk/web');
    my $name = $self->cfg->val('app', 'name', 'WEB Services');
    my $description = $self->cfg->val('app', 'description', 'Test api using RESTFUL HAL-JSON');

    # Template config

    my $config = {
        INCLUDE_PATH => File($base, 'root')->path,   # or list ref
        INTERPOLATE  => 1,  # expand "$var" in plain text
    };

    # create various objects

    my $template = Template->new($config);
    my $json     = JSON::XS->new->utf8();

    # allow variables with preceeding _

    $Template::Stash::PRIVATE = undef;

    # handlers, using URLMap for routing

    my $builder = Plack::Builder->new();
    my $urlmap  = Plack::App::URLMap->new();
    
    $urlmap->mount('/' => Web::Machine->new(
        resource => 'XAS::Service::Resource',
        resource_args => [
            alias           => 'root',
            template        => $template,
            json            => $json,
            app_name        => $name,
            app_description => $description
        ] )
    );

    # static files

    $urlmap->mount('/js' => Plack::App::File->new(
        root => $base . '/root/js' )
    );

    $urlmap->mount('/css' => Plack::App::File->new(
        root => $base . '/root/css')
    );

    $urlmap->mount('/yaml' => Plack::App::File->new(
        root => $base . '/root/yaml/yaml')
    );

    return $builder->to_app($urlmap->to_app);

 }

 my $interface = XAS::Service::Server->new(
     -alias   => 'server',
     -port    => 9507,
     -address => 'localhost,
     -app     => $self->build_app(),
 );

 $interface->run();

=head1 DESCRIPTION

This module is a wrapper around L<Web::Machine::Resource|https://metacpan.org/pod/Web::Machine::Resource>.
It provides the defaults that I have found useful when developing a REST based
web service.

=head1 METHODS - Web::Machine

Web::Machine provides callbacks for processing the request. This are the ones
that I have found useful to override.

=head2 init

This method interfaces the passed resource_args to accessors. It also pulls
in the XAS environment and log handling.

=head2 is_authorized

This method uses basic authenication and checks wither the user is valid. This
needs to be overridden.

=head2 options

Returns the allowed options for the service. This basically takes what
is provided by allowed_methods(), content_types_provided(),
content_types_accepted() and creates the proper headers for the response.

=head2 allowed_methods

This returns the allowed methods for the handler. The defaults are
OPTIONS GET HEAD.

=head2 post_is_create

This method returns TRUE. This allows for processing based on
content_types_provided() and content_types_accepted().

=head2 content_types_accepted

This method returns the accepted content types for this handler. This also
allows processing based on those types. The defaults are:

 'application/json'                  which will call 'from_json'
 'application/x-www-form-urlencoded' which will call 'from_html'

=head2 content_types_provided

This method returns the content types that this handler will provided. This
allows for processing based on those types. They defaults are:

 'text/html'            which will call 'to_html'
 'application/hal+json' which will call 'to_json'

=head2 charset_provided

This will return the accepted charset. The default is UTF-8.

=head2 finish_request

This method is called last and allows us to fix up error messages.

=head1 METHODS - Ours

These methods are used to make writting services easier.

=head2 get_navigation

This method returns a data structure used for navigation within the
html interface. This needs to be overridden for any useful to happen.

=head2 get_links

This method returns the links associated with this handler. Used in the html
interface and json responses. This needs to be overridden for anything useful 
to happen.

=head2 get_response

This method is called to help create a response. It calls get_navigation() and
get_links() as helpers. It returns a data structure that will be converted to
a html page or json depending on how the request was made. This needs to be
overridden for anything useful to happen.

=head2 json_to_multivalue

This method will convert json parameters into a L<Hash::MultiValue|https://metacpan.org/pod/Hash::MultiValue> object.
This is to normalize the handling of posted data.

=head2 from_json

This methods converts the JSON post data into a L<Hash::MultiValue|https://metacpan.org/pod/Hash::MultiValue> object
and calls process_params().

=head2 to_json

This method is called when a json response is required.

=head2 from_html

This methods retrieves the post parameters and calls process_params().

=head2 to_html

This method is called when a html response is required.

=head2 from_json

This method is called when request is using json.

=head2 from_html

This method is called when a request is html.

=head2 format_json

Formats the response as json.

=head2 format_html

Formats the response as html.

=head2 process_params($params)

This method processes the post parameters. This needs to be overridden.

=over 4

=item B<$params>

The parameters that need to be processed.

=back

=head1 ACCESSORS

These accessors are used to interface the arguments passed into the Web
Machine Resource.

=head2 app_name

Returns the name of the service. Primarily used for the html interface.

=head2 app_description

Return the description of the service. Primarily used for the html interface.

=head2 json

Returns the handle for JSON::XS.

=head2 tt

Returns the handle for Template.

=head2 env

Returns the handle for the XAS environment.

=head2 log

Returns the handle for the XAS logging.

=head2 alias

Returns the alias for this handler. Used for logging purposes.

=head1 MUTATORS

=head2 errcode

Allows you to set an HTTP error code. Used for error handling.

=head2 errstr

Allows you to set an error string. Used for error handling.

=head1 SEE ALSO

=over 4

=item L<Hash::MultiValue|https://metacpan.org/pod/Hash::MultiValue>

=item L<Web::Machine::Resource|https://metacpan.org/pod/Web::Machine::Resource>

=item L<Web::Machine|https://metacpan.org/pod/Web::Machine>

=item L<XAS::Service|XAS::Service>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
