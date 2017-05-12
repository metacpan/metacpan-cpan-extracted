#!perl -T

use Test::More tests => 14;

use lib '../lib';
BEGIN { use_ok('Win32::Env') }

my $caught_warn;

sub catch_warn_sub{
 my $rx=shift;
 return sub { my $warn=shift; $caught_warn+=($warn=~/$rx/); };
}

sub test_sys_or_usr_warn{
 no strict 'refs';
 my $sub=\&{$_[0]};
 local $SIG{__WARN__}=catch_warn_sub(qr/sys_or_usr.*ENV_USER.*ENV_SYSTEM/);
 $caught_warn=0;
 &$sub();
 ok($caught_warn, "get warning about \$sys_or_usr from $_[0]");
}

sub test_variable_warn{
 no strict 'refs';
 my $sub=\&{$_[0]};
 local $SIG{__WARN__}=catch_warn_sub(qr/\$variable.*defined.*empty/);
 $caught_warn=0;
 &$sub(ENV_USER);
 ok($caught_warn, "get warning about \$variable from $_[0] (variable not defined)");
 $caught_warn=0;
 &$sub(ENV_USER, '');
 ok($caught_warn, "get warning about \$variable from $_[0] (variable is empty)");
}

test_sys_or_usr_warn('GetEnv');
test_sys_or_usr_warn('SetEnv');
test_sys_or_usr_warn('ListEnv');
test_sys_or_usr_warn('DelEnv');
test_sys_or_usr_warn('InsertPathEnv');

test_variable_warn('GetEnv');
test_variable_warn('SetEnv');
test_variable_warn('DelEnv');
test_variable_warn('InsertPathEnv');