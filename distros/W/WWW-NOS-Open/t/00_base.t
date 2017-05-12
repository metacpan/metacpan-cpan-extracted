use Test::More;
use Test::NoWarnings;

BEGIN {
    %MAIN::methods = (
        'WWW::NOS::Open' => [
            qw(get_version get_latest_articles get_latest_videos get_latest_audio_fragments search get_tv_broadcasts get_radio_broadcasts)
        ],
        'WWW::NOS::Open::Version'  => [qw(get_version get_build)],
        'WWW::NOS::Open::Resource' => [
            qw(get_id get_type get_title get_description get_published get_last_update get_thumbnail_xs get_thumbnail_s get_thumbnail_m get_link get_keywords)
        ],
        'WWW::NOS::Open::Article' => [
            qw(get_id get_type get_title get_description get_published get_last_update get_thumbnail_xs get_thumbnail_s get_thumbnail_m get_link get_keywords)
        ],
        'WWW::NOS::Open::MediaResource' => [
            qw(get_id get_type get_title get_description get_published get_last_update get_thumbnail_xs get_thumbnail_s get_thumbnail_m get_link get_keywords get_embedcode)
        ],
        'WWW::NOS::Open::Video' => [
            qw(get_id get_type get_title get_description get_published get_last_update get_thumbnail_xs get_thumbnail_s get_thumbnail_m get_link get_keywords get_embedcode)
        ],
        'WWW::NOS::Open::AudioFragment' => [
            qw(get_id get_type get_title get_description get_published get_last_update get_thumbnail_xs get_thumbnail_s get_thumbnail_m get_link get_keywords get_embedcode)
        ],
        'WWW::NOS::Open::Broadcast' => [
            qw(get_id get_type get_channel_icon get_channel_code get_channel_name get_starttime get_endtime get_genre get_title get_description)
        ],
        'WWW::NOS::Open::DayGuide' => [
            qw(get_type get_date get_broadcasts)
        ],
    );
    my $total_methods = 0;
    foreach my $methods ( values %MAIN::methods ) {
        $total_methods += @$methods;
    }
    plan tests => 1 + ( 10 * 3 ) + $total_methods + 1 + 1;
    ok(1);    # If we made it this far, we're ok.
    use_ok('WWW::NOS::Open');
    use_ok('WWW::NOS::Open::Version');
    use_ok('WWW::NOS::Open::TypeDef');
    use_ok('WWW::NOS::Open::Resource');
    use_ok('WWW::NOS::Open::Article');
    use_ok('WWW::NOS::Open::MediaResource');
    use_ok('WWW::NOS::Open::Video');
    use_ok('WWW::NOS::Open::AudioFragment');
    use_ok('WWW::NOS::Open::DayGuide');
    use_ok('WWW::NOS::Open::Broadcast');
}
my $version_args = [ q{v1}, q{0.0.1} ];
new_ok('WWW::NOS::Open');
new_ok('WWW::NOS::Open::TypeDef');
new_ok('WWW::NOS::Open::Version', $version_args );
new_ok('WWW::NOS::Open::Resource');
new_ok('WWW::NOS::Open::Article');
new_ok('WWW::NOS::Open::MediaResource');
new_ok('WWW::NOS::Open::Video');
new_ok('WWW::NOS::Open::AudioFragment');
new_ok('WWW::NOS::Open::DayGuide');
new_ok('WWW::NOS::Open::Broadcast');

my $sub;
@WWW::NOS::Open::Sub::ISA          = qw(WWW::NOS::Open);
$sub                               = new_ok('WWW::NOS::Open::Sub');
@WWW::NOS::Open::TypeDef::Sub::ISA = qw(WWW::NOS::Open::TypeDef);
$sub = new_ok( 'WWW::NOS::Open::TypeDef::Sub');
@WWW::NOS::Open::Version::Sub::ISA = qw(WWW::NOS::Open::Version);
$sub = new_ok( 'WWW::NOS::Open::Version::Sub', $version_args );
@WWW::NOS::Open::Resource::Sub::ISA = qw(WWW::NOS::Open::Resource);
$sub                                = new_ok('WWW::NOS::Open::Resource::Sub');
@WWW::NOS::Open::Article::Sub::ISA  = qw(WWW::NOS::Open::Article);
$sub                                = new_ok('WWW::NOS::Open::Article::Sub');
@WWW::NOS::Open::MediaResource::Sub::ISA = qw(WWW::NOS::Open::MediaResource);
$sub                                = new_ok('WWW::NOS::Open::MediaResource::Sub');
@WWW::NOS::Open::Video::Sub::ISA    = qw(WWW::NOS::Open::Video);
$sub                                = new_ok('WWW::NOS::Open::Video::Sub');
@WWW::NOS::Open::AudioFragment::Sub::ISA = qw(WWW::NOS::Open::AudioFragment);
$sub = new_ok('WWW::NOS::Open::AudioFragment::Sub');
@WWW::NOS::Open::DayGuide::Sub::ISA = qw(WWW::NOS::Open::DayGuide);
$sub = new_ok('WWW::NOS::Open::DayGuide::Sub');
@WWW::NOS::Open::Broadcast::Sub::ISA = qw(WWW::NOS::Open::Broadcast);
$sub = new_ok('WWW::NOS::Open::Broadcast::Sub');

foreach my $module ( keys %MAIN::methods ) {
    foreach my $method ( @{ $MAIN::methods{$module} } ) {
        can_ok( $module, $method );
    }
}

my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{TEST_AUTHOR};
}
$ENV{TEST_AUTHOR} && Test::NoWarnings::had_no_warnings();
