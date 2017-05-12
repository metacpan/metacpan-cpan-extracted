use strict;
use Test::More;
use t::TT2LikeTest qw(render_ok);

use_ok "Text::Xslate";
use_ok "Text::Xslate::Bridge::TT2Like";

# note Text::Xslate::Bridge::TT2Like->dump;

render_ok '[% foo.length() %]', undef, 3, "foo.length";
render_ok '[% foo.size() %]', undef, 1, "foo.size";
render_ok '[% foo.match( "o", 1 ).join("") %]', undef, 'oo', "foo.match";
render_ok '[% IF (foo.search( "fo" )) %]match[% ELSE %]no match[% END %]', undef, "match", "foo.search (MATCH)";
render_ok '[% IF (foo.search( "bar" )) %]match[% ELSE %]no match[% END %]', undef, "no match", "foo.search (NO MATCH)";
render_ok '[% foo.remove( "oo" ) %]', undef, "f", "foo.remove";
render_ok '[% foobar.split().size() %]', undef, 2, "foobar.split (size)";
render_ok '[% foobar.split().0 %]', undef, "foo", "foobar.split (foo)";
render_ok '[% foobar.split().1 %]', undef, "bar", "foobar.split (bar)";
render_ok '[% foobar.chunk(2).0 %]', undef, "fo", "foobar.chunk 0";
render_ok '[% foobar.chunk(2).1 %]', undef, "o ", "foobar.chunk 1";
render_ok '[% foobar.replace("bar", "baz") %]', undef, "foo baz", "foobar.replace";
render_ok '[% foobar.substr( 0, 2 ) %]', undef, "fo", "foobar.substr (get)";
render_ok '[% foobar.substr( 0, 2, "ba" ) %]', undef, "bao bar", "foobar.substr (replace)";


done_testing();
