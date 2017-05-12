



# taken from the Perl Cookbook recipe 7.21 (netlock)
#
# try: LockFile::Simple
# http://search.cpan.org/~ram/LockFile-Simple-0.2.5/Simple.pm


package Uplug::Web::Process::Lock;
# module to provide very basic filename-level
# locks.  No fancy systems calls.  In theory,
# directory info is sync'd over NFS.  Not
# stress tested.

use strict;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA      = qw(Exporter);
@EXPORT   = qw(nflock nunflock);

use vars qw($Debug $Check $MaxLockTime);
$Debug  ||= 0;  # may be predefined
$Check  ||= 5;  # may be predefined

$MaxLockTime ||= 10;   # lock files max 10 seconds! (remove older lockfiles!)

use Cwd;
use Fcntl;
use Sys::Hostname;
use File::Basename;
use File::stat;
use Carp;

my %Locked_Files = ();

# usage: nflock(FILE; NAPTILL)
sub nflock($;$) {
    my $pathname = shift;
    my $naptime  = shift || 0;
    my $lockname = name2lock($pathname);
    my $whosegot = "$lockname/owner";
    my $start    = time();
    my $missed   = 0;
    local *OWNER;

    # if locking what I've already locked, return
    if ($Locked_Files{$pathname}) {
        carp "$pathname already locked";
        return 1
    }

    if (!-w dirname($pathname)) {
#        croak "can't write to directory of $pathname";
	#
	# joerg 040913:
	# I should give up and return 0 but for the sake of UplugWeb
	# and its write-permissions we simply go on instead of failing
	return 1;
    }

    while (1) {
        last if mkdir($lockname, 0777);
        confess "can't get $lockname: $!" if $missed++ > 10
                        && !-d $lockname;
        if ($Debug) {{
            open(OWNER, "< $whosegot") || last; # exit "if"!
            my $lockee = <OWNER>;
            chomp($lockee);
            printf STDERR "%s $0\[$$]: lock on %s held by %s\n",
                scalar(localtime), $pathname, $lockee;
            close OWNER;
        }}

	#### added by joerg@stp.ling.uu.se: check time stamp
	####                                remove files if too old
	####                                (time-mtime>maxlocktime)
	&RemoveOldLockFiles($whosegot,$MaxLockTime);
	&RemoveOldLockFiles($lockname,$MaxLockTime);
	####
	####

        sleep $Check;
        return if $naptime && time > $start+$naptime;
    }
    sysopen(OWNER, $whosegot, O_WRONLY|O_CREAT|O_EXCL)
                            or croak "can't create $whosegot: $!";
    printf OWNER "$0\[$$] on %s since %s\n",
            hostname(), scalar(localtime);
    close(OWNER)                
        or croak "close $whosegot: $!";
    $Locked_Files{$pathname}++;
    return 1;
}

# free the locked file
sub nunflock($) {
    my $pathname = shift;
    my $dir      = dirname($pathname);
    my $lockname = name2lock($pathname);
    my $whosegot = "$lockname/owner";
    unlink($whosegot) if -e $whosegot;
    carp "releasing lock on $lockname" if $Debug;
    delete $Locked_Files{$pathname};
    return rmdir($lockname);
#    my $ret = rmdir($lockname);
#    rmdir("$dir/.lockdir");
#    return $ret;
}

# helper function
sub name2lock($) {
    my $pathname = shift;
    my $dir  = dirname($pathname);
    my $file = basename($pathname);
    $dir = getcwd() if $dir eq '.';
    my $lockname = "$dir/$file.LOCKDIR";     # original version
#    if (not -d "$dir/.lockdir"){
#	mkdir ("$dir/.lockdir",0775);
#	system ("chmod g+w $dir/.lockdir");
#    }
#    my $lockname = "$dir/.lockdir/$file";
    return $lockname;
}

sub RemoveOldLockFiles{
    my $file=shift;
    my $maxtime=shift;
    if (not -e $file){return 1;}
    my $filestat=stat($file);
    if ((time-$filestat->mtime)>$maxtime){
        if (-d $file){return rmdir($file);}
        return unlink($file);
    }
}

# anything forgotten?
END {
    for my $pathname (keys %Locked_Files) {
	my $dir      = dirname($pathname);
        my $lockname = name2lock($pathname);
        my $whosegot = "$lockname/owner";
        carp "releasing forgotten $lockname";
        unlink($whosegot);
	return rmdir($lockname);
#	my $ret = rmdir($lockname);
#	rmdir("$dir/.lockdir");
#	return $ret;
    }
}

1;
