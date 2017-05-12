use Test::More tests => 50;
BEGIN { use_ok('WWW::BookBot::Test'); use_ok(test_init('WWW::BookBot')); };
test_begin();

#------ en_code and de_code
$str="This is a Test!";
new_bot(LANGUAGE_ENCODE=>'', LANGUAGE_DECODE=>'');
test_encoding($str, $str, "without conversion");
new_bot();
test_encoding($str, $str, "with conversion");

#------ parse_patterns
test_parse_patterns('$3$4', '\$3\$4', 'auto \\');
test_parse_patterns("\n1\n2\n3\n4\n", '1|2|3|4', '\\n -> |');
test_parse_patterns('Ab', '[aA][bB]', 'case insensitive');
test_parse_patterns('\b[a-ZbE]', '\b[a-ZbE]', 'special forms of RE');
test_parse_patterns("(case)\nDDD\nEEE", 'DDD|EEE', 'preserve case sensitive');

#------ utilities: msg_format, files, log, result, DB
my $msg_para={TestInfo=>"OK",TestNum=>7};
my $msg_result="Test: OK 7";
test_msg_format($msg_para, $msg_result);
test_file("MSG1", "MSG2");
test_log("MSG1", "MSG2", "Encode\$Test", $msg_para, $msg_result);
test_result("MSG1", "MSG2");
test_DB();

#------ agent, url, fetch
test_agent();
test_url();
test_fetch();

#------ parse functions
#$bot->{REMOVE_LEADING_SPACES}=1;
#test_parser('remove_leadingspace',
#	"\n    a good\n  dog\n  must\n  be\n  good.\n",
#	"\n  a good\ndog\nmust\nbe\ngood.\n",
#);
#$bot->{REMOVE_INNER_SPACES}=1;
#test_parser('remove_innerspace',
#	"T h i s  i s  a  t e s t. Y e t  a n o t h e r",
#	"This is a test. Yet another",
#);
new_bot();
test_parser('normalize_space', "\001\002", '  ');
test_parser('remove_html',
	"<a href='5'> Test</a>\n<script src='my.js'>do();\n</script>Good<!--<br>inner\n-->",
	" Test\nGood",
);
test_parser('decode_entity', '&nbsp;&#79&#107;', ' Ok');
test_parser('normalize_paragraph_1',
	"\n  Good\n----\n\n----\n Over  \n  ",
	" Good\n ---\n Over",
);
test_parser('parse_title',
	"  Tit'le is\n o'k  ",
	"Tit'le is o'k",
	"without enclose",
);
test_parser('parse_title',
	"  'Title is\n ok'.  ",
	"Title is ok",
	"with enclose",
);
test_parser('normalize_paragraph',
	"\n   Test<br>\nOK  \n",
	"    Test\n    OK",
);

#------ main function
test_catalog_get_book(
	"BAD CATLOG",
	"Begin <a href='my.txt' target=_blank\n>TEST</A> End",
	"http://www.sina.com.cn/my.txt",
	"TEST"
);
test_book_chapters(
	"BAD CATLOG",
	"Begin <a href='my.txt' target=_blank\n>TEST</A> End",
	"http://www.sina.com.cn/my.txt",
	"TEST"
);
test_writebin("A b\nef");
test_parse_bintext("TESTS");

#------ The End
#dump_var('Patterns');
#test_pattern('space', '&nbsp');
test_end();