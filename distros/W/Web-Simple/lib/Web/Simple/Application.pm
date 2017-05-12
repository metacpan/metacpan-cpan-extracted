package Web::Simple::Application;

use Scalar::Util 'weaken';

use Moo;

has 'config' => (
  is => 'ro',
  default => sub {
    my ($self) = @_;
    +{ $self->default_config }
  },
  trigger => sub {
    my ($self, $value) = @_;
    my %default = $self->default_config;
    my @not = grep !exists $value->{$_}, keys %default;
    @{$value}{@not} = @default{@not};
  }
);

sub default_config { () }

has '_dispatcher' => (is => 'lazy');

sub _build__dispatcher {
  my $self = shift;
  require Web::Dispatch;
  my $final = $self->_build_final_dispatcher;

  # We need to weaken both the copy of $self that the
  # app parameter will close over and the copy that'll
  # be passed through as a node argument.
  #
  # To ensure that this doesn't then result in us being
  # DESTROYed unexpectedly early, our to_psgi_app method
  # closes back over $self

  weaken($self);
  my %dispatch_args = (
    dispatch_app => sub { $self->dispatch_request(@_), $final },
    dispatch_object => $self
  );
  weaken($dispatch_args{dispatch_object});
  Web::Dispatch->new(%dispatch_args);
}

sub _build_final_dispatcher {
  [ 404, [ 'Content-type', 'text/plain' ], [ 'Not found' ] ]
}

sub run_if_script {
  # ->to_psgi_app is true for require() but also works for plackup
  return $_[0]->to_psgi_app if caller(1);
  my $self = ref($_[0]) ? $_[0] : $_[0]->new;
  $self->run(@_);
}

sub _run_cgi {
  my $self = shift;
  require Plack::Handler::CGI;
  Plack::Handler::CGI->new->run($self->to_psgi_app);
}

sub _run_fcgi {
  my $self = shift;
  require Plack::Handler::FCGI;
  Plack::Handler::FCGI->new->run($self->to_psgi_app);
}

sub to_psgi_app {
  my $self = ref($_[0]) ? $_[0] : $_[0]->new;
  my $app = $self->_dispatcher->to_app;

  # Close over $self to keep $self alive even though
  # we weakened the copies the dispatcher has; the
  # if 0 causes the ops to be optimised away to
  # minimise the performance impact and avoid void
  # context warnings while still doing the closing
  # over part. As Mithaldu said: "Gnarly." ...

  return sub { $self if 0; goto &$app; };
}

sub run {
  my $self = shift;
  if (
    $ENV{PHP_FCGI_CHILDREN} || $ENV{FCGI_ROLE} || $ENV{FCGI_SOCKET_PATH}
    || ( -S STDIN && !$ENV{GATEWAY_INTERFACE} )
    # If STDIN is a socket, almost certainly FastCGI, except for mod_cgid
    ) {
    return $self->_run_fcgi;
  } elsif ($ENV{GATEWAY_INTERFACE}) {
    return $self->_run_cgi;
  }
  unless (@ARGV && $ARGV[0] =~ m{(^[A-Z/])|\@}) {
    return $self->_run_cli(@ARGV);
  }

  my @args = @ARGV;

  unshift(@args, 'GET') if $args[0] !~ /^[A-Z]/;

  $self->_run_cli_test_request(@args);
}

sub _test_request_spec_to_http_request {
  my ($self, $method, $path, @rest) = @_;

  # if it's a reference, assume a request object
  return $method if ref($method);

  if ($path =~ s/^(.*?)\@//) {
    my $basic = $1;
    require MIME::Base64;
    unshift @rest, 'Authorization:', 'Basic '.MIME::Base64::encode($basic);
  }

  my $request = HTTP::Request->new($method => $path);

  my @params;

  while (my ($header, $value) = splice(@rest, 0, 2)) {
    unless ($header =~ s/:$//) {
      push @params, $header, $value;
    }
    $header =~ s/_/-/g;
    if ($header eq 'Content') {
      $request->content($value);
    } else {
      $request->headers->push_header($header, $value);
    }
  }

  if (($method eq 'POST' or $method eq 'PUT') and @params) {
    my $content = do {
      require URI;
      my $url = URI->new('http:');
      $url->query_form(@params);
      $url->query;
    };
    $request->header('Content-Type' => 'application/x-www-form-urlencoded');
    $request->header('Content-Length' => length($content));
    $request->content($content);
  }

  return $request;
}

sub run_test_request {
  my ($self, @req) = @_;

  require HTTP::Request;

  require Plack::Test;

  my $request = $self->_test_request_spec_to_http_request(@req);

  Plack::Test::test_psgi(
    $self->to_psgi_app, sub { shift->($request) }
  );
}

sub _run_cli_test_request {
  my ($self, @req) = @_;
  my $response = $self->run_test_request(@req);

  binmode(STDOUT); binmode(STDERR); # for win32

  print STDERR $response->status_line."\n";
  print STDERR $response->headers_as_string("\n")."\n";
  my $content = $response->content;
  $content .= "\n" if length($content) and $content !~ /\n\z/;
  print STDOUT $content if $content;
}

sub _run_cli {
  my $self = shift;
  die $self->_cli_usage;
}

sub _cli_usage {
  "To run this script in CGI test mode, pass a URL path beginning with /:\n".
  "\n".
  "  $0 /some/path\n".
  "  $0 /\n"
}

1;

=head1 NAME

Web::Simple::Application - A base class for your Web-Simple application

=head1 DESCRIPTION

This is a base class for your L<Web::Simple> application.  You probably don't
need to construct this class yourself, since L<Web::Simple> does the 'heavy
lifting' for you in that regards.

=head1 METHODS

This class exposes the following public methods.

=head2 default_config

Merges with the C<config> initializer to provide configuration information for
your application.  For example:

  sub default_config {
    (
      title => 'Bloggery',
      posts_dir => $FindBin::Bin.'/posts',
    );
  }

Now, the C<config> attribute of C<$self>  will be set to a HashRef
containing keys 'title' and 'posts_dir'.

The keys from default_config are merged into any config supplied, so
if you construct your application like:

  MyWebSimpleApp::Web->new(
    config => { title => 'Spoon', environment => 'dev' }
  )

then C<config> will contain:

  {
    title => 'Spoon',
    posts_dir => '/path/to/myapp/posts',
    environment => 'dev'
  }

=head2 run_if_script

The run_if_script method is designed to be used at the end of the script
or .pm file where your application class is defined - for example:

  ## my_web_simple_app.pl
  #!/usr/bin/env perl
  use Web::Simple 'HelloWorld';

  {
    package HelloWorld;

    sub dispatch_request {
      sub (GET) {
        [ 200, [ 'Content-type', 'text/plain' ], [ 'Hello world!' ] ]
      },
      sub () {
        [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
      }
    }
  }

  HelloWorld->run_if_script;

This returns a true value, so your file is now valid as a module - so

  require 'my_web_simple_app.pl';

  my $hw = HelloWorld->new;

will work fine (and you can rename it to lib/HelloWorld.pm later to make it
a real use-able module).

However, it detects if it's being run as a script (via testing $0) and if
so attempts to do the right thing.

If run under a CGI environment, your application will execute as a CGI.

If run under a FastCGI environment, your application will execute as a
FastCGI process (this works both for dynamic shared-hosting-style FastCGI
and for apache FastCgiServer style setups).

If run from the commandline with a URL path, it runs a GET request against
that path -

  $ perl -Ilib examples/hello-world/hello-world.cgi /
  200 OK
  Content-Type: text/plain
  
  Hello world!

You can also provide a method name -

  $ perl -Ilib examples/hello-world/hello-world.cgi POST /
  405 Method Not Allowed
  Content-Type: text/plain
  
  Method not allowed

For a POST or PUT request, pairs on the command line will be treated
as form variables. For any request, pairs on the command line ending in :
are treated as headers, and 'Content:' will set the request body -

  $ ./myapp POST / Accept: text/html form_field_name form_field_value
  
  $ ./myapp POST / Content-Type: text/json Content: '{ "json": "here" }'

The body of the response is sent to STDOUT and the headers to STDERR, so

  $ ./myapp GET / >index.html

will generally do the right thing.

To send basic authentication credentials, use user:pass@ syntax -

  $ ./myapp GET bob:secret@/protected/path

Additionally, you can treat the file as though it were a standard PSGI
application file (*.psgi).  For example you can start up up with C<plackup>

  plackup my_web_simple_app.pl

or C<starman>

  starman my_web_simple_app.pl

=head2 to_psgi_app

This method is called by L</run_if_script> to create the L<PSGI> app coderef
for use via L<Plack> and L<plackup>. If you want to globally add middleware,
you can override this method:

  use Web::Simple 'HelloWorld';
 
  {
    package HelloWorld;
    use Plack::Builder;
  
    around 'to_psgi_app', sub {
      my ($orig, $self) = (shift, shift);
      my $app = $self->$orig(@_); 
      builder {
        enable ...; ## whatever middleware you want
        $app;
      };
    };
  }

This method can also be used to mount a Web::Simple application within
a separate C<*.psgi> file -

  use strictures 1;
  use Plack::Builder;
  use WSApp;
  use AnotherWSApp;

  builder {
    mount '/' => WSApp->to_psgi_app;
    mount '/another' => AnotherWSApp->to_psgi_app;
  };

This method can be called as a class method, in which case it implicitly
calls ->new, or as an object method ... in which case it doesn't.

=head2 run

Used for running your application under stand-alone CGI and FCGI modes.

I should document this more extensively but run_if_script will call it when
you need it, so don't worry about it too much.

=head2 run_test_request

  my $res = $app->run_test_request(GET => '/' => %headers);

  my $res = $app->run_test_request(POST => '/' => %headers_or_form);

  my $res = $app->run_test_request($http_request);

Accepts either an L<HTTP::Request> object or ($method, $path) and runs that
request against the application, returning an L<HTTP::Response> object.

If the HTTP method is POST or PUT, then a series of pairs can be passed after
this to create a form style message body. If you need to test an upload, then
create an L<HTTP::Request> object by hand or use the C<POST> subroutine
provided by L<HTTP::Request::Common>.

If you prefix the URL with 'user:pass@' this will be converted into
an Authorization header for HTTP basic auth:

  my $res = $app->run_test_request(
              GET => 'bob:secret@/protected/resource'
            );

If pairs are passed where the key ends in :, it is instead treated as a
headers, so:

  my $res = $app->run_test_request(
              POST => '/',
             'Accept:' => 'text/html',
              some_form_key => 'value'
            );

will do what you expect. You can also pass a special key of Content: to
set the request body:

  my $res = $app->run_test_request(
              POST => '/',
              'Content-Type:' => 'text/json',
              'Content:' => '{ "json": "here" }',
            );

=head1 AUTHORS

See L<Web::Simple> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Web::Simple> for the copyright and license.

=cut
