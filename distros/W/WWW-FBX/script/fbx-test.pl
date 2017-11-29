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

sub die_helper {
  print "Usage : $0 [COMMAND] [PARAMETERS]\n";
  print "Control FreeboxOs v6 through its API v3\n\n";
  print "Without COMMAND, the script will list the permission granted and display your internet connection state as an example.\n\n";
  print "List of COMMAND and PARAMETERS are:\n";
  for my $role ( @{ $fbx->meta->roles } ) {
    if ($role->{package} eq "WWW::FBX::Role::API::APIv3") {
      for my $meth ( sort $role->get_method_list ) {
        print "\t$meth (", join(" , ", @{$role->get_method($meth)->params}), ")\n" unless $meth eq "meta";
      }
    }
  }
  exit;
}

eval {

  if (-f $store) {
    my $token = retrieve $store;
    %$conn = ( %$conn, %$token );
    print "Retrieved track_id and app_token from $store\n";
  } else {
    print "No stored token found\n";
  }
  $fbx = WWW::FBX->new( $conn );
  unless ( -f $store ) {
    print "Storing token in $store in current directory for further usage [ track_id = ", $fbx->track_id, " app_token = ", $fbx->app_token, " ]\n";
    print "You can add the remaining permissions by connecting on the web interface\n";
    store { track_id => $fbx->track_id, app_token => $fbx->app_token }, $store;
  }

  GetOptions(
    'debug' => sub { $fbx->debug(1) },
    'help' => \&die_helper,
  ) or die_helper;

  if (! defined (my $cmd = shift @ARGV) ) {
    #Just run a simple test
    print "App permissions are:\n"; 
    while ( my( $key, $value ) = each %{ $fbx->uar->{result}{permissions} } ) { 
      print "\t $key\n" if $value; 
    }
    $res = $fbx->connection;
    printf "Your %s internet connection is %s\n", $res->{media}, $res->{state};
  } elsif (eval { $json = from_json( $ARGV[0]) } ) {
    #Execute with JSON
    my $res = $fbx->$cmd($json);
  } else {
    #Execute non JSON
    my $res = $fbx->$cmd(@ARGV);
  }
};

if ( my $err = $@ ) {
    die $@ unless blessed $err && $err->isa('WWW::FBX::Error');
 
    warn "HTTP Response Code: ", $err->code, "\n",
         "HTTP Message......: ", $err->message, "\n",
         "API Error.........: ", $err->error, "\n",
         "Error Code........: ", $err->fbx_error_code, "\n",
}
