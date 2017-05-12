use strict;
use Test::More;
use t::TT2LikeTest qw(render_ok);

use_ok "Text::Xslate";
use_ok "Text::Xslate::Bridge::TT2Like";

# note(Text::Xslate::Bridge::TT2Like->dump);

render_ok q{[% "foo\n\nbar" | html_para %]}, undef, "<p>\nfoo\n</p>\n\n<p>\nbar</p>\n";
render_ok q{[% "foo\n\nbar" | html_para %]}, undef, "<p>\nfoo\n</p>\n\n<p>\nbar</p>\n";
render_ok q{[% "foo\n\nbar" | html_break %]}, undef, "foo\n<br />\n<br />\nbar";
render_ok q{[% "foo\n\nbar" | html_para_break %]}, undef, "foo\n<br />\n<br />\nbar";
render_ok q{[% "foo\n\nbar" | html_line_break %]}, undef, "foo<br />\n<br />\nbar";
render_ok q{[% "&'" | xml  %]}, undef, "&amp;&apos;";
render_ok q{[% "my file.html" | uri  %]}, undef, "my%20file.html";
render_ok q{[% "my file.html" | url  %]}, undef, "my%20file.html";
render_ok '[% "foo" | upper %]', undef, "FOO", "foo.uc";
render_ok '[% "fOo" | lower %]', undef, "foo", "foo.lc";
render_ok '[% "foo" | ucfirst %]', undef, "Foo";
render_ok '[% "FOO" | lcfirst %]', undef, "fOO";
render_ok '[% "  FOO  " | trim %]', undef, "FOO";
render_ok '[% "  I am    a  pen.  " | collapse %]', undef, "I am a pen.";

render_ok '[% "foo\nbar" | indent("me> ") %]', undef, "me&gt; foo\nme&gt; bar";
render_ok '[% "7" | format("%03d") %]', undef, "007";
render_ok '[% "7" | repeat(3) %]', undef, "777";
render_ok '[% "I am a pen." | replace("pen", "John") %]', undef, "I am a John.";
render_ok '[% "pen." | remove("n") %]', undef, "pe.";
render_ok '[% "aiueoaiueo" | truncate(5) %]', undef, "ai...";


done_testing();
