package WWW::MLite; # $Id: MLite.pm 50 2019-06-21 21:05:37Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

WWW::MLite - Lite Web Application Framework

=head1 VERSION

Version 2.01

=head1 SYNOPSIS

    package MyApp;

    use base qw/WWW::MLite/;

    use HTTP::Status qw/:constants/;
    use Data::Dumper;

    __PACKAGE__->register_method( # GET /myapp
        name    => "getIndex",
        description => "Index page",
        method  => "GET",
        path    => "/myapp",
        deep    => 0,
        attrs   => {
                foo         => 'blah-blah-blah',
                bar         => 'on',
                deserialize => 0,
                serialize   => 1,
            },
        requires => undef,
        returns => undef,
        code    => sub {
        my $self = shift;
        my @params = @_;

        $self->data(Dumper({
                params => [@params],
                name   => $self->name,
                description => $self->info("description"),
                attrs  => $self->info("attrs"),
                path   => $self->info("path"),
                method => $self->info("method"),
                requires => $self->info("requires"),
                returns => $self->info("returns"),
            }));

        return HTTP_OK; # HTTP RC
    });

    1;

    package main;

    use FindBin qw/$Bin/;
    use lib "$Bin/../lib";

    use CGI;
    use File::Spec;

    my $q = new CGI;
    my $server = MyApp->new(
        project     => "MyApp",
        ident       => "myapp",
        root        => File::Spec->catdir($Bin, "conf"),
        #confopts    => {... Config::General options ...},
        configfile  => File::Spec->catfile($Bin, "conf", "myapp.conf"),
        log         => "on",
        logfd       => fileno(STDERR),
        #logfile     => '/path/to/log/file.log',
        nph         => 0, # NPH (no-parsed-header)
    );
    print $server->call($q->request_method, $q->request_uri, $q) or die($server->error);

=head1 DESCRIPTION

Lite Web Application Framework

This module allows you to quickly and easily write a REST servers

=head2 new

    my $server = MyApp->new(
        project     => "MyApp",
        ident       => "myapp",
        root        => File::Spec->catdir($Bin, "conf"),
        #confopts    => {... Config::General options ...},
        configfile  => File::Spec->catfile($Bin, "conf", "myapp.conf"),
        log         => "on",
        logfd       => fileno(STDERR),
        #logfile     => '/path/to/log/file.log',
        nph         => 0, # NPH (no-parsed-header)
    );

Returns CTK object as WWW::MLite server

=over 4

=item confopts

Optional value. L<Config::General> options

=item configfile

File of configuration

Default: /etc/myapp/myapp.conf

=item log

General switch for logging enable/disable

Default: off

Also see configuration for logging manage

=item logfd

File descriptor or fileno

Default: none (use syslog)

See L<IO::Handle>

=item logfile

Log file path. Not recommended!

=item nph

Enable or disable NPH mode (no-parsed-header)

Default: 0

See L<CGI/USING-NPH-SCRIPTS>

This option for the response subroutine only!

=item root

Root directory for project. This is NOT document root directory!

Default: /etc/myapp

=back

See also L<CTK> and L<CTK::App>

=head1 METHODS

List of available methods

=head2 call

See L</call_method>

=head2 call_method

    $server->call_method( $ENV{REQUEST_URI}, $ENV{REQUEST_METHOD}, ... );

Runs the callback function from current method with additional parameters

Note: any number of parameters can be specified,
all of them will be receive in the callback function and in your overridden the response subroutine

Returns: response content

=head2 check_http_method

    $server->check_http_method("GET"); # returns 1
    $server->check_http_method("OPTIONS"); # returns 0

Checks the availability of the HTTP method by its name and returns the status

=head2 code

    my $code = $server->code;
    my $code = $server->code( 500 );

Gets/Sets response HTTP code

Default: 200 (HTTP_OK)

See L<HTTP::Status>

=head2 cleanup

    $server->cleanup;

Cleans the all working data and resets it to default values

=head2 data

    my $data = $server->data;
    $server->data({
            param1 => "new value",
        });

Gets/Sets working data structure or HTTP content

Default: undef

See L<HTTP::Response>

=head2 head

    my $head = $server->head;
    $server->head({
            "Content-Type" => "text/plain",
        });

Gets/Sets HTTP headers

Default: "text/plain"

See L<HTTP::Headers>

=head2 info

    my $info = $server->info;
    my $description => $server->info("description");
    my $attrs = $server->info("attrs");
    my $path = $server->info("path");
    my $method = $server>info("method");
    my $requires = $server->info("requires");
    my $returns = $server->info("returns");

Returns the info structure or info-data of current method

=head2 lookup_method

    my $method = $server->lookup_method($ENV{REQUEST_URI}, $ENV{REQUEST_METHOD});

Returns $method structure from hash of registered methods; or undef if method is not registered

=head2 message

    my $message = $server->message;
    my $message = $server->message( "Internal Server Error" );

Gets/Sets response HTTP message

Default: "OK"

See L<HTTP::Status>

=head2 name

    my $name = $server->name;

Returns name of current method. Default: default

=head2 register_method

    use base qw/WWW::MLite/;

    use HTTP::Status qw/:constants/;
    use Data::Dumper;

    __PACKAGE__->register_method( # GET /myapp
        name    => "getIndex",
        description => "Index page",
        method  => "GET",
        path    => "/myapp",
        deep    => 0,
        attrs   => {
                foo         => 'blah-blah-blah',
                bar         => 'on',
                deserialize => 0,
                serialize   => 1,
            },
        requires => [
                qw/ user1 user2 userX /
            ],
        returns => {
                type => 'any',
            },
        code    => sub {
        my $self = shift;
        my @params = @_;

        # ... your method's code here ...

        return HTTP_OK; # HTTP RC
    });

Registers new method and returns operation status

B<NOTE!> This is non class method!

=over 4

=item attrs

Sets attributes of the method as hashref

Default: {}

In the method's code or response method, you can get the attribute values using the $self->info("attrs") method

=item code

Sets callback function

Default: sub { return HTTP::Status::HTTP_OK }

This callback function MUST return HTTP status code

See L<HTTP::Status>

=item deep, depth

Enables deeply scanning of path for method lookup. If this param is set to true then the
mechanism of the deeply lookuping will be enabled. For example:

For registered path /foo with enabled deep lookuping will be matched any another
incoming path that begins from /foo prefix: /foo, /foo/bar, /foo/bar/baz and etc.

Default: 0

=item description

Sets the description of method

Default: none

=item name

Sets the name of method

Default: default

=item method

Sets the HTTP method for trapping. Supported: GET, POST, PUT, DELETE.

Default: GET

=item path

Sets the URL's path for trapping

Default: /

=item requires

Array-ref structure that contains list of groups/users or any data for authorization

Default: []

=item returns

Hash-ref structure that contains schema

Default: {}

See L<JSON::Schema>, L<JSON::Validator>, L<http://json-schema.org/>

=back


=head2 middleware

The middleware method. Runs before every Your registered methods.

You can override this method in Your class.

This method MUST returns HTTP status code.
If code is a Successful status code (2xx) then Your registered method will called

For examle:

    sub response {
            my $self = shift;
            my @params = @_;

            # . . .

            return HTTP::Status::HTTP_OK
    }

=head2 response

The method for response prepare.

You can override this method in Your class.

But note! This method MUST returns serialized or plain content for output

For examle:

    sub response {
        my $self = shift;
        my @params = @_;
        my $rc = $self->code; # RC HTTP code (from yuor methods)
        my $head = $self->head; # HTTP Headers (hashref)
        my $data = $self->data; # The working data
        my $msg = $self->message || HTTP::Status::status_message($rc) || "Unknown code";

        # . . .

        my @res = (sprintf("Status: %s %s", $rc, $msg));
        push @res, sprintf("Content-Type: %s", "text/plain; charset=utf-8");
        push @res, "", $data // "";
        return join("\015\012", @res);
    }

=head2 again

Internal use only!

See L<CTK::App/again>

=head1 EXAMPLES

See all examples on METACPAN website L<https://metacpan.org/release/WWW-MLite>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

Please report any bugs to https://rt.cpan.org/.

=head1 SEE ALSO

L<CTK>, L<HTTP::Message>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '2.01';

use base qw/ CTK /;
$CTK::PLUGIN_ALIAS_MAP{log} = "WWW::MLite::Log";

use Storable qw/dclone/; # for dclone
use HTTP::Status qw/ :is /;
use HTTP::Message;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Date;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use constant {
        APP_PLUGINS => [qw/
                config log
            /],
        METHODS => {
                GET     => 1,
                POST    => 1,
                PUT     => 1,
                DELETE  => 1,
                PATCH   => 1,
            },
        EOL                 => "\015\012",
        KEY_MASK            => "%s#%s", # METHOD, PATH
        REG_KEY_MASK        => "%s#%s#%d", # CLASS, SERVER_NAME, SERVER_PORT
        DEFAULT_METHOD      => "GET",
        DEFAULT_NAME        => "default",
        DEFAULT_PATH        => "/", # Root
        DEFAULT_SERVER_NAME => "localhost",
        DEFAULT_SERVER_PORT => 80,
        DEFAULT_CONTENT_TYPE=> "text/plain",
    };

my %method_registry;

sub again {
    my $self = shift;
    my $args = $self->origin;
    my $status = $self->load_plugins(@{(APP_PLUGINS)});
    $self->{status} = 0 unless $status;
    my $config = $self->configobj;

    # Autoloading logger (data from config)
    my $log_on = $config->get("logenable") || $config->get("logenabled") || 0;
    if ($self->logmode && $log_on) {
        my $logopts = $args->{logopts} || {};
        my $logfile = defined($args->{logfile}) ? $self->logfile : $config->get("logfile"); # From args or config
        $logopts->{facility} = $args->{logfacility} if defined($args->{logfacility}); # From args only!
        if ($args->{logfd}) {
            $logopts->{fd} = $args->{logfd};
        } else {
            $logopts->{file} = $logfile if defined($logfile) && length($logfile);
        }
        $logopts->{ident} = defined($args->{ident})
            ? $args->{ident}
            : ($config->get("logident") // $self->project); # From args or config
        $logopts->{level} = defined($args->{loglevel})
            ? $args->{loglevel}
            : ($config->get("loglevel")); # From args or config
        $self->logger_init(%$logopts) or do {
            $self->error("Can't initialize logger");
            $self->{status} = 0;
        };
    }

    # Set methods
    my $registry_key = sprintf(REG_KEY_MASK,
        ref($self),
        $ENV{SERVER_NAME} || DEFAULT_SERVER_NAME,
        $ENV{SERVER_PORT} || DEFAULT_SERVER_PORT,
    );
    $self->{methods} = exists($method_registry{$registry_key}) ? $method_registry{$registry_key} : {},

    # Set name, info, code, head, data
    $self->{name} = undef; # Method name
    $self->{info} = undef; # Method info (without code)
    $self->{code} = undef; # Response code (RC)
    $self->{message} = undef; # Response message
    $self->{head} = undef; # Response headers
    $self->{data} = undef; # Response data
    $self->{request_method} = undef; # Request method
    $self->{request_uri} = undef; # Request uri

    return $self;
}

sub register_method {
    my $class = shift; # Caller's class
    croak("Can't use reference in class name context") if ref($class);
    my %info = @_;
    my $registry_key = sprintf(REG_KEY_MASK,
        $class,
        $ENV{SERVER_NAME} || DEFAULT_SERVER_NAME,
        $ENV{SERVER_PORT} || DEFAULT_SERVER_PORT,
    );
    $method_registry{$registry_key} = {} unless exists($method_registry{$registry_key});
    my $methods = $method_registry{$registry_key};

    # Method & Path
    my $meth = $info{method} || DEFAULT_METHOD;
    $meth = DEFAULT_METHOD unless grep {$_ eq $meth} keys %{(METHODS())};
    my $path = $info{path} // "";
    $path =~ s/\/+$//;
    $path = DEFAULT_PATH unless length($path);

    # Meta
    my $name = $info{name} || DEFAULT_NAME;
    my $code = $info{code} || sub {return HTTP::Status::HTTP_OK};
    my $attrs = $info{attrs} && is_hash($info{attrs}) ? $info{attrs} : {};
    my $returns = $info{returns} && is_hash($info{returns}) ? $info{returns} : {};
    my $description = $info{description} || "";
    my $deep = $info{deep} || $info{depth} || 0;
    my $requires = array($info{requires} || []);

    # Key
    my $key = sprintf(KEY_MASK, $meth, $path);
    if ($methods->{$key}) {
        my $tname = $methods->{$key}{name} || DEFAULT_NAME;
        return 0 if $tname ne $name;
    }

    $methods->{$key} = {
            method  => $meth,
            path    => $path,
            name    => $name,
            code    => $code,
            deep    => $deep,
            requires=> $requires,
            attrs   => $attrs,
            returns => $returns,
            description => $description,
        };
    return 1;
}
sub check_http_method {
    my $self = shift;
    my $meth = shift;
    return 0 unless $meth;
    return 1 if $meth eq 'HEAD';
    my $meths = METHODS;
    return $meths->{$meth} ? 1 : 0;
}

sub name {
    my $self = shift;
    return $self->{name} || DEFAULT_NAME;
}
sub info {
    my $self = shift;
    my $name = shift;
    my $meta = dclone($self->{info} || {name => $self->name});
    return $meta unless defined($name);
    return undef unless defined $meta->{$name};
    return $meta->{$name};
}
sub code {
    my $self = shift;
    my $value = shift;
    return fv2zero($self->{code}) unless defined($value);
    $self->{code} = $value || HTTP::Status::HTTP_OK;
    return $self->{code};
}
sub message {
    my $self = shift;
    my $value = shift;
    return $self->{message} unless defined($value);
    $self->{message} = $value || HTTP::Status::status_message(HTTP::Status::HTTP_OK);
    return $self->{message};
}
sub head {
    my $self = shift;
    my $struct = shift;
    return $self->{head} unless defined($struct);
    $self->{head} = $struct;
    return $struct;
}
sub data {
    my $self = shift;
    my $struct = shift;
    return $self->{data} unless defined($struct);
    $self->{data} = $struct;
    return $struct;
}

sub lookup_method {
    my $self = shift;
    my ($imeth, $ipath) = @_;

    # Method
    my $meth = uc($imeth || DEFAULT_METHOD);
    $meth = "GET" if $meth eq 'HEAD';
    unless ($self->check_http_method($meth)) {
        $self->error(sprintf("The HTTP %s method not allowed", $meth));
        return undef;
    }

    # Path
    my $path = $ipath || DEFAULT_PATH;
    $path =~ s/[?\#](.*)$//;
    $path =~ s/\/+$//;
    $path = DEFAULT_PATH unless length($path);

    # Get method
    my $name;
    my $key = sprintf(KEY_MASK, $meth, $path);
    my $methods = $self->{methods};
    # ...by key
    return $methods->{$key} if $methods->{$key}
        && $methods->{$key}{name}
        && $methods->{$key}{code};
    # ...by path
    foreach my $p (_scan_backward($path)) {
        my $ikey = sprintf(KEY_MASK, $meth, $p);
        return $methods->{$ikey} if $methods->{$ikey}
            && $methods->{$ikey}{deep}
            && $methods->{$ikey}{name}
            && $methods->{$ikey}{code};
    }
    $self->error(sprintf("Method not found (%s %s)", $meth, $path));
    return undef;
}
sub call_method {
    my $self = shift;
    my $meth = shift;
    my $path = shift;
    my @params = @_;
    $self->cleanup;
    $self->{request_method} = $meth;
    $self->{request_uri} = $path;
    my $method = $self->lookup_method($meth, $path) or return;
    unless(ref($method) eq 'HASH') {
        $self->error("Incorrect method structure");
        return;
    }

    # Get info
    my %info;
    my $func;
    foreach my $k (keys %$method) {
        next unless defined $k;
        if ($k eq 'code') {
            $func = $method->{code};
            next;
        } elsif ($k eq 'name') {
            $self->{name} = $method->{name};
        }
        $info{$k} = $method->{$k};
    }
    $self->{info} = dclone(\%info);

    # Call middleware method
    my $rc = $self->middleware(@params);

    # Call method
    if ($rc && !is_success($rc)) {
        # Skip!
    } elsif (ref($func) eq 'CODE') {
        $rc = &$func($self, @params);
    } else {
        $self->message(sprintf("The code of method %s not found!", $self->name));
        $rc = HTTP::Status::HTTP_NOT_IMPLEMENTED;
    }
    $self->{code} = $rc;

    # Call response method
    unless (HTTP::Status::status_message($rc)) {
        $self->message(sprintf("Method %s returns incorrect HTTP status code!", $self->name));
        $self->{code} = HTTP::Status::HTTP_INTERNAL_SERVER_ERROR;
    }
    return $self->response(@params);
}
sub call { goto &call_method }

sub cleanup {
    my $self = shift;
    $self->error(""); # Flush error
    $self->{name} = undef; # Method name
    $self->{info} = undef; # Method info (without code)
    $self->{code} = undef; # Response code (RC)
    $self->{message} = undef; # Response message
    $self->{head} = undef; # Response headers
    $self->{data} = undef; # Response data
    $self->{request_method} = undef; # Request method
    $self->{request_uri} = undef; # Request uri
    return 1;
}

sub middleware {
    my $self = shift;
    return HTTP::Status::HTTP_OK;
}
sub response {
    my $self = shift;
    my $rc = $self->code;
    my $head = $self->head;
    my $data = $self->data;
    my $msg = $self->message || HTTP::Status::status_message($rc) || "Unknown code";

    # Content
    my $dct = DEFAULT_CONTENT_TYPE;
    my $content = $data // "";
    $content = "" if $rc =~ /^(1\d\d|[23]04)$/; # make sure content we have no content
    if (utf8::is_utf8($content)) {
        utf8::encode($content);
        $dct .= "; charset=utf-8";
    }
    my $cl = length($content);
    $cl += length("\n") if $self->origin->{nph}; # Hack for HTTP::Message::as_string (eol char)

    # Headers
    my $h = HTTP::Headers->new(Status => sprintf("%s %s", $rc, $msg));
    if (is_void($head)) { # No data!
        $h->header('Server' => sprintf("%s/%s", __PACKAGE__, $VERSION));
        $h->header('Connection' => 'close');
        $h->header('Date' => HTTP::Date::time2str(time()));
        $h->header('Content-Type' => $dct);
    } elsif (is_hash($head)) { # Data!
        $h->header(%$head);
    }
    $h->header('Content-Length' => $cl) if $cl && !$h->header('Content-Length');

    # Response
    my $ishead = $self->{request_method} && $self->{request_method} eq 'HEAD' ? 1 : 0;
    my $r = HTTP::Response->new($rc, $msg, $h, ($cl && !$ishead ? $content : ""));

    # Done!
    return $self->origin->{nph}
        ? $r->as_string
        : join(EOL, $r->{'_headers'}->as_string(EOL), ($cl && !$ishead ? $content : ""));
}

sub _scan_backward { # Returns for /foo/bar/baz array: /foo/bar/baz, /foo/bar, /foo, /
    my $p = shift // '';
    my @out = ($p) if length($p) && $p ne '/';
    while ($p =~ s/\/[^\/]+$//) {
        push @out, $p if length($p)
    }
    push @out, '/';
    return @out;
}

1;

__END__
