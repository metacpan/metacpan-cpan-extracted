use strict;
use Test::More;
use t::TT2LikeTest qw(render_ok);

use_ok "Text::Xslate";
use_ok "Text::Xslate::Bridge::TT2Like";

render_ok '[% strings.size() %]', undef, 4, "strings.size";
render_ok '[% strings.join("-") %]', undef, "abc-def-ghi-jkl", "strings.join";
render_ok '[% CALL strings.push("end"); strings.4 %]', undef, "end", "strings.push";
render_ok '[% strings.pop() %]', undef, "jkl", "strings.pop";
render_ok '[% CALL strings.unshift("begin"); strings.0 %]', undef, "begin", "strings.unshift";
render_ok '[% strings.shift() %]', undef, "abc", "strings.shift";
render_ok '[% strings.max() %]', undef, 3, "strings.max";
render_ok '[% strings.size() %]', undef, 4, "strings.size";
render_ok '[% strings.defined() %]', undef, 1, "strings.defined";
render_ok '[% strings.first() %]', undef, "abc", "strings.first";
render_ok '[% strings.last() %]', undef, "jkl", "strings.last";
render_ok '[% strings.reverse().shift() %]', undef, "jkl", "strings.reverse";
render_ok '[% strings.grep( "[ce]" ).join("-") %]', undef, "abc-def", "strings.grep";
render_ok '[% CALL strings.unshift("zzz"); strings.sort().join("-") %]', undef, 'abc-def-ghi-jkl-zzz', "strings.sort";
render_ok '[% CALL numbers.unshift(99); numbers.nsort().join("-") %]', undef, "1-2-3-4-5-99", "numbers.nsort";
render_ok '[% CALL numbers.unshift(1); numbers.unique().join("-") %]', undef, "1-2-3-4-5", "numbers.unique";
render_ok '[% SET newlist = [ 6, 7, 8, 9 ]; CALL numbers.import( newlist ); numbers.join("-") %]', undef, "1-2-3-4-5-6-7-8-9", "numbers.import";
render_ok '[% SET newlist = numbers.merge( [ 6, 7, 8, 9 ] ); newlist.join("-") %]', undef, "1-2-3-4-5-6-7-8-9", "numbers.merge 1";
render_ok '[% SET newlist = numbers.merge( [ 6, 7, 8, 9 ] ); numbers.join("-") %]', undef, "1-2-3-4-5", "numbers.merge 2";
render_ok '[% numbers.slice( 1, 3 ).join("-") %]', undef, "2-3-4", "numbers.slice";
render_ok '[% CALL numbers.splice( 1, 3, [ 99 ] ); numbers.join("-") %]', undef, "1-99-5", "numbers.splice";

done_testing();