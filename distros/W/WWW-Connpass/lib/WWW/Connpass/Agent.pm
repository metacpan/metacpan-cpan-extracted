package WWW::Connpass::Agent;
use strict;
use warnings;

use parent qw/WWW::Mechanize/;

use Time::HiRes qw/gettimeofday tv_interval/;
use HTTP::Request;
use JSON 2;

use constant DEBUG => $ENV{WWW_CONNPASS_DEBUG};

my $_JSON = JSON->new->utf8;

sub new {
    my ($class, %args) = @_;
    my $interval = delete $args{interval} || 1.0;
    my $self = $class->SUPER::new(%args);
    $self->{_interval}    = $interval;
    $self->{_last_req_at} = undef;
    return $self;
}

sub request {
    my $self = shift;
    if (my $last_req_at = $self->{_last_req_at}) {
        my $sec = tv_interval($last_req_at);
        Time::HiRes::sleep $self->{_interval} - $sec if $sec < $self->{_interval};
    }
    my $res = $self->SUPER::request(@_);
    if (DEBUG) {
        my $req = $res->request;
        warn "============== DEBUG ==============";
        warn $req->as_string;
        warn $res->as_string;
        warn "==============  END  ==============";
    }
    $self->{_last_req_at} = [gettimeofday];
    return $res;
}

sub extract_cookie {
    my ($self, $expected_key) = @_;

    my $result;
    $self->cookie_jar->scan(sub {
        my ($key, $val) = @_[1..2];
        return if defined $result;
        return if $key ne $expected_key;
        $result = $val;
    });

    return $result;
}

sub _csrf_token {
    my $self = shift;
    $self->{_csrf_token} ||= $self->extract_cookie('connpass-csrftoken');
}

sub request_like_xhr {
    my ($self, $method, $url, $param) = @_;
    my $content = $_JSON->encode($param);

    my $req = HTTP::Request->new($method, $url, [
        'Content-Type'     => 'application/json',
        'Content-Length'   => length $content,
        'X-CSRFToken'      => $self->_csrf_token(),
        'X-Requested-With' => 'XMLHttpRequest',
    ], $content);
    return $self->request($req);
}

1;
__END__
