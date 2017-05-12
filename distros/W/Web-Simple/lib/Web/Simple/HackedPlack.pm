# This is Plack::Server::CGI, copied almost verbatim.
# Except I inlined the bits of Plack::Util it needed.
# Because it loads a number of modules that I didn't.
# miyagawa, I'm sorry to butcher your code like this.
# The apology would have been in the form of a haiku.
# But I needed more syllables than that would permit.
# So I thought perhaps I'd make it bricktext instead.
#   -- love, mst

# Hide from PAUSE
package
    Plack::Server::CGI;
use strict;
use warnings;
use IO::Handle;
BEGIN {

    # Hide from PAUSE
    package
        Plack::Util;

    sub foreach {
        my($body, $cb) = @_;

        if (ref $body eq 'ARRAY') {
            for my $line (@$body) {
                $cb->($line) if length $line;
            }
        } else {
            local $/ = \4096 unless ref $/;
            while (defined(my $line = $body->getline)) {
                $cb->($line) if length $line;
            }
            $body->close;
        }
    }
    sub TRUE()  { 1==1 }
    sub FALSE() { !TRUE }
}

sub new { bless {}, shift }

sub run {
    my ($self, $app) = @_;
    my %env;
    while (my ($k, $v) = each %ENV) {
        next unless $k =~ qr/^(?:REQUEST_METHOD|SCRIPT_NAME|PATH_INFO|QUERY_STRING|SERVER_NAME|SERVER_PORT|SERVER_PROTOCOL|CONTENT_LENGTH|CONTENT_TYPE|REMOTE_ADDR|REQUEST_URI)$|^HTTP_/;
        $env{$k} = $v;
    }
    $env{'HTTP_COOKIE'}   ||= $ENV{COOKIE};
    $env{'psgi.version'}    = [ 1, 0 ];
    $env{'psgi.url_scheme'} = ($ENV{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http';
    $env{'psgi.input'}      = *STDIN;
    $env{'psgi.errors'}     = *STDERR;
    $env{'psgi.multithread'}  = Plack::Util::FALSE;
    $env{'psgi.multiprocess'} = Plack::Util::TRUE;
    $env{'psgi.run_once'}     = Plack::Util::TRUE;
    my $res = $app->(\%env);
    print "Status: $res->[0]\n";
    my $headers = $res->[1];
    while (my ($k, $v) = splice(@$headers, 0, 2)) {
        print "$k: $v\n";
    }
    print "\n";

    my $body = $res->[2];
    my $cb = sub { print STDOUT $_[0] };

    Plack::Util::foreach($body, $cb);
}

1;
__END__

=head1 SYNOPSIS

    ## in your .cgi
    #!/usr/bin/perl
    use Plack::Server::CGI;

    # or Plack::Util::load_psgi("/path/to/app.psgi");
    my $app = sub {
        my $env = shift;
        return [
            200,
            [ 'Content-Type' => 'text/plain', 'Content-Length' => 13 ],
            'Hello, world!',
        ];
    };

    Plack::Server::CGI->new->run($app);

=head1 SEE ALSO

L<Plack::Server::Base>

=cut


