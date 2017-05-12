#!/usr/bin/perl

use warnings;
use strict;
use Getopt::Long; 
use Twitter::Daily;
use Net::Twitter;
use DateTime;

### Default settings
my %debug;         ## debug vector
my $debugAll = 0;
my %validDebug = ( 'setDebugFlags' => 1,
                   'run'           => 1 );
my $debugList;

### internal settings and structure
### Non Plus Ultra !!

my $NAME = "Twitter Daily News";
my $VERSION = "0.1.2";
my $AUTHOR = "Victor A. Rodriguez (Bit-Man)";
my $CONTACT = 'http://www.bit-man.com.ar';
my $SCREENWIDTH = 69;

use constant INFO => 0;
use constant HELP => 1;
use constant RUN => 2;
my $cmdSub = [ \&printInfo, \&printHelp, \&run];
my $cmd = [ 0, 0, 1 ];    ## 0: disabled, 1: enabled
my $errStr;    ## Extended error string

my $twUser;			## Twitter password
my $twPass;			## Twitter user
my $user;		     ## user for Blog access
my $pass;		## FTP password
my $host;        ## FTP host
my $blCategory;		## Blosxom category
my $date;			## Twitter timeline date to publish
my $verbose = 0;
my $title;
my $blogType;       ## Blog type

#############  setDebugFlags  ################################################
## sets accordingly the debug vector @debug 
sub setDebugFlags($$) {
    my ($debugList, $debugAll) = @_;
    my @list;
    
    return if ( ! $debugList && ! $debugAll);

    if ($debugAll) { 
        @list = keys %validDebug;
    } else {
        @list = split (/,/, $debugList);
    };
    
    foreach my $thisDebug (@list) {
        dieSoft( "Debugging element '$thisDebug' isn't a valid one\n", 1)
            if ( ! $debugAll && ! $validDebug{ $thisDebug } );
        $debug{ $thisDebug } = 1;
    };

};

#############  ProcessArgs  ##################################################
sub ProcessArgs(){
    
    ## no_pass_through: stops command processing if unknown options are present
    Getopt::Long::Configure( qw(no_pass_through) );  
    GetOptions( 'tuser=s' => \$twUser,
                'tpass=s' => \$twPass,
                'user=s' => \$user,
                'pass=s' => \$pass,
                'host=s' => \$host,
                'category=s' => \$blCategory,
                'title=s' => \$title,
                'date=s' => \$date,
                'verbose' => \$verbose,
                'debugAll' => \$debugAll,
                'debug=s' => \$debugList,
                'blog=s' => \$blogType,
                'help' => \($cmd->[1]),
                'info' => \($cmd->[0]) )
       || dieSoft("Unknown arguments were passed", 1);
    
    setDebugFlags( $debugList, $debugAll );
    $cmd->[HELP] = ( ! $twUser || ! $twPass || ! $user || ! $pass  || 
                  ! $host || ! $date || ! $blogType );
    $cmd->[RUN] = ! $cmd->[INFO] &&  ! $cmd->[HELP];

    parseDate() if $cmd->[RUN];
    
    ## The options are loaded and the command processing can begin ...
    ## in case no commands are needed, just leave $cmdSub and $cmd empty

    my ($i, $cmdExec) = (0, 0);
    foreach (@$cmdSub) {
        if ($cmd->[$i++]) {
		    PrintSeparator2();
		    &$_();
            $cmdExec++;
        };
    }
    
    if (! $cmdExec) {
        PrintSeparator2();
        printHelp();
    };
};

#############  Born to run !!  ################################################
sub run() {
	print "Connecting to Twitter and your Blog ...\n";
    
	my $twitter = Net::Twitter->new( username => $twUser, 
                                     password => $twPass ) 
                 || dieSoft("Not all options were passed",1); 
    
    my ($blog,$entry);
    
    $blogType =~ /blosxom/ && do {
    	use Blosxom::Entry::Twitter;
        use Blosxom::Publish;

        $blog = Blosxom::Publish->new( server => $host,
                                      category => $blCategory,
                                      )
                 || dieSoft("Not all options were passed",1);
        
        $blog->login( user => $user, password => $pass );
    
        $entry =  Blosxom::Entry::Twitter->new()
             || dieSoft("Not all options were passed",1);
    
    };
    
    $blogType =~ /blogger/ && do {
        dieSoft("Sorry, Blogger interface not implemented yet. Stay Tuned !!!", 1);
    };
    
	my $daily =  Twitter::Daily->new( 'TWuser' => $twUser,                                                                               
                     'twitter' => $twitter,
                     'blog' => $blog,
                     'entry' => $entry,
                     'verbose' => $verbose ) || dieSoft("Not all options were passed",1);

	## TODO take a look at Twitter date format and how it can a date be set to represent
	##      any date and posibly something more verbose like 'today', 'yesterday', etc.
	

	print "Posting news ...\n";
	$daily->postNews($date,$title) || do {
		my $error =  $daily->errMsg();
		$daily->close(); 
		dieSoft( $error, 1); 
	};
	
	$daily->close();
	print "done.\n";
};

#############  Separators  ####################################################
sub PrintSeparator(){
	print '=' x $SCREENWIDTH . "\n";
}

sub PrintSeparator2(){
	print '-' x $SCREENWIDTH . "\n";
}

sub execFile($) {
	my $path = shift;
	
	## TODO path separator is unixish 
	$path =~ m/.*\/(.*)$/;
	return $1;
}

#############  printHelp  #####################################################
sub printHelp(){
	my $prg = execFile($0);
	print <<EOT
    
    usage:
    $prg  --tuser=user --tpass=password --host=myhost.mydomain
        --user=user --pass=password --date="YYYY-MM-DD" --blog
        [--category=/twitter] 
    	[{--debug | --deubgAll}] [--help] [--info]

    --tuser:	  Twitter user
    --tpass:	  Twitter password
    
    --user:	      FTP user to access Blosxom site
    --pass:	      FTP password to access Blosxom site
    --host:   Host were Blosxom is hosted
    --category:   Blosxom category to store the Twitter news of the day
    
    --date:       Narrows the returned results to just those statuses 
                  created after the specified date (formatted as YYYY-MM-DD)
    --blog:       Blog type (blosxom/blogger)
    --help:       This help screen
    --info:       Author and version info
    
    WARNING: the debug flags are not implemented yet
             Feel free to so so :-D
    --debug:      comma separated value of subs to debug
    --debugAll:   debug all subs

EOT
}	
	
#############  PrintHeader  ###################################################
sub PrintHeader(){
	PrintSeparator();
    printInfo();
};

sub printInfo() {
    print "$NAME - v$VERSION\n" .
          "$AUTHOR\n" .
          "Contact: $CONTACT\n"; 
}

sub dieSoft($$) {
    my $msg = shift;
    my $die = shift;

    my $dieMsg = "error !!!!!\n    $msg\n";
    $dieMsg .= "    $errStr\n"    if $errStr;
    $dieMsg .= "OS Error: $!\n\n"  if $!;
    die "\n\nFatal $dieMsg" if $die;
    print $dieMsg;
}


sub parseDate() {
    my($year,$month,$date) = split /-/, $date;

    $date = new DateTime(
        year  => $year,
        month => $month,
        day   => $date,
    );

    dieSoft( "Wrong date", 1 ) if ( !$date );
}

# main
##############################################################################


PrintHeader();
ProcessArgs();
PrintSeparator2();
exit;


