#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use WebService::Syncthing;

use Data::Printer;

my $hostport = shift // 'localhost:8080';

my $Syncthing = WebService::Syncthing->new(
    base_url => "http://$hostport/rest",
#    auth_token => 'AUTHTOKEN',
);

p $Syncthing->get_ping();
p $Syncthing->get_version();
p $Syncthing->get_model('folder_name');
p $Syncthing->get_connections();
#p $Syncthing->get_completion(
#    'AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAD-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA',
#    'folder_name'
#);
p $Syncthing->get_config();
p $Syncthing->get_config_sync();
p $Syncthing->get_system();
p $Syncthing->get_errors();
p $Syncthing->get_discovery();
#p $Syncthing->get_deviceid(
#    'AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAD-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA',
#);
p $Syncthing->get_upgrade();
p $Syncthing->get_ignores('folder_name');
p $Syncthing->get_need('folder_name');

p $Syncthing->post_ping();


p $Syncthing->post_scan({
    folder => 'folder_name',
});

p $Syncthing->post_bump({
    folder => 'folder_name',
    file   => 'spam',
});

p $Syncthing->get_errors();
p $Syncthing->post_error('this is an error');
p $Syncthing->post_error_clear();

