package ZM::Session;
$ZM::Session::VERSION = '0.2.1';
use strict;

sub new
{
    my ($c, %args) = @_;
    my $class = ref($c) || $c;
    $args{SID} = $args{id};
    bless \%args, $class;
}

sub start
{
	my ($cl,$print_content,$no_cookie, $double_enter) = @_;
    if (!defined($cl->{lifetime}))
	{
		$cl->{lifetime} = 600;
	}
    if (!defined($cl->{path}))
	{
		$cl->{path} = "/tmp/";
	}
    # Set ID if not defined
    if ((!defined($cl->{SID})) || ((length($cl->{SID}) == 0)))
	{
		$cl->id($cl->newID());
	}
	if($no_cookie eq "")
	{
		#SET COOKIE
		my @week=("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday");
		my @months=("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday)=gmtime(time()+$cl->{lifetime});
		my $t=sprintf("%s, %02d-%s-%02d %02d:%02d:%02d GMT",$week[$wday],$mday,$months[$mon],$year % 100,$hour,$min,$sec);
		print "Content-type: text/html\n" if($print_content ne "nocontent");
		print $cl->{head};
		print "Set-Cookie: SID=".$cl->id."; expires=".$t."; path=/\n";
		print "\n" if $double_enter eq "";
	}
    if (-e $cl->getfile())
	{
		return 0;
	}
    open(SF,">".$cl->getfile());
	close(SF);
    $cl->check_sessions();
	#SET IP
	if (defined($cl->{check_ip}))
	{
		$cl->set("SID_IP",$ENV{REMOTE_ADDR});
	}
    return 1;
}

sub check_sessions
{
    my $cl = shift;
    opendir(SD,$cl->{path});
    my @files = readdir(SD);
#    shift @files;
#    shift @files;
    foreach my $f (@files)
	{
	    next if $f!~/^zm_sess_/;
		if (((stat($cl->{path}.$f))[9] + $cl->{lifetime}) < time())
		{ 
			unlink($cl->{path}.$f); 
		}
	}
    closedir(SD);
}

sub destroy
{
    my $cl = shift;
    if (!$cl->have_id())
	{
		return -1;
	}
    if (-e $cl->getfile())
	{
		unlink($cl->getfile());
	}
    undef $cl->{SID};
    if (defined($cl->{id}))
	{
		undef $cl->{id};
	}
    return 1;
}

sub exists
{
    my ($cl,$id) = @_;
    if (!defined($id))
	{
		return 0;
	}
    my $file = $cl->{path}."zm_sess_".$cl->{$id};
    if (-e $file)
	{
		return 1;
	}
    return 0;
}

sub have_id
{
    my $cl = shift;
    if (!defined($cl->{SID}))
	{
		return 0;
	}
    return 1;
}

sub set_path
{
    my ($cl, $path) = @_;
    if (defined($path)) { $cl->{path} = $path }
    return $cl->{path};
}

sub id
{
    my ($cl, $newid) = @_;
    if (defined($newid))
	{
		$cl->{SID} = $newid;
	}
	if (!$cl->have_id())
	{
		return -1;
	}
    return $cl->{SID};
}

sub getfile
{
    my $cl = shift;
    return $cl->{path}."zm_sess_".$cl->{SID};
}

sub is_set
{
    my ($cl,$name) = @_;
    if (!$cl->have_id())
	{
		return -1;
	}
    if (-e $cl->getfile())
	{
		open(SF,$cl->getfile);
		while (my $l = <SF>)
		{
	    	my @line = split (/=/,$l);
		    if ($line[0] eq $name) { 
			close(SF); 
			return 1;
			}
	    }
		close(SF);
    }
    return 0;
}

sub list
{
    my ($cl) = @_;
    my %h;
    if (!$cl->have_id())
	{
		return -1;
	}
    if (-e $cl->getfile())
    {
	open(SF,$cl->getfile);
	while (my $l = <SF>)
	{
	    my @line = split (/=/,$l);
	    $h{$line[0]}=$line[1];
	}
	close(SF);
	return %h;
    }
    return 0;
}

sub unset
{
    my ($cl,$name) = @_;
    my $content = "";
    if (!$cl->have_id())
	{
		return -1;
	}
    if (!$cl->is_set($name))
	{
		return 0;
	}
    open(SF,$cl->getfile());
    while (my $l = <SF>)
	{ 
    	$l =~ s/^$name=(.*?)\n//i;
    	$content .= $l; 
	}
	close(SF);
    open(SF,">".$cl->getfile());
    print SF $content; 
    close(SF);
}

sub unsetall
{
    my ($cl,$name) = @_;
    my $content = "";
	if (!$cl->have_id())
	{
		return -1;
	}
	if (-e $cl->getfile())
	{
		return 0;
	}
    open(SF,">".$cl->getfile());
	close(SF);
    $cl->check_sessions();
	
    return 1;
}

sub get
{
    my ($cl,$name) = @_;
    $name=~s/(\(|\))/\\$1/;
    if (!$cl->have_id())
	{
		return -1;
	}
	if (-e $cl->getfile())
	{
		open(SF,$cl->getfile());
		while (my $l = <SF>)
		{
	    	if ($l =~ /^$name=(.*?)\n/i)
			{
				close(SF); 
				return $1; 
			}
	    }
		close(SF);
    }
	else
	{ 
    	return -1;
    }
	return "";
}

sub set
{
    my ($cl,$name,$value) = @_;
    if (!$cl->have_id()) { return -1; }
	if (-e $cl->getfile())
	{
		my $content = "";
		my $flag=0;	
		open(SF,$cl->getfile()); 
		while (my $l = <SF>)
		{ 
			$flag=1 if($l =~ s/^$name=(.*?)\n/$name=$value\n/gis);
	    	$content .= $l; 
	    }
		close(SF);
		if(!$flag)
		{
			$content.="$name=$value\n";
		}
		open(SF,">".$cl->getfile());
		print SF $content; 
		close(SF);
		return 1;
    }
    return 0;
}


sub newID
{
    my $cl = shift;
	#GET COOKIE
	my %COOKIES=$cl->parse_COOKIE();
	if($COOKIES{SID} ne "")
	{
		$cl->{SID}=$COOKIES{SID};
	}
#	print "Content-type: text/html\n\n";
#	print "COOKIE: ".$COOKIES{SID}."<br>";
	if(($COOKIES{SID} eq "") || !($cl->check_ip_addr))
	{
		do
		{
	    	my $ary = "0123456789abcdefghijABCDEFGH";	# replace with the set of characters
	    	$cl->{SID} = "";
		    my $arylen = length($ary);
    		for my $i (0 .. 23)
			{
				my $idx = int(rand(time) % $arylen);
				my $dig = substr($ary, $idx, 1);
				$cl->{SID} .= $dig;
		    }
		} 
		while($cl->exists($cl->{SID}));
	}
	return $cl->{SID};
}

sub check_ip_addr
{
	my $cl = shift;
	return 1 if(!defined($cl->{check_ip}));
#	print "Content-type: text/html\n\n";
#	print "SID_IP: ".$cl->get("SID_IP")." IP: ".$ENV{REMOTE_ADDR};
#	print " GETFILE: ".$cl->getfile();
	return 0 if($cl->get("SID_IP") ne $ENV{REMOTE_ADDR});
	return 1
}

sub parse_COOKIE
{
	my @keypairs = split(/;/,$ENV{HTTP_COOKIE});
	my %COOKIE;
    foreach my $keyvalue (@keypairs)
    {
        $keyvalue=~s/^\s+//;
        my ($key,$value) = split(/=/,$keyvalue);
        $key =~ tr/+/ /;
        $key =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $value =~ tr/+/ /;
        $value =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/pack("C",hex($1))/eg;
        $value=~s/\r//g;
        $COOKIE{$key} = $value;
    }
	return(%COOKIE);
}

#############################

1;

__END__

=head1 NAME

ZM::Session - sessions manager for CGI

=head1 VERSION

Session.pm v 0.2.0

=over 4

=item Recent Changes:

=over 4

=item 0.1.0 

Added sessions this user's IP support.

=item 0.0.3 

Added 'nocontent' parametr to method start().

=item 0.0.2 

Changed variable's manipulation methods.

=item 0.0.1 

WOW! It's working!!! :-)

=back

=back

=head1 DESCRIPTION

This module can be used anywhere you need sessions. As a session management module, it uses files with a configurable lifetime to handle your session data. For those of you familiar with PHP, you will notice that the session syntax is a little bit similar. This module storing session ID at users COOKIES.

=head1 METHODS

The following public methods are availible:

=over 4

=item B<$s = new ZB<M>::Session();>

The constructor, this starts the ball rolling. It can take the following hash-style parameters:

=over 4

=item lifetime

how long the session lasts, in seconds.

=item path

the directory where you want to store your session files.

=item id

if you want to give the session a non-random name, use this parameter as well.

=item head

additional headers.

=item check_ip

if you want check user IP address. Create new session if IP was changed.

=back

=item B<$s-E<gt>start();>

This creates a session and set COOKIE or resumes an old one if COOKIE exist and session file alive. This will return '1' if this is a new session, and '0' if it's resuming an old one. If you defined no values in the 'new()' call, then the session will start with a default lifetime of 600 seconds, a path of /tmp, and a random string for an id. This method have one argument - 'nocontent'. This argument allow you print Content-type self.

=item B<$s-E<gt>set_path();>

Set the session path or, without an argument, return the current session path. Used with an argument, this performs the same thing as the 'path' parameter in the constructor.

=item B<$s-E<gt>id();>

If the session id exists, this will return the current session id - useful if you want to maintain state with a cookie! If you pass a parameter, it acts the same as new( id => 'some_session_name'), i.e., it creates a session with that id.

=item B<$s-E<gt>is_set();>

Check to see if the variable is defined. Returns '1' for true, '0' for false.

=item B<$s-E<gt>unset();>

This method allows you to undefine variable.

=item B<$s-E<gt>set();>

This is where you actually define your variables. This method takes two arguments: the first is the name of the variable, and the second is the value of the variable.

=item B<$s-E<gt>get();>

This method allows you to access the data that you have saved in a session - just pass it the name of the variable that you 'set()'.

=item B<$s-E<gt>unsetall();>

Calling this method will wipe all the variables stored in your session.

=item B<$s-E<gt>destroy();>

This method deletes the session file, destroys all the evidence, and skips bail.

=back

=head1 EXAMPLES

=over 4

=item Session creation and destruction

 use strict;
 use ZM::Session;

    my $s = new ZM::Session(lifetime=>10,path=>"/home/user/sessions/",id=>$cgi->param("SID"),check_ip=>"yes");
    $s->start();
    # $s->set_path('/home/user/sessions/');

    $s->set("zm","abc");
    print $s->get("zm"); #should print out "abc"

    if ($s->is_set("zm"))
	{
		print "Is set";
	}
	else
	{
		print "Not set";
	}

    # unset "zm"
    $s->unset("zm");
    print $s->get("zm"); #should print out empty string
    
    $s->unset(); # wipe all variables
    $s->destroy(); # delete session with this ID

=back

=head1 COPYRIGHT

Copyright 2002 Zet Maximum

=head1 AUTHOR

Zet Maximum ltd.
http://www.zmaximum.ru/

=cut
