
my $os = $^O;

############# Global Variables ##############
my $cwd;
chomp( my $hostname = `hostname`);
if ( defined $ENV{PMID} ) {
        $hostname = $ENV{PMID};
}

if ( $os eq 'MSWin32' ) {
	eval "use Win32";
	$cwd = Win32::GetCwd();
	$cwd = Win32::GetShortPathName( $cwd );
	$hostname = uc($hostname);
}
else
{
	chomp ( $cwd = `pwd` );
}

my $tuxconfig = $cwd . "\/TUXCONFIG";

################################################

# search array of integers a for given integer x
# return index where found or -1 if not found
sub bsearch {
    my ($x, @a) = @_;         # search for x in array a
    my ($l, $u) = (0, $#a);   # lower, upper end of search interval
    my $i;                    # index of probe
    while ($l <= $u) {
	$i = int(($l + $u)/2);
	#print $i, "\n";
	if ($a[$i] < $x) {
	    $l = $i+1;
	}
	elsif ($a[$i] > $x) {
	    $u = $i-1;
	} 
	else {
	    return $i; # found
	}
    }
    return -1;         # not found
}


sub get_ipckey()
{
	if ( $os eq 'MSWin32' ) {
		return 0xbea0;
	}
	
    ##############################################################
    # create an array of all the currently used ipckeys
    ##############################################################
    my @used_ipckeys;

    # create the array of used_ipckeys
    my $cmd = "ipcs -a | sed 's/^[smq]/& /g' | awk '{print \$2}'";
    open( P, $cmd . "|" );
    while ( <P> ) {
        # add each value to the array as a scalar (hence the '+ 0').
        $used_ipckeys[++$#used_ipckeys] = ($_ + 0);
    }
    close( P );
    #my $rc = ($? >> 8);
    #print "rc = $rc\n";

    # sort the array in numeric ascending order so we can use
    # bsearch to search the array
    @used_ipckeys = sort { $a <=> $b } ( @used_ipckeys );
    #print "@used_ipckeys" . "\n";

    ##############################################################
    # select the first available ipckey that is not currently used
    ##############################################################
    my $ipckey;
    for ( $ipckey = 32769; $ipckey < 262143; $ipckey++ )
    {
        #print "Checking ipckey $ipckey...\n";
        if ( bsearch( $ipckey, @used_ipckeys ) == -1 ) {
            last;
        }
    }

    return "$ipckey";
}

sub get_tuxconfig()
{
    return $tuxconfig;
}

sub get_wsnaddr()
{
    my $wsnaddr = "//" . $hostname . ":10000";
    return $wsnaddr;
}

sub gen_ubbconfig()
{
    my $ipckey = get_ipckey();

    # open the template file
    my $templateFile = "ubbconfig.template";
    open( TEMPLATE, $templateFile ) || 
        die ( "Can't open $templateFile $!\n" );

    # open the ubbconfig file for writing
    my $ubbconfig = "ubbconfig";
    open( UBBCONFIG, ">$ubbconfig" ) ||
        die ( "Can't open $ubbconfig: $!\n" );

    chomp( my $pwd = $cwd );

    while ( <TEMPLATE> )
    {
        s/<IPCKEY>/
            $ipckey;
        /eg;

        s/<HOSTNAME>/
            $hostname;
        /eg;

        s/<TUXDIR>/
            $ENV{TUXDIR};
        /eg;

        s/<APPDIR>/
            $pwd;
        /eg;

        s/<TUXCONFIG>/
            get_tuxconfig();
        /eg;

        s/<WSNADDR>/
            get_wsnaddr() . "";
        /eg;

        printf UBBCONFIG $_;
    }

    close( TEMPLATE );
    close( UBBCONFIG );
}

####################################################################
# MAIN CODE
####################################################################
#gen_ubbconfig();

#if ( $os eq 'MSWin32' ) {
#		print `type ubbconfig`;
#}
#else {
#	print `cat ubbconfig`;
#}

#$ENV{TUXCONFIG} = get_tuxconfig();
#system( "tmshutdown -y" );
#system( "tmloadcf -y ubbconfig" );
#system( "tmboot -y" );
1;
