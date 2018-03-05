package WWW::FCM::HTTP::Response;

use strict;
use warnings;
use JSON qw(decode_json);
use Class::Accessor::Lite (
    new => 0,
    ro  => [qw/http_response content is_success sent_reg_ids/],
);

use WWW::FCM::HTTP::Response::ResultSet;

sub new {
    my ($class, $http_response) = @_;

    my $is_success  = $http_response->is_success;
    my $content     = $http_response->content;
    my $req_content = decode_json($http_response->request->content);

    my $sent_reg_ids = [];
    if ($is_success) {
        $content = decode_json $content;

        if (exists $content->{multicast_id}) {
            $sent_reg_ids = $req_content->{registration_ids};
        }
    }
    else {
        $content = { error => $content };
    }

    bless {
        is_success    => $is_success,
        content       => $content,
        sent_reg_ids  => $sent_reg_ids,
        http_response => $http_response,
    }, $class;
}

sub success {
    shift->content->{success};
}

sub failure {
    shift->content->{failure};
}

sub message_id {
    shift->content->{message_id};
}

sub multicast_id {
    shift->content->{multicast_id};
}

sub canonical_ids {
    shift->content->{canonical_ids};
}

sub error {
    shift->content->{error};
}

sub has_error {
    my $self = shift;
    return 1 unless $self->is_success;
    $self->error ? 1 : 0;
}

sub results {
    my $self = shift;
    my $results = $self->content->{results} || return;
    WWW::FCM::HTTP::Response::ResultSet->new($results, $self->sent_reg_ids);
}

sub DESTROY {};
sub AUTOLOAD {
    (my $method = our $AUTOLOAD) =~ s/.*:://;
    no strict 'refs';
    *{$AUTOLOAD} = sub {
        use strict;
        my $self = shift;
        $self->{http_response}->$method(@_);
    };
    goto &$AUTOLOAD;
}

1;
