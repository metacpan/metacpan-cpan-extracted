package WebService::Qiita::Test;
use strict;
use warnings;
use utf8;
use Exporter::Lite;

use WebService::Qiita::Client;

our @EXPORT = qw(client api_endpoint);


no warnings 'redefine';

sub import {
    my ($class, @opts) = @_;
    no warnings 'redefine';
    no strict 'refs';

    strict->import;
    warnings->import;
    utf8->import;

    @_ = ($class, @opts);
    goto &Exporter::Lite::import;
}

sub client {
    my (%args) = @_;
    my $client = WebService::Qiita::Client->new({
        url_name => $args{url_name} || 'y_uuki_',
        password => $args{password} || 'mysecret',
        token    => $args{token}    || 'authtoken',
    });
    $client;
}

sub api_endpoint {
    my ($path) = @_;
    WebService::Qiita::Client::Base::ROOT_URL . "/api/v1" . $path;
}


1;
