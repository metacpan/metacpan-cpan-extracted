#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

use lib '/opt/yote/lib';
use lib '/home/wolf/proj/Yote/ServerYote/lib';
use lib '/home/wolf/proj/Yote/YoteBase/lib';

use Yote;
use Yote::Server;

use CGI;
use DateTime;
use Data::Dumper;
use Encode;
use JSON;
use URI::Escape;

sub _log {
    my( $msg ) = @_;
    open my $out, ">>/opt/yote/log/yote.log";
    print $out "$msg\n";
}

unless( $main::yote_server ) {
    eval('use Yote::ConfigData');
    my $yote_root_dir = $@ ? '/opt/yote' : Yote::ConfigData->config( 'yote_root' );
    unshift @INC, "$yote_root_dir/lib";

    my $options = Yote::Server::load_options( $yote_root_dir );

    $main::yote_server = new Yote::Server( $options );
#    $main::yote_server->ensure_locker;

}
my $cgi = CGI->new;

# check if a file upload
my $json_payload = uri_unescape(scalar($cgi->param('p')));
_log( "IN : '$json_payload'" );
my $uploads = $cgi->param('f');
my( @uploads );
if( $uploads ) {
    for( my $i=0; $i<$uploads; $i++ ) {
        my $file = $cgi->param("f$i");
        push @uploads, $file;

        next; # code below doesn't yet run

        # to open (but maybe this should be elsewhere
        # to download ----->
        my( $original_name ) = ($file =~ /.*\."?(\w*)"?$/ );
        
        my $newname = "somethingnew";
        open (FILE, ">./$newname");
        while (read ($file, my $Buffer, 1024)) {
            print FILE $Buffer;
        }
        close FILE;

    }
}

my $out_json;
eval {
    $out_json = $main::yote_server->invoke_payload( $json_payload, \@uploads );
};

if( ref $@ eq 'HASH' ) {
    $out_json = encode_json( $@ );
    undef $@;
} elsif( $@ ) {
    _log( "ERRY <$@>" );
    $out_json = encode_json( {
        err => 'ERROR',
                         } );
}

print $cgi->header(
    -status => '200 OK',
    -type => 'text/json; charset=utf-8'
    );
$out_json = Encode::decode('utf8',$out_json);
_log( "CGI OUT <$out_json>" );
print $out_json;
$main::yote_server->{STORE}->stow_all;

