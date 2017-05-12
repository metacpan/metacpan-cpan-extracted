package Test::WebService::Bitly::Mock::UserAgent;
use strict;
use warnings;


use LWP::UserAgent;
use Test::MockObject::Extends;
use File::Basename;
use Path::Class;

sub new {
    my $class = shift;
    my $ua = LWP::UserAgent->new;
    $ua = Test::MockObject::Extends->new($ua);

    $ua->mock(get  => sub {__PACKAGE__->_mock_response($_[1])});
    $ua->mock(post => sub {__PACKAGE__->_mock_response($_[1])});

    return $ua;
}

sub _mock_response {
    my ($class, $uri) = @_;
    $uri              = URI->new($uri);

    my $path      =  $uri->path;
    $path         =~ s{^/}{};
    my $base_name =  basename($path) . '.json';
    my $dir_name  =  dirname($path);

    my $datafile = file(__FILE__)->dir->subdir('../../../../../data')->subdir($dir_name)->file($base_name);

    my $response = HTTP::Response->new;
    if ($uri->host eq 'api.bit.ly') {
        $response->code(200);
        $response->message('OK');
    }
    else {
        $response->code(500);
        $response->message('Internal Server Error');
    }
    $response->content(scalar $datafile->slurp);

    return $response;
}

1;
