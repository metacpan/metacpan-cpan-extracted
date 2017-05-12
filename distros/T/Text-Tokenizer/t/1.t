# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 2;
BEGIN { use_ok('Text::Tokenizer') };


my $fail = 0;
foreach my $constname (qw(
	 TOK_UNDEF TOK_TEXT TOK_DQUOTE TOK_SQUOTE TOK_IQUOTE
		TOK_SIQUOTE TOK_BLANK TOK_ERROR TOK_EOL TOK_COMMENT TOK_EOF
		TOK_BASH_COMMENT TOK_C_COMMENT TOK_CC_COMMENT
		NOERR UNCLOSED_DQUOTE UNCLOSED_SQUOTE UNCLOSED_IQUOTE NOCONTEXT
		UNCLOSED_C_COMMENT
		TOK_OPT_DEFAULT TOK_OPT_NONE TOK_OPT_NOUNESCAPE
	        TOK_OPT_SIQUOTE TOK_OPT_UNESCAPE TOK_OPT_UNESCAPE_CHARS
		TOK_OPT_UNESCAPE_LINES TOK_OPT_PASSCOMMENT TOK_OPT_PASS_COMMENT
		TOK_OPT_UNESCAPE_NQ_LINES TOK_OPT_C_COMMENT TOK_OPT_CC_COMMENT
		TOK_OPT_NO_BASH_COMMENT TOK_OPT_NO_IQUOTE)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Tokenizer macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

