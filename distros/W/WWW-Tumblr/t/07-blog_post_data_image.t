use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Basename qw( dirname );
use Cwd 'abs_path';

# Must load these first to check skip conditions
use WWW::Tumblr;
use WWW::Tumblr::Test;

# Check if we should skip posting tests entirely
if (my $reason = WWW::Tumblr::Test::skip_posting_tests()) {
    plan skip_all => $reason;
}

my $blog = WWW::Tumblr::Test::blog();

my $post = $blog->post(
    type => 'photo',
    data => [ File::Spec->catfile( dirname( abs_path( $0 ) ), 'data', 'larrywall.jpg' ) ],
);

if ($post) {
    pass('data posting');
} else {
    if ($blog->error && WWW::Tumblr::Test::check_rate_limit($blog->error)) {
        SKIP: { skip "Rate limit exceeded", 1; }
    } else {
        fail('data posting');
        diag("Error: " . join(', ', @{$blog->error->reasons || ['Unknown']}));
    }
}

done_testing();
