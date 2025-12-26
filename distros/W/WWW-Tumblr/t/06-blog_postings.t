use strict;
use warnings;
use utf8;

use Test::More;

# Must load these first to check skip conditions
use WWW::Tumblr;
use WWW::Tumblr::Test;

# Check if we should skip posting tests entirely
if (my $reason = WWW::Tumblr::Test::skip_posting_tests()) {
    plan skip_all => $reason;
}

use LWP::Simple 'get';
use JSON;
use Data::Dumper;
use Encode 'decode_utf8';

my %post_types = (
    text    => { body => scalar localtime() },
    photo   => { source => 'https://picsum.photos/400/200' },
    quote   => { quote => 'The only way to do great work is to love what you do. - Steve Jobs' },
    link    => do {
        eval {
            my $data = decode_json( get("https://fastapi.metacpan.org/v1/favorite/_search?size=50&fields=author,release&sort=date:desc") );
            my $hit = $data->{hits}->{hits}->[ int rand @{$data->{hits}->{hits}} ];
            my ( $author, $release ) = @{ $hit->{fields} }{'author', 'release'};
            { url => "https://metacpan.org/release/$author/$release" }
        } or do {
            { url => "https://damog.net/blog" }
        };
    },
);

# TODO: chat, audio, video

my $blog = WWW::Tumblr::Test::blog();

for my $type ( sort keys %post_types ) {
    # Skip if we've hit rate limit
    if (WWW::Tumblr::Test::is_rate_limited()) {
        SKIP: { skip "Rate limit exceeded", 1; }
        next;
    }
    
    my $result = $blog->post( type => $type, %{ $post_types{ $type } } );
    if ($result) {
        pass("trying $type");
    } else {
        if ($blog->error && WWW::Tumblr::Test::check_rate_limit($blog->error)) {
            SKIP: { skip "Rate limit exceeded", 1; }
        } else {
            fail("trying $type");
            diag("Error: " . join(', ', @{$blog->error->reasons || ['Unknown']}));
        }
    }
}

# Test UTF-8 posting (PR #15)
SKIP: {
    skip "Rate limit exceeded", 1 if WWW::Tumblr::Test::is_rate_limited();
    
    my $utf8_body = scalar(localtime()) . " - UTF-8 test: \x{65e5}\x{672c}\x{8a9e}";  # Japanese chars
    my $result = $blog->post(type => 'text', body => $utf8_body);
    if ($result) {
        pass("trying text with UTF-8 characters");
    } else {
        if ($blog->error && WWW::Tumblr::Test::check_rate_limit($blog->error)) {
            skip "Rate limit exceeded", 1;
        } else {
            fail("trying text with UTF-8 characters");
        }
    }
}

done_testing();
