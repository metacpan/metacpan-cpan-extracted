# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More;

BEGIN { use_ok('WWW::Vimeo::Download'); }

my $vimeo = WWW::Vimeo::Download->new();
isa_ok( $vimeo, 'WWW::Vimeo::Download' );

#$vimeo->load_video( 'http://www.vimeo.com/27855315' );
#$vimeo->load_video('http://vimeo.com/groups/shortfilms/videos/28012171');
$vimeo->load_video('http://vimeo.com/57130400'); #very short video, good for testing.. 2mb
ok( $vimeo->download_url =~ m/^http/, 'found download url for video' );
#warn "---> Video title: " . $vimeo->caption;
#warn "---> Video download url : " . $vimeo->download_url;
$vimeo->download;
#ok( -e $vimeo->filename_nfo, 'nfo created with success' );
ok( -e $vimeo->filename, 'downloaded file with success' );
#unlink( $vimeo->filename_nfo );
unlink( $vimeo->filename );


#download by id
$vimeo->load_video('57130400'); #very short video, good for testing.. 2mb
ok( $vimeo->download_url =~ m/^http/, 'found download url for video' );
#warn "---> Video title: " . $vimeo->caption;
#warn "---> Video download url : " . $vimeo->download_url;
$vimeo->download;
#ok( -e $vimeo->filename_nfo, 'nfo created with success' );
ok( -e $vimeo->filename, 'downloaded file with success' );
#unlink( $vimeo->filename_nfo );
unlink( $vimeo->filename );




#custom filename
$vimeo->load_video('57130400'); #very short video, good for testing.. 2mb
ok( $vimeo->download_url =~ m/^http/, 'found download url for video' );
my $filename = 'mymovie.xyz';
$vimeo->download( { filename => $filename } );
ok( -e $filename, 'downloaded file with success' );
unlink( $filename );





done_testing;
