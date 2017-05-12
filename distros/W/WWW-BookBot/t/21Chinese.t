use Test::More tests => 50;
BEGIN { use_ok('WWW::BookBot::Test'); use_ok(test_init('WWW::BookBot::Chinese')); };
test_begin();

#------ en_code and de_code
$str="测试代码";
new_bot(LANGUAGE_ENCODE=>'', LANGUAGE_DECODE=>'');
test_encoding($str, $str, "without conversion");
new_bot();
test_encoding($str, $str, "with conversion");

#------ parse_patterns
test_parse_patterns('$3$4', '\$3\$4', 'auto \\');
test_parse_patterns("\n1\n2\n3\n4\n", '1|2|3|4', '\\n -> |');
test_parse_patterns('Ab', '[aA][bB]', 'case insensitive');
test_parse_patterns('\b[a-ZbE]', '\b[a-ZbE]', 'special forms of RE');
test_parse_patterns("(case)\n测试DDD\n顺利EEE", '测试DDD|顺利EEE', 'preserve case sensitive');

#------ utilities: msg_format, files, log, result, DB
my $msg_para={TestInfo=>"正常",TestNum=>7};
my $msg_result="测试: 正常 7";
test_msg_format($msg_para, $msg_result);
test_file("测", "试");
test_log("测", "试", "编码\$测试", $msg_para, $msg_result);
test_result("测", "试");
test_DB();

#------ agent, url, fetch
test_agent();
test_url();
test_fetch();

#------ parse functions
#$bot->{REMOVE_LEADING_SPACES}=1;
#test_parser('remove_leadingspace',
#	"\n   测试\n  过程\n  还是\n  不错\n  的。\n",
#	"\n 测试\n过程\n还是\n不错\n的。\n",
#);
#$bot->{REMOVE_INNER_SPACES}=1;
#test_parser('remove_innerspace',
#	"户， 而 解 密 密 钥 由 用 户 自 己 保 存－－。 这 样 以 来， 密 钥 保 存 量 少",
#	"户， 而解密密钥由用户自己保存－－。 这样以来， 密钥保存量少",
#);
new_bot();
test_parser('normalize_space', "\001\002　", '    ');
test_parser('remove_html',
	"<a href='5'> 测试</a>\n<script src='my.js'>do();\n</script>正确<!--<br>显示\n-->",
	" 测试\n正确",
);
test_parser('decode_entity', '&nbsp;&#79&#107;', ' Ok');
test_parser('normalize_paragraph_1',
	"\n  测试\n※ ※ ※\n\n----\n 正确  \n  ",
	" 测试\n ---\n 正确",
);
test_parser('parse_title',
	"  标题《显示 是\n 正》常  ",
	"标题《显示 是 正》常",
	"without enclose",
);
test_parser('parse_title',
	"  《测试标题》。  ",
	"测试标题",
	"with enclose",
);
test_parser('normalize_paragraph',
	"\n   测试<br>\n正确  \n",
	"　　测试\n　　正确",
);

#------ parse utilities
test_catalog_get_book(
	"错误目录",
	"开始 <a href='my.txt' target=_blank\n>测试</A> 结束",
	"http://www.sina.com.cn/my.txt",
	"测试"
);
test_book_chapters(
	"错误目录",
	"开始 <a href='my.txt' target=_blank\n>测试</A> 结束",
	"http://www.sina.com.cn/my.txt",
	"测试"
);
test_writebin("测试\n数据");
test_parse_bintext("测试文本");

#------ The End
#dump_var('Patterns');
#test_pattern('remove_line_by_end', '中华网');
test_end;