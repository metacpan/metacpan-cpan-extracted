# $Id: ctutil.pl,v 1.1 2001/07/03 23:48:27 mpeppler Exp $
# @(#)ctutil.pl	1.4	03/05/98
#
# Copyright (c) 1995
#   Michael Peppler
#
#   You may copy this under the terms of the GNU General Public License,
#   or the Artistic License, copies of which should have accompanied
#   your Perl kit.

#
# Some utility stuff for Sybase::CTlib
#

sub msg_cb
{
    my($layer, $origin, $severity, $number, $msg, $osmsg, $dbh) = @_;

    print STDERR "\nOpen Client Message:\n";
    printf STDERR ("Message number: LAYER = (%ld) ORIGIN = (%ld) ",
		   $layer, $origin);
    printf STDERR ("SEVERITY = (%ld) NUMBER = (%ld)\n",
		   $severity, $number);
    print STDERR "Message String: $msg\n";
    if (defined($osmsg)) {
	printf STDERR ("Operating System Error: %s\n", $osmsg);
    }

    CS_SUCCEED;
}
    
sub srv_cb
{
    my($dbh, $number, $severity, $state, $line, $server, $proc, $msg)
	= @_;

    # Don't print informational or status messages
    if($severity > 10)
    {
        printf STDERR ("Message number: %ld, Severity %ld, ",
			  $number, $severity);
	printf STDERR ("State %ld, Line %ld\n",
			   $state, $line);
	       
	if (defined($server)) {
	    printf STDERR ("Server '%s'\n", $server);
	}
    
	if (defined($proc)) {
	    printf STDERR (" Procedure '%s'\n", $proc);
	}

	print STDERR "Message String: $msg\n";

	# Handle Extended Error information:
	if($dbh->{ExtendedError}) {
	    my(@fmt, $key, $l, @dat);
	    
	    print STDERR "\n[Start Extended Error]\n\n";
	    
	    @fmt = $dbh->ct_describe;
	    foreach (@fmt) {
		printf STDERR "%-$$_{MAXLENGTH}s", $$_{NAME};
	    }
	    print STDERR "\n";
	    foreach (@fmt) {
		$l = '-' x ($$_{MAXLENGTH}-1);
		print STDERR "$l ";
	    }
	    print STDERR "\n";
	    while(@dat = $dbh->ct_fetch) {
		for($i = 0; $i < scalar(@dat); ++$i) {
		    printf STDERR "%-$fmt[$i]->{MAXLENGTH}s", $dat[$i];
		}
		print STDERR "\n\n[End Extended Error]\n";
	    }
	}
    }
    elsif ($number == 0)
    {
	print STDERR "$msg\n";
    }

    CS_SUCCEED;
}
    

ct_callback(CS_CLIENTMSG_CB, \&msg_cb);
ct_callback(CS_SERVERMSG_CB, \&srv_cb);

1;
