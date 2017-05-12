#!/usr/local/bin/perl
#
#	@(#)ctlib.pl	1.1	8/7/95
# This is a very simple example for the experimental CTlib
# extension to Perl.

#BEGIN {$ENV{SYBASE} = "/usr/local/sybase10"; unshift @INC, "../../../lib";}

use Sybase::CTlib;

ct_callback(CS_CLIENTMSG_CB, \&msg_cb);
ct_callback(CS_SERVERMSG_CB, "srv_cb");

$uid = 'mpeppler';	# I doubt that this will work on your system :-)
$pwd = 'Im not tellin...';
$srv = 'TROLL';

$X = Sybase::CTlib->ct_connect($uid, $pwd, $srv);

print "CS_CMD_SUCCEED: ", CS_CMD_SUCCEED, "\n";
print "CS_CMD_DONE: ", CS_CMD_DONE, "\n";
print "CS_ROW_RESULT: ", CS_ROW_RESULT, "\n";

$X->ct_execute("select * from sysusers") || die "execute failed!";
#$X->ct_command(CS_LANG_CMD, "select * from sysusers", CS_NULLTERM, CS_UNUSED);
#$X->ct_send();

while(($rc = $X->ct_results($restype)) == CS_SUCCEED)
{
    print "\$restype = $restype\n";
    next if ($restype == CS_CMD_DONE ||
	     $restype == CS_CMD_FAIL ||
	     $restype == CS_CMD_SUCCEED);
    if(@names = $X->ct_col_names())
    {
	print "@names\n";
    }
    if(@types = $X->ct_col_types())
    {
	print "@types\n";
    }
    while(@dat = $X->ct_fetch)
    {
	print "@dat\n";
    }
}
print "End of Results Sets\n" if($rc == CS_END_RESULTS);
print "Error!\n" if($rc == CS_FAIL);

($ret, $rowcount) = $X->ct_options(CS_GET, CS_OPT_ROWCOUNT, $rowcount, CS_INT_TYPE);

warn "options failed\n" if $ret != CS_SUCCEED;

print "$ret $rowcount\n";

sub msg_cb
{
    my($layer, $origin, $severity, $number, $msg, $osmsg) = @_;

    printf STDERR "\nOpen Client Message: (In msg_cb)\n";
    printf STDERR "Message number: LAYER = (%ld) ORIGIN = (%ld) ",
	    $layer, $origin;
    printf STDERR "SEVERITY = (%ld) NUMBER = (%ld)\n",
	    $severity, $number;
    printf STDERR "Message String: %s\n", $msg;
    if (defined($osmsg))
    {
	printf STDERR "Operating System Error: %s\n",
		$osmsg;
    }
    CS_SUCCEED;
}
    
sub srv_cb
{
    my($cmd, $number, $severity, $state, $line, $server, $proc, $msg) = @_;

    printf STDERR "\nServer message: (In srv_cb)\n";
    printf STDERR "Message number: %ld, Severity %ld, ",
               $number, $severity;
    printf STDERR "State %ld, Line %ld\n",
               $state, $line;
    
    if (defined($server))
    {
	printf STDERR "Server '%s'\n", $server;
    }
    
    if (defined($proc))
    {
	printf STDERR " Procedure '%s'\n", $proc;
    }

    printf STDERR "Message String: %s\n", $msg;
				# 
    CS_SUCCEED;
}
    
