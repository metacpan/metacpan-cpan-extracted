# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PAM-Module.t'

#########################

# change 'tests => 4' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Authen::PAM') };
BEGIN { use_ok('Authen::PAM::Module') };

my $fail = 0;
foreach my $constname (qw(
	PAM_AUTHTOK
	PAM_ABORT PAM_ACCT_EXPIRED PAM_AUTHINFO_UNAVAIL
	PAM_AUTHTOK_DISABLE_AGING PAM_AUTHTOK_ERR PAM_AUTHTOK_EXPIRED
	PAM_AUTHTOK_LOCK_BUSY PAM_AUTHTOK_RECOVERY_ERR PAM_BINARY_PROMPT
	PAM_AUTHTOK_TYPE PAM_AUTH_ERR PAM_BAD_ITEM PAM_BUF_ERR
	PAM_CHANGE_EXPIRED_AUTHTOK PAM_CONV PAM_CONV_AGAIN PAM_CONV_ERR
	PAM_CRED_ERR PAM_CRED_EXPIRED PAM_CRED_INSUFFICIENT PAM_CRED_UNAVAIL
	PAM_DATA_SILENT PAM_DELETE_CRED PAM_DISALLOW_NULL_AUTHTOK PAM_ERROR_MSG
	PAM_ESTABLISH_CRED PAM_FAIL_DELAY PAM_IGNORE PAM_INCOMPLETE
	PAM_MAXTRIES PAM_MAX_MSG_SIZE PAM_MAX_NUM_MSG PAM_MAX_RESP_SIZE
	PAM_MODULE_UNKNOWN PAM_NEW_AUTHTOK_REQD PAM_NO_MODULE_DATA
	PAM_OLDAUTHTOK PAM_OPEN_ERR PAM_PERM_DENIED PAM_PROMPT_ECHO_OFF
	PAM_PROMPT_ECHO_ON PAM_RADIO_TYPE PAM_REFRESH_CRED
	PAM_REINITIALIZE_CRED PAM_RHOST PAM_RUSER PAM_SERVICE PAM_SERVICE_ERR
	PAM_SESSION_ERR PAM_SILENT PAM_SUCCESS PAM_SYMBOL_ERR PAM_SYSTEM_ERR
	PAM_TEXT_INFO PAM_TRY_AGAIN PAM_TTY PAM_USER PAM_USER_PROMPT
	PAM_USER_UNKNOWN PAM_XAUTHDATA PAM_XDISPLAY _PAM_RETURN_VALUES
	PAM_DATA_REPLACE PAM_UPDATE_AUTHTOK PAM_PRELIM_CHECK
	__LINUX_PAM_MINOR__ __LINUX_PAM__
)) {
	if (eval "my \$a = Authen::PAM::Module::$constname(); 1"){
		my $b=eval('Authen::PAM::Module::'.$constname.'();');
		if(defined($b)){
			printf "% 10s\t%s\t%s\n", $b+0,$b.'',$constname;
		}else{
			printf "     undef\t%s\n", $constname;
		}
		next;
	};
	#warn $constname;
	#if ($@ =~ /^The symbol $constname is not supported by your PAM library/) {
	#if ($@ =~ /^Your vendor has not defined Authen::PAM::Module macro $constname/) {
		#warn "# pass: $@";
		#print "# pass: $@";
	#} else {
		warn "# fail: $@";
		print "# fail: $@";
		$fail = 1;
	#}
}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, "EOF");
