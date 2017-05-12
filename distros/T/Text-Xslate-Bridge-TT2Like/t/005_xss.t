use strict;
use Test::More;
use t::TT2LikeTest qw(render_ok);

use_ok "Text::Xslate";
use_ok "Text::Xslate::Util", "html_escape";
use_ok "Text::Xslate::Bridge::TT2Like";

# note(Text::Xslate::Bridge::TT2Like->dump);

my $xss = "<script>alert(1)</script>";
my $e   = html_escape($xss)->as_string;

my $vars = { xss => $xss };

render_ok q{[% xss _ "foo\n\nbar" | html_para %]},       $vars, "<p>\n${e}foo\n</p>\n\n<p>\nbar</p>\n";
render_ok q{[% xss _ "foo\n\nbar" | html_break %]},      $vars, "${e}foo\n<br />\n<br />\nbar";
render_ok q{[% xss _ "foo\n\nbar" | html_para_break %]}, $vars, "${e}foo\n<br />\n<br />\nbar";
render_ok q{[% xss _ "foo\n\nbar" | html_line_break %]}, $vars, "${e}foo<br />\n<br />\nbar";


done_testing();
