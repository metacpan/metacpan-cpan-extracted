package Test::HTTP::LocalServer;
use strict;
use 5.008; # We use "fancy" opening of lexical filehandle, see below
use FindBin;
use File::Spec;
use File::Temp;
use URI::URL qw();
use Carp qw(carp croak);
use Cwd;
use File::Basename;
use Time::HiRes qw ( time sleep );
use HTTP::Tiny;

our $VERSION = '0.69';

=head1 NAME

Test::HTTP::LocalServer - spawn a local HTTP server for testing

=head1 SYNOPSIS

  use HTTP::Tiny;
  my $server = Test::HTTP::LocalServer->spawn;

  my $res = HTTP::Tiny->new->get( $server->url );
  print $res->{content};

  $server->stop;

=head1 DESCRIPTION

This module implements a tiny web server suitable for running "live" tests
of HTTP clients against it. It also takes care of cleaning C<%ENV> from settings
that influence the use of a local proxy etc.

Use this web server if you write an HTTP client and want to exercise its
behaviour in your test suite without talking to the outside world.

=head1 METHODS

=head2 C<Test::HTTP::LocalServer-E<gt>spawn %ARGS>

  my $server = Test::HTTP::LocalServer->spawn;

This spawns a new HTTP server. The server will stay running until
  $server->stop
is called.

Valid arguments are :

=over 4

=item *

C<< html => >> scalar containing the page to be served

=item *

C<< file => >> filename containing the page to be served

=item *

C<<  debug => 1 >> to make the spawned server output debug information

=item *

C<<  eval => >> string that will get evaluated per request in the server

Try to avoid characters that are special to the shell, especially quotes.
A good idea for a slow server would be

  eval => sleep+10

=back

All served HTML will have the first %s replaced by the current location.

The following entries will be removed from C<%ENV> when making a request:

    HTTP_PROXY
    http_proxy
    HTTP_PROXY_ALL
    http_proxy_all
    HTTPS_PROXY
    https_proxy
    CGI_HTTP_PROXY
    ALL_PROXY
    all_proxy

=cut

sub get {
    my( $url ) = @_;
    local *ENV;
    delete @ENV{qw(
      HTTP_PROXY http_proxy CGI_HTTP_PROXY
      HTTPS_PROXY https_proxy HTTP_PROXY_ALL http_proxy_all
      ALL_PROXY
      all_proxy
    )};
    my $response = HTTP::Tiny->new->get($url);
    $response->{content}
}

sub spawn_child_win32 { my ( $self, @cmd ) = @_;
    system(1, @cmd)
}

sub spawn_child_posix { my ( $self, @cmd ) = @_;
    require POSIX;
    POSIX->import("setsid");

    # daemonize
    defined(my $pid = fork())   || die "can't fork: $!";
    if( $pid ) {    # non-zero now means I am the parent
        return $pid;
    };
    #chdir("/")                  || die "can't chdir to /: $!";

    # We are the child, close about everything, then exec
    (setsid() != -1)            || die "Can't start a new session: $!";
    #open(STDERR, ">&STDOUT")    || die "can't dup stdout: $!";
    #open(STDIN,  "< /dev/null") || die "can't read /dev/null: $!";
    #open(STDOUT, "> /dev/null") || die "can't write to /dev/null: $!";
    exec @cmd or warn $!;
}

sub spawn_child { my ( $self, @cmd ) = @_;
    my ($pid);
    if( $^O =~ /mswin/i ) {
        $pid = $self->spawn_child_win32(@cmd)
    } else {
        $pid = $self->spawn_child_posix(@cmd)
    };

    return $pid
}

sub spawn {
  my ($class,%args) = @_;
  my $self = { %args };
  bless $self,$class;

  local $ENV{TEST_HTTP_VERBOSE};
  $ENV{TEST_HTTP_VERBOSE}= 1
    if (delete $args{debug});

  $self->{delete} = [];
  if (my $html = delete $args{html}) {
    # write the html to a temp file
    my ($fh,$tempfile) = File::Temp::tempfile();
    binmode $fh;
    print $fh $html
      or die "Couldn't write tempfile $tempfile : $!";
    close $fh;
    push @{$self->{delete}},$tempfile;
    $args{file} = $tempfile;
  };
  my ($tmpfh,$logfile) = File::Temp::tempfile();
  close $tmpfh;
  push @{$self->{delete}},$logfile;
  $self->{logfile} = $logfile;
  my $web_page = delete $args{file} || "";

  my $file = __PACKAGE__;
  $file =~ s!::!/!g;
  $file .= '.pm';
  my $server_file = File::Spec->catfile( dirname( $INC{$file} ),'log-server' );
  my ($fh,$url_file) = File::Temp::tempfile;
  close $fh; # race condition, but oh well
  my @opts = ("-f", $url_file);
  push @opts, "-e" => delete($args{ eval })
      if $args{ eval };

  my @cmd=( $^X, $server_file, $web_page, $logfile, @opts );
  my $pid = $self->spawn_child(@cmd);
  my $timeout = time +2;
  while( time < $timeout and (-s $url_file <= 15)) {
      sleep( 0.1 ); # overkill, but good enough for the moment
  }

  my $server;
  while( time < $timeout and !open $server, '<', $url_file ) {
      sleep(0.1);
  };
  $server
      or die "Couldn't read back URL from '$url_file': $!";

  my $url = <$server>;
  close $server;
  unlink $url_file;
  chomp $url;
  die "Couldn't read back local server url"
      unless $url;

  $self->{_pid} = $pid;
  $self->{_server_url} = URI::URL->new($url);

  $self;
};

=head2 C<< $server->port >>

This returns the port of the current server. As new instances
will most likely run under a different port, this is convenient
if you need to compare results from two runs.

=cut

sub port {
  carp __PACKAGE__ . "::port called without a server" unless $_[0]->server_url;
  $_[0]->server_url->port
};

=head2 C<< $server->url >>

This returns the L<URI> where you can contact the server. This url
is valid until the C<$server> goes out of scope or you call

  $server->stop;

The returned object is a copy that you can modify at your leisure.

=cut

sub url {
  $_[0]->server_url->abs
};

=head2 C<< $server->server_url >>

This returns the L<URI> object of the server URL. Use L</$server->url> instead.
Use this object if you want to modify the hostname or other properties of the
server object.

Consider this basically an emergency accessor. In about every case,
using C<< ->url() >> does what you want.

=cut

sub server_url {
  $_[0]->{_server_url}
};

=head2 C<< $server->stop >>

This stops the server process by requesting a special
url.

=cut

sub stop {
    get( $_[0]->server_url() . "quit_server" );
    undef $_[0]->{_server_url};
    wait;
    #my $retries = 10;
    #while(--$retries and CORE::kill( 0 => $_[0]->{ _pid } )) {
        #warn "Waiting for '$_[0]->{ _pid }'";
        #sleep 1; # to give the child a chance to go away
    #};
    #if( ! $retries ) {
        #$_[0]->kill;
    #};
};

=head2 C<< $server->kill >>

This kills the server process via C<kill>. The log
cannot be retrieved then.

=cut

sub kill {
  CORE::kill( 'KILL' => $_[0]->{ _pid } )
      or warn "Couldn't kill pid '$_[0]->{ _pid }': $!";
  wait;
  undef $_[0]->{_server_url};
  undef $_[0]->{_pid};
};

=head2 C<< $server->get_log >>

This returns the
output of the server process. This output will be a list of
all requests made to the server concatenated together
as a string.

=cut

sub get_log {
  my ($self) = @_;
  return get( $self->server_url() . "get_server_log" );
};

sub DESTROY {
  $_[0]->stop if $_[0]->server_url;
  for my $file (@{$_[0]->{delete}}) {
    unlink $file or warn "Couldn't remove tempfile $file : $!\n";
  };
  if( $_[0]->{_pid } and CORE::kill( 0 => $_[0]->{_pid })) {
      $_[0]->kill; # boom
  };
};

=head2 C<< $server->local >>

  my $url = $server->local('foo.html');
  # file:///.../foo.html

Returns an URL for a local file which will be read and served
by the webserver. The filename must
be a relative filename relative to the location of the current
program.

=cut

sub local {
    my ($self, $htmlfile) = @_;
    require File::Spec;
    my $fn= File::Spec->file_name_is_absolute( $htmlfile )
          ? $htmlfile
          : File::Spec->rel2abs(
                 File::Spec->catfile(dirname($0),$htmlfile),
                 Cwd::getcwd(),
             );
    $fn =~ s!\\!/!g; # fakey "make file:// URL"

    $self->local_abs($fn)
}

=head1 URLs implemented by the server

=head2 arbitrary content C<< $server->content($html) >>

  $server->content(<<'HTML');
      <script>alert("Hello World");</script>
  HTML

The URL will contain the HTML as supplied. This is convenient for supplying
Javascript or special URL to your user agent.

=head2 download C<< $server->download($name) >>

This URL will send a file with a C<Content-Disposition> header and indicate
the suggested filename as passed in.

=head2 302 redirect C<< $server->redirect($target) >>

This URL will issue a redirect to C<$target>. No special care is taken
towards URL-decoding C<$target> as not to complicate the server code.
You need to be wary about issuing requests with escaped URL parameters.

=head2 401 basic authentication challenge C<< $server->basic_auth($user, $pass) >>

This URL will issue a 401 basic authentication challenge. The expected user
and password are encoded in the URL.

    my $challenge_url = $server->basic_auth('foo','secret');
    my $wrong_pw = URI->new( $challenge_url );
    $wrong_pw->userinfo('foo:hunter2');
    $res = HTTP::Tiny->new->get($wrong_pw);
    is $res->{status}, 401, "We get the challenge with a wrong user/password";

=head2 404 error C<< $server->error_notfound($target) >>

This URL will response with status code 404.

=head2 Timeout C<< $server->error_timeout($seconds) >>

This URL will send a 599 error after C<$seconds> seconds.

=head2 Timeout+close C<< $server->error_close($seconds) >>

This URL will send nothing and close the connection after C<$seconds> seconds.

=head2 Error in response content C<< $server->error_after_headers >>

This URL will send headers for a successful response but will close the
socket with an error after 2 blocks of 16 spaces have been sent.

=head2 Chunked response C<< $server->chunked >>

This URL will return 5 blocks of 16 spaces at a rate of one block per second
in a chunked response.

=head2 Surprisingly large bzip2 encoded response C<< $server->bzip2 >>

This URL will return a short HTTP response that expands to 16M body.

=head2 Surprisingly large gzip encoded response C<< $server->gzip >>

This URL will return a short HTTP response that expands to 16M body.

=head2 Other URLs

All other URLs will echo back the cookies and query parameters.

=cut

use vars qw(%urls);
%urls = (
    'local_abs' => 'local/%s',
    'redirect' => 'redirect/%s',
    'error_notfound' => 'error/notfound/%s',
    'error_timeout' => 'error/timeout/%s',
    'error_close' => 'error/close/%s',
    'error_after_headers' => 'error/after_headers',
    'gzip' => 'large/gzip/16M',
    'bzip2' => 'large/bzip/16M',
    'chunked' => 'chunks',
    'download' => 'download/%s',
    'basic_auth' => 'basic_auth/%s/%s',
);
for (keys %urls) {
    no strict 'refs';
    my $name = $_;
    *{ $name } = sub {
        my $self = shift;
        $self->url . sprintf $urls{ $name }, @_;
    };
};

sub content {
    my( $self, $html ) = @_;
    (my $encoded = $html) =~ s!([^\w])!sprintf '%%%02x',$1!ge;
    $self->url . $encoded;
}

=head1 EXPORT

None by default.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Copyright (C) 2003-2019 Max Maischein

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

Please contact me if you find bugs or otherwise improve the module. More tests
are also very welcome !

=head1 SEE ALSO

L<WWW::Mechanize>,L<WWW::Mechanize::Shell>,L<WWW::Mechanize::Firefox>

=cut

1;
