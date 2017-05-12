# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More;

BEGIN { use_ok( 'WWW::YouTube::Download::Channel' ); }

my $yt = WWW::YouTube::Download::Channel->new ();
isa_ok ($yt, 'WWW::YouTube::Download::Channel');
$yt->debug(1);
$yt->apply_regex_filter('translate beat box'); #only leech this
$yt->apply_regex_skip('skip|some|Bad Videos');
$yt->newer_than( { day => 1, month => 12, year => 2000 } );
$yt->leech_channel('google');
$yt->download_all;

sub is_file_downloaded {
    return 1 if ( -e @{ $yt->video_list_ids }[0]->{ filename } );
} 
is( 1, is_file_downloaded , 'video downloaded..' );
&cleanup_test_files;

sub cleanup_test_files {
    foreach my $vid ( @{ $yt->video_list_ids } ) {
        unlink $vid->{ filename_nfo } if ( -e $vid->{ filename_nfo } ) ;
        unlink $vid->{ filename } if ( -e $vid->{ filename } ) ;
    }
}
#if ( -e 'Google-Demo-Slam-Translate-Beat-Box-2010-12-01' ) {
#    unlink 'Google-Demo-Slam-Translate-Beat-Box-2010-12-01'; # clean up
#} 

done_testing();
