package WWW::2ch::UserAgent;
use strict;

use base qw( LWP::UserAgent );

use HTTP::Request;
use HTTP::Date;

sub new {
    my $class = shift;
    my $ua = shift;
    my $self  = $class->SUPER::new();
    
    $ua = " ($ua)" if $ua;
    $self->agent("Monazilla/1.00 WWW::2ch/$WWW::2ch::VERSION$ua");
    $self->timeout(15);
    $self->max_redirect(0);
    $self;
}

sub diff_request {
    my ($self, $url, %opt) = @_;

    my $req = HTTP::Request->new(GET => $url);
    $req->header(Range => 'bytes=' . $opt{size} . '-') if $opt{size};
    $req->header('If-Modified-Since' => HTTP::Date::time2str($opt{time})) if $opt{time} && $opt{time} > 0;

    $self->request($req);
}

1;
