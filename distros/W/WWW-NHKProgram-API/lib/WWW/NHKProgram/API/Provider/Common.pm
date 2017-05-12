package WWW::NHKProgram::API::Provider::Common;
use strict;
use warnings;
use utf8;
use Carp;
use JSON ();
use Text::Sprintf::Named qw/named_sprintf/;

use constant API_ENDPOINT => "http://api.nhk.or.jp/v1/pg/";

sub call {
    my ($class, $sub_uri, $arg, $raw) = @_;

    my $res = $class->furl->get(named_sprintf(
        API_ENDPOINT . "$sub_uri?key=" . $class->api_key, $arg
    ));
    _catch_error($res, $raw);
    return $res->{content};
}

sub _catch_error {
    my ($res, $raw) = @_;

    unless ($res->is_success) {
        if ($raw) {
            croak $res->{content};
        }
        my $fault = JSON::decode_json($res->{content})->{fault};
        my $fault_str = $fault->{faultstring};
        my $fault_detail = $fault->{detail}->{errorcode};

        my $error_str = "[Error] " . $res->status_line;
        if ($fault_str) {
            $error_str .= ": $fault_str";
        }
        if ($fault_detail) {
            $error_str .= " ($fault_detail)";
        }
        croak $error_str;
    }
}

1;

