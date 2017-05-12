# 	@(#)SybWWW.pm	1.2	06/27/97
package SybWWW;

sub message_handler
{
    my ($db, $message, $state, $severity, $text, $server, $procedure, $line)
	= @_;

    # Don't display 'informational' messages:
    if ($severity > 10)
    {
	print "Sybase message <b>$message</b>, Severity <b>$severity</b>, state <b>$state</b>";
	print "<br>Server <b>`$server'</b>" if defined ($server);
	print "<br>Procedure <b>`$procedure'</b>" if defined ($procedure);
	print "<br>Line <b>$line</b>" if defined ($line);
	print "<p>$text<p><p>\n\n";
	
# &dbstrcpy returns the command buffer.

	if(defined($db))
	{
	    my ($lineno, $cmdbuff) = (1, undef);

	    $cmdbuff = &Sybase::DBlib::dbstrcpy($db);
	    print "<pre>\n";
	       
	    foreach $row (split (/\n/, $cmdbuff))
	    {
		printf ("%5d> $row\n", $lineno++);
	    }
	    print "</pre>\n";
	}
    }
    elsif ($message == 0)
    {
		print "$text<p>\n";
    }
    
    0;
}

sub error_handler {
    my ($db, $severity, $error, $os_error, $error_msg, $os_error_msg)
	= @_;
    # Check the error code to see if we should report this.
    if ($error != Sybase::DBlib::SYBESMSG) {
		print "Sybase error: $error_msg<p>\n";
		print "OS Error: $os_error_msg<p>\n" if defined ($os_error_msg);
    }

    Sybase::DBlib::INT_CANCEL;
}

Sybase::DBlib::dbmsghandle(\&message_handler);
Sybase::DBlib::dberrhandle(\&error_handler);

1;
