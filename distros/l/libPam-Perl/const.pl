#!/usr/bin/perl

use warnings;
use strict;
my %context=(
	ret=>[qw(
		PAM_SUCCESS PAM_OPEN_ERR PAM_SYMBOL_ERR PAM_SERVICE_ERR
		PAM_SYSTEM_ERR PAM_BUF_ERR PAM_PERM_DENIED PAM_AUTH_ERR
		PAM_CRED_INSUFFICIENT PAM_AUTHINFO_UNAVAIL PAM_USER_UNKNOWN
		PAM_MAXTRIES PAM_NEW_AUTHTOK_REQD PAM_ACCT_EXPIRED
		PAM_SESSION_ERR PAM_CRED_UNAVAIL PAM_CRED_EXPIRED PAM_CRED_ERR
		PAM_NO_MODULE_DATA PAM_CONV_ERR PAM_AUTHTOK_ERR
		PAM_AUTHTOK_RECOVERY_ERR PAM_AUTHTOK_LOCK_BUSY
		PAM_AUTHTOK_DISABLE_AGING PAM_TRY_AGAIN PAM_IGNORE PAM_ABORT
		PAM_AUTHTOK_EXPIRED PAM_MODULE_UNKNOWN PAM_BAD_ITEM
		PAM_CONV_AGAIN PAM_INCOMPLETE _PAM_RETURN_VALUES
	)],
	flag=>[qw(
		PAM_DISALLOW_NULL_AUTHTOK PAM_ESTABLISH_CRED PAM_DELETE_CRED
		PAM_REINITIALIZE_CRED PAM_REFRESH_CRED
		PAM_CHANGE_EXPIRED_AUTHTOK PAM_UPDATE_AUTHTOK PAM_PRELIM_CHECK
		PAM_SILENT PAM_DATA_REPLACE PAM_DATA_SILENT
	)],
	item=>[qw(
		PAM_SERVICE PAM_USER PAM_TTY PAM_RHOST PAM_CONV PAM_AUTHTOK
		PAM_OLDAUTHTOK PAM_RUSER PAM_USER_PROMPT PAM_FAIL_DELAY
		PAM_XDISPLAY PAM_XAUTHDATA PAM_AUTHTOK_TYPE
	)],
	conv=>[qw(
		PAM_PROMPT_ECHO_OFF PAM_PROMPT_ECHO_ON 	PAM_ERROR_MSG
		PAM_TEXT_INFO PAM_RADIO_TYPE PAM_BINARY_PROMPT
	)]
);
my $fhc;
my $fhh;
my $fhx;
open $fhc, '>', 'const.c.inc' or die;
open $fhx, '>', 'const.xs.inc' or die;
open $fhh, '>', 'const.h' or die;
select $fhh;
print <<'EOT';
#ifndef _const_h
#define _const_h
#define XSRETURN_QV(s,v)	STMT_START { XST_mQV( 0,s,v); XSRETURN(1); } STMT_END
#define XSRETURN_QV2(v,c)	STMT_START { XST_mQV2(0,v,c); XSRETURN(1); } STMT_END

#define PUSHq(v,p,l)		mXPUSHs(newSVqvn(p,l,v))

#define XST_mQV(i,s,v)		(ST(i) = sv_2mortal(newSVqv(s,v)))
#define XST_mQV2(i,v,c)		(ST(i) = sv_2mortal(newSVqv2(v,c)))
#define XST_mQVn(i,s,l,v)	(ST(i) = sv_2mortal(newSVqvn(s,l,v)))

#define newSVqv(s,v)		P_newSVqv(aTHX_ s,v)
#define newSVqvn(s,l,v)		P_newSVqvn(aTHX_ s,l,v)
#define newSVqv2(v,c)		P_newSVqv2(aTHX_ v,c)
#define sv_setqvn(a,b,c,d)	P_sv_setqvn(aTHX_ a,b,c,d)

void P_sv_setqvn(pTHX_ SV* m, int i, const char* s, STRLEN len);
SV* P_newSVqv(pTHX_ const char* s, int i);
SV* P_newSVqv2(pTHX_ int i, const char* (*func)(int i,int* len));
SV* P_newSVqvn(pTHX_ const char* s, STRLEN len, int i);
SV* Q_intorconst(pTHX_ SV* s);

EOT
select $fhc;
foreach my $a (keys %context){
	print {$fhh} "const char* QContext_$a(int i, int* len);\n";
	print {$fhx} "void\nQContext_$a(int i)\n\tPROTOTYPE: \$;\n\tCODE:\n\t\tXSRETURN_QV2(i, &QContext_$a);\n\n";
	print "const char* QContext_$a(int i, int* len){\n";
	print "\tswitch (i) {\n";
	foreach (@{$context{$a}}){
		my $b=length($_);
		print "\t\tcase $_: *len=$b;return \"$_\";break;\n";
	}
	print "\t\tdefault: *len=0;return NULL;break;\n";
	print "\t}\n";
	print "}\n\n";
}
print {$fhh} "#endif /*_const_h*/\n";
select STDOUT;
close $fhh;
close $fhx;
close $fhc;

my @names = (qw(
	__LINUX_PAM_MINOR__
	__LINUX_PAM__
	PAM_MAX_NUM_MSG
	PAM_MAX_MSG_SIZE
	PAM_MAX_RESP_SIZE
), map {@{$context{$_}}} keys %context);

my $fhp;
open $fhp, '>', 'const.pl.inc' or die;
select $fhp;
print "sub map_constant(\$){\n";
print "\tmy \$_=shift;\n";
print "\ts|^[ 	]*||;\n";
print "\ts|[ 	]*\$||;\n";
foreach my $a (sort {length($b)<=>length($a)||$a cmp $b} @names){
	print "\treturn Authen::PAM::Module::$a()	if /^$a\$/i;\n";
}
print "\treturn undef;\n";
print "}\n";
select STDOUT;
close $fhp;

if(eval {require Local::ExtUtils::Constant; 1}) {
	# If you edit these definitions to change the constants used by this
	# module, you will need to use the generated const-c.inc and
	# const-xs.inc files to replace their "fallback" counterparts before
	# distributing your changes.
	ExtUtils::Constant::WriteConstants(
		NAME		=> 'Authen::PAM::Module',
		NAMES		=> \@names,
		DEFAULT_TYPE	=> 'IV',
		C_FILE		=> 'const-c.inc',
		XS_FILE		=> 'const-xs.inc',
	);
}else{
	use File::Copy;
	use File::Spec;
	foreach my $file ('const-c.inc', 'const-xs.inc') {
		my $fallback = File::Spec->catfile('fallback', $file);
		copy($fallback,$file)or die "Can't copy $fallback to $file: $!";
	}
}
