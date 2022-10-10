use strict;
use warnings;

use Test2::V0;

use Text::HyperScript qw(true);
use Text::HyperScript::HTML5 qw(p hr script);

sub main {
    is( hr, '<hr />' );

    is( p( 'hello, ', 'guest!' ), '<p>hello, guest!</p>' );

    is( script( { crossorigin => true }, '' ), '<script crossorigin></script>' );

    for my $tag (@Text::HyperScript::HTML5::EXPORT) {
        local $@;
        my $result = eval qq[
          package Text::HyperScript::HTML5::Test;

          use Text::HyperScript::HTML5;

          return ${tag}({id=> 'test'}, '');
        ];

        ok( !$@, "error of ${tag}:${@}" );

        $tag =~ s{_}{}g;
        is( $result, qq(<${tag} id="test"></${tag}>) );
    }

    done_testing;
}

main;
