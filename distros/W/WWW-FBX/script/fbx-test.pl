#!/usr/bin/perl
use strict;
use warnings;
use Scalar::Util "blessed";
use Storable;
use Data::Dumper;
use Getopt::Long;
use JSON::MaybeXS;
use WWW::FBX;

my $fbx;
my $store = 'app_token';
my $conn = {
    app_id => "APP ID",
    app_name => "APP NAME",
    app_version => "1.0",
    device_name => "debian",
};
my $json;
my $res;
my ($quiet,$debug);

sub die_helper {
  print "Usage : $0 [OPTIONS] [COMMAND] [PARAMETERS]\n";
  print "Control FreeboxOs v6 through its API v3\n\n";
  print "OPTIONS can be --debug, --quiet and --help\n\n";
  print "Without COMMAND, the script will list the permission granted and display your internet connection state as an example.\n\n";
  print "List of COMMAND and PARAMETERS are:\n";
  $conn->{ noauth }=1;
  $fbx = WWW::FBX->new( $conn );
  for my $role ( @{ $fbx->meta->roles } ) {
    if ($role->{package} eq "WWW::FBX::Role::API::APIv3") {
      for my $meth ( sort $role->get_method_list ) {
        print "\t$meth (", join(" , ", @{$role->get_method($meth)->params}), ")\n" unless $meth eq "meta";
      }
    }
  }
  exit;
}

for (qw/track_id app_token/) {
  $conn->{$_} = $ENV{$_} if $ENV{$_};
}

eval {

  if (-f $store) {
    my $token = retrieve $store;
    %$conn = ( %$conn, %$token );
    warn "Retrieved track_id and app_token from $store\n";
  } else {
    warn "No stored token found\n";
  }
  GetOptions(
    'debug' => sub { $conn->{debug} = 1 },
    'quiet' => sub { $quiet = 1 },
    'help' => \&die_helper,
  ) or die_helper;

  $fbx = WWW::FBX->new( $conn );
  unless ( -f $store ) {
    warn "Storing token in $store in current directory for further usage [ track_id = ", $fbx->track_id, " app_token = ", $fbx->app_token, " ]\n";
    warn "You can add the remaining permissions by connecting on the web interface\n";
    store { track_id => $fbx->track_id, app_token => $fbx->app_token }, $store;
  }

  if (! defined (my $cmd = shift @ARGV) ) {
    #Just run a simple connection test
    print "App permissions are:\n";
    while ( my( $key, $value ) = each %{ $fbx->uar->{result}{permissions} } ) {
      print "\t $key\n" if $value;
    }
    $res = $fbx->connection;
    printf "Your %s internet connection is %s\n", $res->{media}, $res->{state};
  } elsif ( $cmd eq "wifitab" ) {
    #List wifi stations
    my $wifi = $fbx->wifi_ap("0/stations");
    for my $host ( sort {$a->{hostname} cmp $b->{hostname} } @{ $wifi }) {
      my $ip="N/A";
      for my $l3c (@{$host->{host}{l3connectivities}}) {
          $ip = $l3c->{addr} if $l3c->{active};
        }
      printf "%16.16s\t%s\t%15.15s\t%6.6sdB\t%6.6sMbps\t%6.6sMbps\n", $host->{hostname}, $host->{mac}, $ip, $host->{signal}, 10*$host->{last_rx}{bitrate}, 10*$host->{last_tx}{bitrate};
    }
  } else {
    #Execute given command (JSON or not)
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Deepcopy = 1;
    if (eval { $json = from_json( $ARGV[0]) } ) {
      $res = $fbx->$cmd($json);
    } else {
      $res = $fbx->$cmd(@ARGV);
    }
    print Dumper $res unless $quiet;
  }
};

if ( my $err = $@ ) {
    die $@ unless blessed $err && $err->isa('WWW::FBX::Error');

    warn "HTTP Response Code: ", $err->code, "\n",
         "HTTP Message......: ", $err->message, "\n",
         "API Error.........: ", $err->error, "\n",
         "Error Code........: ", $err->fbx_error_code, "\n",
}
