#!/usr/bin/perl

use Time::HiRes qw( gettimeofday tv_interval );
use Cwd;

# In the non-installed case, we need to figure out what the library is at
# compile time so that "use lib" doesn't fail. To do this, we enclose the
# calculation of it in a BEGIN block.
BEGIN {
    # this value is set by the installation scripts
    my $was_installed = 0;

    if ($was_installed) {
        # In this case, libdir needs to be set to the directory that the modules
        # were installed to, and confdir needs to be set to the directory that
        # logger.conf et al. were installed in. The installation script
        # replaces the LIBDIR and CONFDIR portions with the actual directories
        $libdir = "XXX_LIBDIR_XXX";
        $dirname = "";
    } else {
        # we need a fully-qualified directory name in case we daemonize so that we
        # can still access scripts or other files specified in configuration files
        # in a relative manner. Also, we need to know the location in reference to
        # the binary so that users can launch the daemon from wherever but specify
        # scripts and whatnot relative to the binary.

        $dirname = dirname($0);

        if (!($dirname =~ /^\//)) {
            $dirname = getcwd . "/" . $dirname;
        }

        $libdir = dirname($0)."/../lib";
    }
}

use lib "$libdir";

use perfSONAR_PS::Client::Echo;

my $uri = shift;
my $eventType = shift;

if (!defined $uri or $uri eq "-h") {
	print "Usage: psping [-h] SERVICE_URI [ECHO_EVENT_TYPE]\n";
	exit(-1);
}

my $echo_client = perfSONAR_PS::Client::Echo->new($uri, $eventType);
if (!defined $echo_client) {
	print "Problem creating echo client for service\n";
	exit(-1);
}

my ($stime, $etime);

$stime = [gettimeofday];

my ($status, $res) = $echo_client->ping();
if ($status != 0) {
	print "Service $uri is down: $res\n";
	exit(-1);
}

$etime = [gettimeofday];

$elapsed = tv_interval($stime, $etime);

print "Service $uri is up\n";
print "-Time to make request: $elapsed\n";
