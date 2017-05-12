use Test::More;

use WWW::Mixcloud;

# Load a saved JSON API respsonse, instead of making a real API call
no warnings 'redefine';
local *WWW::Mixcloud::_api_call = sub {

    use JSON;

    local $/;
    open( my $fh, '<', 't/data/cloudcast.json' );
    $json_text   = <$fh>;
    return decode_json( $json_text );

};
use warnings;

my $mixcloud = WWW::Mixcloud->new;

my $cloudcast = $mixcloud->get_cloudcast('cloudcast');

subtest 'construction' => sub {

    isa_ok($cloudcast, 'WWW::Mixcloud::Cloudcast',
        'Created cloudcast object');

    isa_ok($cloudcast->tags->[0], 'WWW::Mixcloud::Cloudcast::Tag',
        'Cloudcast has tag objects');

    isa_ok($cloudcast->pictures->[0], 'WWW::Mixcloud::Picture',
        'Cloudcast has pictures objects');

    isa_ok($cloudcast->user, 'WWW::Mixcloud::User',
        'Cloudcast has user object');

    isa_ok($cloudcast->sections->[0], 'WWW::Mixcloud::Cloudcast::Section',
        'Cloudcast has section objects');

};

subtest 'data' => sub {

    is($cloudcast->listener_count, 886, 'Cloudcast has correct listener count');

    is($cloudcast->name, 'Gilles - Web Gems', 'Cloudcast has correct name');

    is($cloudcast->url, 'http://www.mixcloud.com/LaidBackRadio/gilles-web-gems/',
        'Cloudcast has correct URL');

    is($cloudcast->play_count, '2762', 'Cloudcast has correct play count');

    is($cloudcast->comment_count, '10', 'Cloudcast has correct comment count');

    is($cloudcast->percentage_music, '100',
        'Cloudcast has correct percentage music');
};

done_testing;
