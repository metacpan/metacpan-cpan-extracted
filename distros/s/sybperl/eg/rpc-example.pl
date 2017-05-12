#!/usr/local/bin/perl
#
# @(#)rpc-example.pl	1.2 9/19/95
#
# THis is an example of dbrpc*() calls usage in sybperl.
#
# It is based on a stored proc that we use at ITF to compute the
# unrealised value of a futures trading account. THe stored proc gets
# the account number and the date as input, and outputs the value in two
# MONEY parameters (one in US$, the other in the reference curreny of
# the account).
#
# Proc usage:
#
# exec compute_open_val @account, @date, @val1 out, @val2 out

use Sybase::DBlib;

$d = new Sybase::DBlib;

$d->dbrpcinit("t_proc", 0) || die "rpcinit failed";
$acc = 'CIS 98941';
$d->dbrpcparam("\@account", 0, SYBCHAR, -1, length($acc), $acc) ||
    die "rpcparam ($acc) failed";
$date = '950529';
$d->dbrpcparam("\@date", 0, SYBCHAR, -1, length($date), $date) ||
    die "rpcparam ($date) failed";
$d->dbrpcparam("\@open_val", DBRPCRETURN, SYBFLT8, -1, -1, 0) ||
    die "rpcparam (\@open_val) failed";
$d->dbrpcparam("\@open_val_t", DBRPCRETURN, SYBFLT8, -1, -1, 0) ||
    die "rpcparam (\@open_val_t) failed";
$d->dbrpcsend || die "rpcsend failed";
while($d->dbresults != NO_MORE_RESULTS)
{
    while(@dat = $d->dbnextrow)
    {
	print "@dat\n";
    }
}
if($d->dbhasretstat)
{
    print "Return status: ", $d->dbretstatus, "\n";
}
%ret = $d->dbretdata(1);
foreach (keys(%ret))
{
    print "$_: $ret{$_}\n";
}

# prints:
# @open_val: some_numeric_value
# @open_val_t: some_other_numeric_value


