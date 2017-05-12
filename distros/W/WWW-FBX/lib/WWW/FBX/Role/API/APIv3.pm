package WWW::FBX::Role::API::APIv3;
use 5.014001;
use Moose::Role;
use WWW::FBX::API;
use MIME::Base64 qw/encode_base64 decode_base64/;

#sub BUILD {
#  shift->api_version;
#}

fbx_api_method api_version => (
  description => <<'',
Get API version.

  path => 'api_version',
  method => 'GET',
  params => [],
  required => [],
);

around api_version => sub {
  my $orig = shift;
  my $self = shift;

  api_url( "" );
  $self->$orig;
  my $uar = $self->uar;
  my ($maj) = $uar->{api_version} =~ /(\d*)\./;
  api_url( "$uar->{api_base_url}v$maj" );
};

fbx_api_method req_auth => (
  description => <<'',
Ask for an App token.

  path => 'login/authorize',
  method => 'POST',
  params => [qw/ app_id app_name app_version device_name /],
  required => [qw/ app_id app_name app_version device_name /],

);

fbx_api_method auth_progress => (
  description => <<'',
Monitor token status.

  path => 'login/authorize/',
  method => 'GET',
  params => [qw/suff/],
  required => [qw/suff/],
);

fbx_api_method login => (
  description => <<'',
Get login challenge.

  path => 'login/',
  method => 'GET',
  params => [],
  required => [],
);

fbx_api_method open_session => (
  description => <<'',
Open a session.

  path => 'login/session/',
  method => 'POST',
  params => [ qw/ app_id app_version password / ],
  required => [ qw/ app_id password / ],
);

#Download
fbx_api_method s'/'_'gr => (
  description => <<'',
Global download getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(downloads/ downloads/stats);

fbx_api_method get_download_task => (
  description => <<'',
Get the download task.

  path => 'downloads/',
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
);

fbx_api_method del_download_task => (
  description => <<'',
Get the download task.

  path => 'downloads/',
  method => 'DELETE',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
);

fbx_api_method upd_download_task => (
  description => <<'',
Update the download task.

  path => 'downloads/',
  method => 'PUT',
  params => [ qw/suff io_priority status/ ],
  required => [ qw/suff/ ],
);

fbx_api_method add_download_task => (
  description => <<'',
Add a download task.

  path => 'downloads/add',
  method => 'POST',
  content_type => 'application/x-www-form-urlencoded',
  params => [ qw/download_url download_url_list download_dir recursive username password archive_password cookies/],
  required => [ qw//],
);

fbx_api_method add_download_task_file => (
  description => <<'',
Add a download task by file.

  path => 'downloads/add',
  method => 'POST',
  content_type => 'form-data',
  params => [ qw/download_file download_dir archive_password/],
  required => [ qw/download_file/],
);

fbx_api_method change_prio_download_file => (
  description => <<'',
Change the priority of a Download File.

  path => 'downloads/',
  method => 'PUT',
  params => [ qw/suff priority/ ],
  required => [ qw/suff priority/ ],
);

#TODO: tracker, blacklist

#Download feeds
fbx_api_method s'/'_'gr => (
  description => <<'',
Get feed(s).

  path => $_,
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ ],
) for qw(downloads/feeds/);

fbx_api_method add_feed => (
  description => <<'',
Add a feed.

  path => 'downloads/feeds/',
  method => 'POST',
  params => [ qw/url/ ],
  required => [ qw/url/ ],
);

fbx_api_method del_feed => (
  description => <<'',
Delete download feed.

  path => "downloads/feeds/",
  method => 'DELETE',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
);

fbx_api_method upd_feed => (
  description => <<'',
Update download feed.

  path => 'downloads/feeds/',
  method => 'PUT',
  params => [ qw/suff auto_download/ ],
  required => [ qw/suff / ],
);

fbx_api_method $_ => (
  description => <<'',
Global feed POST.

  path => 'downloads/feeds/',
  method => 'POST',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
) for qw/refresh_feed download_feed_item mark_all_read/;

fbx_api_method refresh_feeds => (
  description => <<'',
Refresh all feeds.

  path => 'downloads/feeds/fetch',
  method => 'POST',
  params => [ ],
  required => [ ],
);

#Download config
fbx_api_method downloads_config => (
  description => <<'',
Get Downloads config.

  path => "downloads/config",
  method => 'GET',
  params => [ ],
  required => [ ],
);

fbx_api_method upd_downloads_config => (
  description => <<'',
Update downloads config.

  path => "downloads/config",
  method => 'PUT',
  params => [ qw/throttling max_downloading_tasks download_dir use_watch_dir watch_dir news bt feed/],
  required => [ ],
) for qw(downloads/config/);

around downloads_config => sub {
  my $orig = shift;
  my $self = shift;

  my $params = $self->$orig(@_);

  for (qw/download_dir watch_dir/) {
    $params->{$_} = decode_base64( $params->{$_} ) if exists $params->{$_} and $params->{$_};
  }

  $params;
};

around upd_downloads_config => sub {
  my $orig = shift;
  my $self = shift;

  if (@_) {
    my $params = $_[0];
    for my $par (qw/download_dir watch_dir/) {
      $params->{$par} = encode_base64( $params->{$par}, "") if exists $params->{$par} and $params->{$par};
    }
  }

  $self->$orig(@_);
};

fbx_api_method upd_downloads_throttle => (
  description => <<'',
Update download throttling.

  path => "downloads/throttling",
  method => 'PUT',
  params => [ qw/throttling/],
  required => [ qw/throttling/ ],
);

#FS
fbx_api_method s'/'_'gr => (
  description => <<'',
Get task(s).

  path => $_,
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ ],
) for qw(fs/tasks/);

fbx_api_method del_task => (
  description => <<'',
Delete task.

  path => "fs/tasks/",
  method => 'DELETE',
  params => [ qw/suff/ ],
  required => [ ],
);

fbx_api_method upd_task => (
  description => <<'',
Update task.

  path => "fs/tasks/",
  method => 'PUT',
  params => [ qw/suff state/ ],
  required => [ qw/suff state/ ],
);

fbx_api_method list_files => (
  description => <<'',
List files.

  path => "fs/ls/",
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
);

around list_files => sub {
  my $orig = shift;
  my $self = shift;
  my $params = shift;

  $params = encode_base64( $params, "") if $params;
  my $res = $self->$orig($params);

  for my $i ( 0.. $#{$res} ) {
    $res->[$i]{path} = decode_base64( $res->[$i]{path} );
  }

  $res;
};

fbx_api_method file_info => (
  description => <<'',
Get file information.

  path => "fs/info/",
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
);

around file_info => sub {
  my $orig = shift;
  my $self = shift;
  my $params = shift;

  $params = encode_base64( $params, "") if $params;
  
  my $res = $self->$orig($params);

  for (qw/parent target path/) {
    $params->{$_} = decode_base64( $params->{$_} ) if exists $params->{$_} and $params->{$_};
  }

  $params;
};

fbx_api_method mv => (
  description => <<'',
Move files.

  path => "fs/mv/",
  method => 'POST',
  params => [ qw/files dst mode/ ],
  required => [ qw/files dst mode/ ],
);

fbx_api_method cp => (
  description => <<'',
Copy files.

  path => "fs/cp/",
  method => 'POST',
  params => [ qw/files dst mode/ ],
  required => [ qw/files dst mode/ ],
);

fbx_api_method archive => (
  description => <<'',
Create an archive.

  path => "fs/archive/",
  method => 'POST',
  params => [ qw/files dst/ ],
  required => [ qw/files dst/ ],
);

around [qw/cp mv archive/] => sub {
  my $orig = shift;
  my $self = shift;
  my $params = shift;

  $params->{$_} = encode_base64( $params->{$_},"") for qw/dst/;
  $params->{files}->[$_] = encode_base64( $params->{files}->[$_],"") for 0..$#{$params->{files}};
  
  $self->$orig($params);
};

fbx_api_method rm => (
  description => <<'',
Delete files.

  path => "fs/rm/",
  method => 'POST',
  params => [ qw/files/ ],
  required => [ qw/files/ ],
);

around [qw/rm cat/] => sub {
  my $orig = shift;
  my $self = shift;
  my $params = shift;

  $params->{files}->[$_] = encode_base64( $params->{files}->[$_],"") for 0..$#{$params->{files}};
  
  $self->$orig($params);
};

fbx_api_method cat => (
  description => <<'',
Cat files.

  path => "fs/cat/",
  method => 'POST',
  params => [ qw/files dst multi_volumes delete_files overwrite append/ ],
  required => [ qw/files dst/ ],
);

fbx_api_method extract => (
  description => <<'',
Extract archive.

  path => "fs/extract/",
  method => 'POST',
  params => [ qw/src dst password delete_archive overwrite/ ],
  required => [ qw/src dst password delete_archive overwrite/ ],
);

around [qw/extract/] => sub {
  my $orig = shift;
  my $self = shift;
  my $params = shift;

  $params->{$_} = encode_base64( $params->{$_},"") for qw/src dst/;
  $self->$orig($params);
};

fbx_api_method repair => (
  description => <<'',
Repair file.

  path => "fs/repair/",
  method => 'POST',
  params => [ qw/src delete_archive / ],
  required => [ qw/src delete_archive/ ],
);

fbx_api_method hash => (
  description => <<'',
Repair file.

  path => "fs/hash/",
  method => 'POST',
  params => [ qw/src hash_type/ ],
  required => [ qw/src hash_type/ ],
);

around [qw/repair hash rename/] => sub {
  my $orig = shift;
  my $self = shift;
  my $params = shift;

  $params->{$_} = encode_base64( $params->{$_},"") for qw/src/;
  $self->$orig($params);
};

fbx_api_method mkdir => (
  description => <<'',
Create directory.

  path => "fs/mkdir/",
  method => 'POST',
  params => [ qw/parent dirname/ ],
  required => [ qw/parent dirname/ ],
);

around [qw/mkdir/] => sub {
  my $orig = shift;
  my $self = shift;
  my $params = shift;

  $params->{$_} = encode_base64( $params->{$_},"") for qw/parent/;
  $self->$orig($params);
};

fbx_api_method rename => (
  description => <<'',
Rename file or directory.

  path => "fs/rename/",
  method => 'POST',
  params => [ qw/src dst/ ],
  required => [ qw/src dst/ ],
);

fbx_api_method download_file => (
  description => <<'',
Download a file.

  path => "dl/",
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
);

around download_file => sub {
  my $orig = shift;
  my $self = shift;
  my $params = shift;

  $params = encode_base64( $params, "") if $params;

  my $res = $self->$orig($params);
  if ($res->{filename} and $res->{content}) {
    open my $f, ">", $res->{filename} or die "Can't create file $res->{filename} : $!";
    print $f $res->{content};
    close $f;
  }

  $res;
};

#Share
fbx_api_method s'/'_'gr => (
  description => <<'',
Global share getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(share_link/);

#Upload
fbx_api_method s'/'_'gr => (
  description => <<'',
Global upload getters.

  path => $_,
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ ],
) for qw(upload/);

fbx_api_method upload_auth => (
  description => <<'',
Upload auth.

  path => "upload/",
  method => 'POST',
  params => [ qw/dirname upload_name/ ],
  required => [ qw/dirname upload_name/],
);

around upload_auth => sub {
  my $orig = shift;
  my $self = shift;

  if (@_) {
    my $params = $_[0];
    $params->{dirname} = encode_base64( $params->{dirname}, "") if exists $params->{dirname} and $params->{dirname};
  }

  $self->$orig(@_);
};

fbx_api_method upload_file => (
  description => <<'',
Upload file.

  path => "upload/",
  method => 'POST',
  params => [ qw/id suff dirname name/ ],
  required => [ qw/name suff/],
  content_type => 'form-data',
);

#if user provided an id, use this one otherwise request one (in that case dirname and upload_name have to be provided)
around upload_file => sub {
  my $orig = shift;
  my $self = shift;
  my $params = $_[0];
  my $id;
  my $filename;

  if ($params and exists $params->{filename} and $params->{filename}) {
    $filename = delete $params->{filename};
    if (exists $params->{id}) {
      $id = delete $params->{id};
    } else {
      $params->{upload_name} = $filename
          unless exists $params->{upload_name};
      my $res = $self->upload_auth(@_);
      delete $params->{dirname};
      delete $params->{upload_name};
      $id = $res->{id};
    }
    $params->{name} = [ $filename ];
    $params->{suff} = "$id/send";
  }
  $self->$orig(@_);
};

fbx_api_method s'/'_'gr => (
  description => <<'',
Delete downloads.

  path => $_,
  method => 'DELETE',
  params => [ ],
  required => [ ],
) for qw(upload/clean);

#AirMedia
fbx_api_method s'/'_'gr => (
  description => <<'',
Global airmedia getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(airmedia/config airmedia/receivers/);

#RRD
fbx_api_method rrd => (
  description => <<'',
Get the RRD stats.

  path => 'rrd/',
  method => 'POST',
  params => [qw/db date_start date_end precision fields/],
  required => [qw/db/],
);

#CALL
fbx_api_method s'/'_'gr => (
  description => <<'',
Global call getters.

  path => $_,
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ ],
) for qw(call/log/);

#CONTACTS
fbx_api_method s'/'_'gr => (
  description => <<'',
Global contacts getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(contact/);

#CONNECTION
fbx_api_method s'/'_'gr => (
  description => <<'',
Global Connection getters.

  path => $_,
  method => 'GET',
  params => [],
  required => [],
) for qw(connection connection/config connection/ipv6/config connection/xdsl/ connection/ftth);

fbx_api_method upd_connection => (
  description => <<'',
Update the connection configuration.

  path => 'connection/config/',
  method => 'PUT',
  params => [qw/ping remote_access remote_access_port wol adblock allow_token_request/],
  required => [qw//],
);

fbx_api_method upd_ipv6_config => (
  description => <<'',
Update the ipv6 connection configuration.

  path => 'connection/ipv6/config/',
  method => 'PUT',
  params => [qw/ ipv6_enabled delegations/],
  required => [qw//],
);

fbx_api_method connection_dyndns => (
  description => <<'',
Get status or config of dyndns provider.

  path => 'connection/ddns/',
  method => 'GET',
  params => [qw/suff/],
  required => [qw/suff/],
);

fbx_api_method upd_connection_dyndns => (
  description => <<'',
Set config of dyndns provider.

  path => 'connection/ddns/',
  method => 'GET',
  params => [qw/suff enabled user password hostname/],
  required => [qw/suff/],
);

#LAN
fbx_api_method s'/'_'gr => (
  description => <<'',
Global Lan getters.

  path => $_,
  method => 'GET',
  params => [],
  required => [],
) for qw(lan/config lan/browser/interfaces);

fbx_api_method upd_lan_config => (
  description => <<'',
Update lan config.

  path => 'lan/config/',
  method => 'PUT',
  params => [ qw/mode ip name name_dns name_mdns name_netbios/ ],
  required => [ qw// ],
);

fbx_api_method list_hosts => (
  description => <<'',
Get the list of hosts on a given interface.

  path => 'lan/browser/',
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
);

fbx_api_method upd_host => (
  description => <<'',
Update a host config.

  path => 'lan/browser/',
  method => 'PUT',
  params => [ qw/suff id primary_name host_type persistent / ],
  required => [ qw/suff id/ ],
);

fbx_api_method wol_host => (
  description => <<'',
Send a WoL.

  path => 'lan/wol/',
  method => 'POST',
  params => [ qw/suff mac password/ ],
  required => [ qw/suff mac/ ],
);

#Freeplugs
fbx_api_method freeplugs_net => (
  description => <<'',
Get freeplugs networks and information.

  path => 'freeplug/',
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ ],
);

fbx_api_method reset_freeplug => (
  description => <<'',
Reset a freeplug.

  path => 'freeplug/',
  method => 'POST',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
);

#DHCP
fbx_api_method s'/'_'gr => (
  description => <<'',
Global DHCP getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(dhcp/config dhcp/static_lease dhcp/dynamic_lease);
#TODO finish

#FTP

fbx_api_method ftp_config => (
  description => <<'',
Get the FTP config.

  path => 'ftp/config/',
  method => 'GET',
  params => [ ],
  required => [ ],
);

fbx_api_method set_ftp_config => (
  description => <<'',
Set the FTP config.

  path => 'ftp/config',
  method => 'PUT',
  params => [ qw/enabled allow_anonymous allow_anonymous_write password/ ],
  required => [ ],
);

#NAT
fbx_api_method fw_dmz => (
  description => <<'',
Get dmz config.

  path => "fw/dmz/",
  method => 'GET',
  params => [ ],
  required => [ ],
);

fbx_api_method s'/'_'gr => (
  description => <<'',
Global NAT getters.

  path => $_,
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
) for qw(fw/redir/ fw/incoming/);
#TODO rest

#UPNP
fbx_api_method s'/'_'gr => (
  description => <<'',
Global UPNP getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(upnpigd/config upnpigd/redir/);
#TODO rest

#LCD
fbx_api_method lcd => (
  description => <<'',
Get the LCD config.

  path => 'lcd/config/',
  method => 'GET',
  params => [ ],
  required => [ ],
);
fbx_api_method set_lcd => (
  description => <<'',
Set the LCD config.

  path => 'lcd/config/',
  method => 'PUT',
  params => [ qw/brightness orientation orientation_forced/ ],
  required => [ ],
);

#SHARES
fbx_api_method s'/'_'gr => (
  description => <<'',
Global Network Shares getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(netshare/samba netshare/afp);
#TODO rest

#UPNPAV
fbx_api_method upnpav => (
  description => <<'',
Get the UPNPAV config.

  path => 'upnpav/config',
  method => 'GET',
  params => [ ],
  required => [ ],
);
fbx_api_method set_upnpav => (
  description => <<'',
Set the UPNPAV config.

  path => 'upnpav/config',
  method => 'PUT',
  params => [ qw/enabled/],
  required => [ qw/enabled/],
);

#SWITCH
fbx_api_method switch_sts => (
  description => <<'',
Get the switch status.

  path => 'switch/status/',
  method => 'GET',
  params => [ ],
  required => [ ],
);

fbx_api_method switch_port => (
  description => <<'',
Get the switch port config and status.

  path => 'switch/port/',
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
);

fbx_api_method set_switch_port => (
  description => <<'',
Update a port config.

  path => 'switch/port/',
  method => 'PUT',
  params => [ qw/suff duplex speed/ ],
  required => [ qw/suff/ ],
);

#wifi
fbx_api_method s'/'_'gr => (
  description => <<'',
Global Wifi getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(wifi/config wifi/planning wifi/mac_filter);

fbx_api_method s'/'_'gr => (
  description => <<'',
Wifi AP and bss configuration.

  path => $_,
  method => 'GET',
  params => [ qw/suff/ ],
  required => [ qw/suff/ ],
) for qw( wifi/ap/ wifi/bss/ );

#TODO finish

#System
fbx_api_method system => (
  description => <<'',
Get the system info.

  path => 'system',
  method => 'GET',
  params => [ ],
  required => [ ],
);

fbx_api_method reboot => (
  description => <<'',
Reboot the system.

  path => 'system/reboot',
  method => 'POST',
  params => [ ],
  required => [ ],
);

#VPN server
fbx_api_method s'/'_'gr => (
  description => <<'',
Global VPN server getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(vpn/ vpn/user/ vpn/ip_pool/);

#VPN client
fbx_api_method s'/'_'gr => (
  description => <<'',
Global VPN client getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(vpn_client/config/ vpn_client/status vpn_client/log);
#TODO finish

#Storage
fbx_api_method s'/'_'gr => (
  description => <<'',
Global storage getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(storage/disk/ storage/partition/);
#TODO finish

#Parental
fbx_api_method s'/'_'gr => (
  description => <<'',
Global parental getters.

  path => $_,
  method => 'GET',
  params => [ ],
  required => [ ],
) for qw(parental/config/ parental/filter/);
#TODO finish

1;
__END__

=encoding utf-8

=head1 NAME

WWW::FBX::Role::API::APIv3 - Freebox API v3

=head1 SYNOPSIS

    with 'WWW::FBX::Role::API::APIv3';

=head1 DESCRIPTION

WWW::FBX::Role::API::APIv3 is the freebox6 API version 3 as a Moose Role

=head1 API

API documentation is given here: L<http://dev.freebox.fr/sdk/os/>
The following methods are currently implemented in this library:

=head2 RRD

=head3 get rrd stats

 $fbx->rrd( { db => "temp", fields => [ "cpub" ], precision => 1 } );

=head2 call and contacts

=head3 call log

 $fbx->call_log;

=head3 contact

 $fbx->contact;

=head2 connection

=head3 connection

 $res = $fbx->connection;

=head3 connection config

 $res = $fbx->connection_config;

=head3 connection ipv6 config

 $fbx->connection_ipv6_config;

=head3 connection xdsl

 $fbx->connection_xdsl;

=head3 connection ftth

 $fbx->connection_ftth;

=head3 update connection config

 $res = $fbx->upd_connection({ping=>\1});

=head3 update connection ipv6 config

 $res = $fbx->upd_ipv6_config({ipv6_enabled=>\0});

=head3 connection dyndns noip

 $res = $fbx->connection_dyndns("noip/status");

=head3 connection dyndns noip

 $res = $fbx->upd_connection_dyndns("noip/status", {enabled=>\0});

=head2 dhcp

=head3 dhcp config

 $fbx->dhcp_config;

=head3 dhcp static lease

 $fbx->dhcp_static_lease;

=head3 dhcp dynamic lease

 $fbx->dhcp_dynamic_lease;

=head2 download

=head3 downloads

 $fbx->downloads;

=head3 downloads config

 $fbx->downloads_config;

=head3 downloads stats

 $fbx->downloads_stats;

=head3 download feeds

 $fbx->downloads_feeds;

=head3 downloads config

 $res = $fbx->downloads_config;

=head3 download tasks

 $res = $fbx->get_download_task;

=head3 download add

 $res = $fbx->add_download_task( { download_url => "http://cdimage.debian.org/debian-cd/current/arm64/bt-cd/debian-8.4.0-arm64-CD-1.iso.torrent"} );

=head3 update downloads config

 $res = $fbx->upd_downloads_config({max_downloading_tasks => $max_dl_tasks});

=head3 update throttling

 $res = $fbx->upd_downloads_throttle( "schedule" );

=head3 download tasks

 $res = $fbx->get_download_task;

=head3 download task

 $res = $fbx->get_download_task( $id );

=head3 download task log

 $res = $fbx->get_download_task( "$id/log" );

=head3 downloads update

 $fbx->upd_download_task( $id, { io_priority => "high" } );

=head3 get download task files

 $res = $fbx->get_download_task("$id/files") ;

=head3 update priority of download file

 $res = $fbx->change_prio_download_file( "$id/files/$id_file", { priority=>"high"} );

=head3 downloads task del

 $res = $fbx->del_download_task( $id );

=head3 download add by local file

 $res = $fbx->add_download_task_file( {download_file => [ "mine/debian-8.4.0-arm64-netinst.iso.torrent" ] });

=head3 download tracker

 $res = $fbx->get_download_task( "$id/trackers");

=head3 download peers

 $res = $fbx->get_download_task( "$id/peers");

=head3 downloads task del with file erase

 $fbx->del_download_task( "$id/erase" );

=head3 download feed

 $res = $fbx->downloads_feeds;

=head3 add feed

 $res = $fbx->add_feed( "http://www.esa.int/rssfeed/Our_Activities/Space_News" );

=head3 update feed

 $fbx->upd_feed( $id , {auto_download=> \1} );

=head3 download feed

 $res = $fbx->downloads_feeds("$id/items");

=head3 refresh feed

 $fbx->refresh_feed( "$id/fetch" );

=head3 refresh all feeds

 $fbx->refresh_feeds;

=head3 download feed items

 $fbx->downloads_feeds("$id/items");

=head3 update a feed item

 $fbx->upd_feed("$id/items/$id_file");

=head3 download a feed item

 $fbx->download_feed_item("$id/items/$id_file/download");

=head3 mark all items as read

 $fbx->mark_all_read( "$id/items/mark_all_as_read" );

=head3 del feed

 $fbx->del_feed( $id );

=head3 download file to disk

 $res = $fbx->download_file( "Disque dur/Photos/cyril/DSCF4322.JPG" );

=head3 download file to disk

 $res = $fbx->download_file( "Disque dur/Photos/cyril/DSCF4321.JPG" );

=head3 get upload id

 $res = $fbx->upload_auth( {upload_name => "DSCF4322.JPG", dirname => "/Disque dur/"} );

=head3 upload file by upload id

 $res = $fbx->upload_file( {id=> $res->{id}, filename=>"DSCF4322.JPG"});

=head3 upload file directly

 $res = $fbx->upload_file( {filename => "DSCF4321.JPG", dirname => "/Disque dur/"} );

=head2 freeplugs

=head3 list freeplugs

 $fbx->freeplugs_net;

=head3 get a particular freeplugs

 $fbx->freeplugs_net("F4:CA:E5:1D:46:AE");

=head3 reset freeplug

 $fbx->reset_freeplug("F4:CA:E5:1D:46:AE");

=head2 fs

=head3 fs tasks

 $fbx->fs_tasks;

=head3 fs task

 $fbx->fs_tasks(12);

=head3 del fs task

 $fbx->del_task(12);

=head3 update fs task

 $fbx->upd_task(12, state=>"paused"});

=head3 list files

 $res = $fbx->list_files("Disque dur/");

=head3 file info

 $res = $fbx->file_info("Disque dur/Photos/Sydney/DSCF4323.JPG");

=head3 file move

 $res = $fbx->mv( {files=>[ qw/a.txt b.txt/ ], dst => "/Disque dur/directory", mode => "overwrite" } );

=head3 file cp

 $res = $fbx->cp( {files=>[ qw/a.txt b.txt/ ], dst => "/Disque dur/directory", mode => "overwrite" } );

=head3 file archive

 $res = $fbx->archive( {files=>[ qw/a.txt b.txt/ ], dst => "/Disque dur/archive.zip", mode => "overwrite" } );

=head3 file rm

 $res = $fbx->rm( {files=>[ qw/a.txt b.txt/ ] } );

=head3 file cat

 $res = $fbx->cat( {files=>[ qw/a.txt b.txt/ ], dst=>"/Disque dur/file", multi_volumes=\0, delete_files=>\0, append=>\1, overwrite=>\0 } );

=head3 file extract

 $res = $fbx->cat( { src => "foo.iso", dst=>"/Disque dur/directory", password =>"", delete_archive=>\0, overwrite=>\0 } );

=head3 file repair

 $res = $fbx->repair( { src => "foo.iso.par2", delete_archive=>\0 } );

=head3 file hash

 $res = $fbx->hash( { src => "foo.iso", hash_type=>"md5" } );

=head3 mkdir

 $res = $fbx->mkdir( { parent => "/Disque dur/", dirname => "directory" } );

=head3 rename

 $res = $fbx->rename( { src => "/Disque dur/a.txt", dst => "b.txt' } );

=head3 download RAW file not JSON!

 $res = $fbx->download_file("Disque dur/Photos/cyril/DSCF4322.JPG");

=head2 ftp

=head3 ftp config

 $fbx->ftp_config;

=head2 lan

=head3 lan config

 $res = $fbx->lan_config;

=head3 lan browser interfaces

 $res = $fbx->lan_browser_interfaces;

=head3 lan browser interfaces pub

 $res = $fbx->list_hosts( $net );

=head3 get host information

 $res = $fbx->list_hosts("$net/$id");

=head3 update host information

 $res = $fbx->upd_host("$net/$id", { id => $id , host_type => "networking_device" });

=head3 update lan config

 $res = $fbx->upd_lan_config( {mode=>"router"} );

=head3 send wol

 $res = $fbx->wol_host( $net, {mac => "B8:27:EB:73:8C:4E"} );

=head2 lcd

=head3 lcd

 $res = $fbx->lcd;

=head3 lcd brightness back

 $fbx->set_lcd({ brightness => $res->{brightness} });

=head2 nat

=head3 fw dmz

 $fbx->fw_dmz;

=head3 fw all redir

 $fbx->fw_redir;

=head3 fw redir

 $fbx->fw_redir(0);

=head3 fw all incoming

 $fbx->fw_incoming;

=head3 fw incoming

 $fbx->fw_incoming("bittorent-main");

=head2 parental

=head3 parental config

 $fbx->parental_config;

=head3 parental filter

 $fbx->parental_filter;

=head2 share

=head3 share link

 $fbx->share_link;

=head3 upload status

 $fbx->upload;

=head3 upload status of a task

 $fbx->upload(1);

=head3 airmedia config

 $fbx->airmedia_config;

=head3 airmedia receivers

 $fbx->airmedia_receivers;

=head2 shares

=head3 netshare samba

 $res = $fbx->netshare_samba;

=head3 netshare afp

 $fbx->netshare_afp;

=head2 storage

=head3 storage disk

 $fbx->storage_disk;

=head3 storage partition

 $fbx->storage_partition;

=head2 switch

=head3 switch status

 $res = $fbx->switch_sts;

=head3 switch port config

 $res = $fbx->switch_port(1);

=head3 switch port stats

 $res = $fbx->switch_port("1/stats/");

=head3 set switch port config

 $res = $fbx->set_switch_port(1 , {duplex=>"auto"} );

=head2 system

=head3 get system info

 $fbx->system;

=head3 reboot system

 $fbx->reboot;

=head2 upnp

=head3 upnpigd config

 $fbx->upnpigd_config;

=head3 upnpigd redir

 $fbx->upnpigd_redir;

=head2 upnpav

=head3 upnpav

 $res=$fbx->upnpav;

=head3 set upnpav

 $fbx->set_upnpav($res->{enabled});

=head2 vpn

=head3 vpn

 $fbx->vpn;

=head3 vpn user

 $fbx->vpn_user;

=head3 vpn ip_pool

 $fbx->vpn_ip_pool;

=head3 vpn client config

 $fbx->vpn_client_config;

=head3 vpn client status

 $fbx->vpn_client_status;

=head3 vpn client log

 $fbx->vpn_client_log;

=head2 wifi

=head3 wifi config

 $fbx->wifi_config;

=head3 wifi ap list

 $fbx->wifi_ap;

=head3 wifi ap

 $fbx->wifi_ap(0);

=head3 wifi ap allowed combinations

 $fbx->wifi_ap( "0/allowed_channel_comb" );

=head3 wifi ap connected stations

 $fbx->wifi_ap( "0/stations" );

=head3 wifi ap neighbors

 $fbx->wifi_ap( "0/neighbors" );

=head3 wifi ap channel usage

 $fbx->wifi_ap( "0/channel_usage" );

=head3 wifi all bss

 $fbx->wifi_bss;

=head3 wifi of a bss

 $fbx->wifi_bss( "00:24:D4:AA:BB:CC" );

=head3 wifi planning

 $fbx->wifi_planning;

=head3 wifi mac filter

 $fbx->wifi_mac_filter;

=head1 LICENSE

Copyright (C) Laurent Kislaire.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Laurent Kislaire E<lt>teebeenator@gmail.comE<gt>

=cut

