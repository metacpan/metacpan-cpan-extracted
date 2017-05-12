package TestHttpd;
use base qw(HTTP::Server::Simple::CGI);

my %content_map = (
    '/robots.txt' => <<"END_CONTENT",
User-Agent: WWW::RobotRules::DBIC::TestUA1
Disallow: /deny_ua1
User-Agent: WWW::RobotRules::DBIC::TestUA2
Disallow: /deny_ua2

END_CONTENT
    '/' => <<"END_CONTENT",
Hello World.
END_CONTENT
);

sub handler {
    my $self = shift;
    my $uri = $ENV{REQUEST_URI};
    my $content = $content_map{$uri} || $uri;
    $self->output_content($content, "text/plain");
}

sub output_content {
    my($self, $content, $type) = @_;
    $type ||= 'text/html';
    print "HTTP/1.0 200 OK\r\n";
    print "Content-Type: $type\r\n";
    print "Content-Length: ", length($content);
    print "\r\n\r\n";
    print $content;
}
