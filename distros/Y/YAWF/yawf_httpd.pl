#!/usr/bin/perl -Ilib -I.
# Include lib of the project dir and the project dir itself
# (assuming that this task has been started from the project dir)

=pod

=head1 YAWF-Webserver

This is a simple webserver for testing projects.

Point your browser to http://127.0.0.1:8000/ to get access to the
development version of your project. It reloads changed modules on
every request.

The request log, debug output and errors go to STDOUT.

WARNING: This server is ONLY FOR DEVELOPMENT, it has nearly no security
features and can't handle more than one request at the same time!

=cut

sub read_config {
open my $cfgfile, 'test_httpd.cfg';
$Port = <$cfgfile>;
$wwwroot = <$cfgfile>;
close $cfgfile;
chomp $Port;
chomp $wwwroot;
$Port ||= 8000;
$wwwroot ||= '.';
}

{

    package MyWebServer;

    use HTTP::Server::Simple::CGI;
    use base qw(HTTP::Server::Simple::CGI);

    use YAWF;
    use YAWF::Request;

    sub setup {
        my $self = shift;
        my %Data = @_;
        for ( keys(%Data) ) {
            $self->{$_} = $Data{$_};
        }
        $self->setup_environment_from_metadata(@_);
        return 1;
    }

    sub headers {
        my $self = shift;
        $self->{headers} = { @{ $_[0] } };
        HTTP::Server::Simple::CGI->headers(@_);
    }

    sub handle_request {
        my $self = shift;
        my $cgi  = shift;

        print STDERR "*** " . $self->{path} . " ***\n";

        if ( $self->{path} =~ /\.(ico|png|gif|jpe?g|css|js)$/ ) {

            # Static files don't go through the request handler
            &main::read_config unless defined($wwwroot);

            my $file = $main::wwwroot . $self->{path};    # Path should start with '/'
            $file = '' if $self->{path} =~ /\.\./;     # Simple security check

            if ( open( fh, $file ) ) {
                print "HTTP/1.1 200 OK\r\n" . "Content-type: ";
                if    ( $self->{path} =~ /\.png$/ )   { print "image/png"; }
                elsif ( $self->{path} =~ /\.gif$/ )   { print "image/gif"; }
                elsif ( $self->{path} =~ /\.jpe?g$/ ) { print "image/jpeg"; }
                else                                  { print "text/plain"; }
                print "\r\n\r\n";

                print <fh>;
                close fh;
            }
            else {
                print "HTTP/1.1 404 Not found\r\n"
                  . "Content-type: text/plain\r\n\r\nError opening $file: $!\n";
                print STDERR "Error opening $file: $!\n";
            }
        }
        elsif ( fork == 0 ) {

            eval {

                my $domain = $self->{headers}->{Host};
                $domain =~ s/\:\d+$//;

                require YAWF::Request;
                my $job = YAWF::Request->new(
                    domain       => $domain,
                    uri          => $self->{path},
                    args_GET     => $self->{query_string},
                    method       => $self->{method},
                    headers      => $self->{headers},
                    remote_ip    => $self->{peeraddr},
                    documentroot => '.',
                    CGI          => $cgi,
                    error        => sub {
                        print STDERR scalar( localtime(time) )
                          . ' HTTPD-ERROR '
                          . join( ' ', @_ ) . "\n";
                    },
                    send_status => sub { print "HTTP/1.1 $_[0] OK\n"; },
                    send_header => sub { print "$_[0]: $_[1]\n"; },
                    send_body   => sub { print "\n"; print @_; },
                );
                $job->run or print "WARNING: Job returned with zero value!\n";

            };

            if ($@) {
                print
                  "HTTP/1.1 200 OK\r\n\r\n<h1>Error</h1><tt>\n$@\n</tt>\r\n";
            }

            exit;

        }

        return 1;
    }

}

# start the server on port 8000
&read_config;
my $pid = MyWebServer->new($Port)->run();
