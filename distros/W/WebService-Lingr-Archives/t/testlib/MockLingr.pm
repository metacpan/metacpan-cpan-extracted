package testlib::MockLingr;
use 5.10.0;
use strict;
use warnings;
use Exporter qw(import);
use Test::MockObject;
use URI;
use HTTP::Response;
use HTTP::Headers;
use JSON;
use Try::Tiny;
use List::Util qw(min max);
use WebService::Lingr::Archives;

our @EXPORT_OK = qw(mock_useragent create_lingr);

our $USERNAME = "hoge";
our $PASSWORD = "password";
our $SESSION_ID = "SESSION";
our $PUBLIC_ID = "PUBLIC";
our $ROOM = "target_room";
our $MAX_MESSAGE_ID = 500;
our $MIN_MESSAGE_ID = 1;

my %HANDLERS = (
    "/api/session/create" => sub {
        my ($params) = @_;
        return try {
            if(!defined($params->{user})) {
                die "No user";
            }
            if(!defined($params->{password})) {
                die "No password";
            }
            if($params->{user} ne $USERNAME) {
                die "Invalid user";
            }
            if($params->{password} ne $PASSWORD) {
                die "Invalid password";
            }
            return _success_response({
                status => "ok", session => $SESSION_ID,
                public_id => $PUBLIC_ID, nickname => $USERNAME,
                user => { username => $USERNAME, name => $USERNAME }
            });
        }catch {
            return _error_response();
        };
    },
    "/api/room/get_archives" => sub {
        my ($params) = @_;
        return try {
            if(!defined($params->{session})) {
                die "No session";
            }
            if($params->{session} ne $SESSION_ID) {
                die "Invalid session";
            }
            if(!defined($params->{before})) {
                die "No before";
            }
            my $limit = $params->{limit} // 20;
            if($limit <= 0) {
                die "Invalid limit";
            }
            my $max = min(int($params->{before}) - 1, $MAX_MESSAGE_ID);
            my $min = max($MIN_MESSAGE_ID, $max - $limit + 1);
            return _success_response({
                status => "ok", messages => [map {_create_message($_)} $min .. $max]
            });
        }catch {
            return _error_response();
        }
    }
);

sub _error_response {
    return _success_response({
        status => "error",
        code => "", detail => ""
    });
}

sub _success_response {
    my ($result_obj) = @_;
    return HTTP::Response->new(
        200, "OK", HTTP::Headers->new(
            "Content-Type" => "application/json;charset=UTF-8"
        ),
        encode_json($result_obj)
    );
}

sub mock_useragent {
    my $ua = Test::MockObject->new;
    $ua->mock('get', sub {
        my ($self, $url_str, $headers) = @_;
        my $url = URI->new("$url_str");
        my %params = $url->query_form;
        my $handler = $HANDLERS{$url->path};
        if($handler) {
            return $handler->(\%params);
        }else {
            return HTTP::Response->new(
                404, "Not Found", undef, ""
            );
        }
    });
}

sub _create_message {
    my ($id) = @_;
    return {
        id => $id,
        room => $ROOM,
        public_session_id => "HOGEHOGE",
        icon_url => 'http://hoge.hoge/avatar.jpg',
        type => "user",
        speaker_id => "toshioito",
        nickname => "toshioito",
        text => "Message $id",
        timestamp => "2013-08-10T10:11:12Z",
        local_id => undef
    };
}

sub create_lingr {
    my ($ua, $other_params) = @_;
    $other_params ||= {};
    return WebService::Lingr::Archives->new(
        user => $USERNAME,
        password => $PASSWORD,
        %$other_params,
        user_agent => $ua,
    );
}


1;
