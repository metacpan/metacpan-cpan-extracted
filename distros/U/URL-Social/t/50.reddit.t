use Test::More;

use FindBin;
use URL::Social;

my $url = ( $ENV{HARNESS_ACTIVE} ) ? 'file://' . $FindBin::Bin . '/data/reddit_imgur.json' : 'http://imgur.com/a/m9ykz';

my $social = URL::Social->new(
    url => $url,
);

ok( $social->reddit->upvote_count   >= 350, 'upvote_count'   );
ok( $social->reddit->downvote_count >= 350, 'downvote_count' );
ok( $social->reddit->comment_count  >= 350, 'comment_count'  );

foreach my $post ( @{$social->reddit->posts} ) {
    ok( defined $post->comment_count, 'comment_count' );
}

my $url = ( $ENV{HARNESS_ACTIVE} ) ? 'file://' . $FindBin::Bin . '/data/reddit_foobar.json' : 'http://www.foobar.com/sdgsdfgdfgdfgdfgd/';

$social = URL::Social->new(
    url => $url,
);

ok( $social->reddit->comment_count == 0, 'comment_count' );

done_testing;
