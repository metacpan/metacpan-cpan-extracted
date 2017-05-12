use strict;
use warnings;

use Test::More;

use_ok('WWW::Tumblr');
use_ok('WWW::Tumblr::Test');

my $blog = WWW::Tumblr::Test::blog();

for my $size ( '', qw(16 24 30 40 48 64 96 128 512) ) {
    my %size_opts = ();
    %size_opts = ( size => $size ) if $size;
    my $avatar = $blog->avatar( %size_opts );
    ok $avatar,     'avatar response ok';
    ok ref $avatar, 'avatar response is a reference';
    is ref $avatar, 'HASH',   'avatar response reference is a hash';
    ok defined $avatar->{avatar_url},  'contains an avatar_url param';
}

done_testing();


