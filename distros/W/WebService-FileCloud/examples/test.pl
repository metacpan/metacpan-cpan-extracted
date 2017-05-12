#!perl

use strict;
use warnings;

use WebService::FileCloud;
use Data::Dumper;

# update these values accordingly
use constant AKEY => 'APIKEY';
use constant UKEY => 'FILEKEY';
use constant TKEY => 'TAGKEY';
use constant USERNAME => 'USERNAME';
use constant PASSWORD => 'PASSWORD';
use constant UPLOAD_URL => 'URL';
use constant FILENAME => 'FILENAME';
use constant TIMEOUT => 30;

my $websvc = WebService::FileCloud->new( akey => AKEY,
					 username => USERNAME,
					 password => PASSWORD,
					 timeout => TIMEOUT );

warn( Dumper( $websvc->fetch_apikey() ) );
warn( Dumper( $websvc->fetch_account_details() ) );
warn( Dumper( $websvc->ping() ) );
warn( Dumper( $websvc->check_file( ukey => UKEY ) ) );
warn( Dumper( $websvc->fetch_file_details( ukey => UKEY ) ) );
warn( Dumper( $websvc->fetch_download_url( ukey => UKEY ) ) );
warn( Dumper( $websvc->fetch_tag_details( tkey => TKEY ) ) );
warn( Dumper( $websvc->fetch_upload_url() ) );
warn( Dumper( $websvc->upload_file( url => UPLOAD_URL, filename => FILENAME ) ) );
