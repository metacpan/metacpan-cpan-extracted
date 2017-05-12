
# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Ping;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

use ZOOM::IRSpy::Utils qw(isodate);

use Text::Iconv;
my $conv = new Text::Iconv("LATIN1", "UTF-8");


sub start {
    my $class = shift();
    my($conn) = @_;

    my %options = ();
    my $xc = $conn->record()->xpath_context();
    my $user = $xc->find("e:serverInfo/e:authentication/e:user");
    my $password = $xc->find("e:serverInfo/e:authentication/e:password");
    $options{"*user"} = $user if $user;
    $options{"*password"} = $password if $password;

    $conn->irspy_connect(undef, \%options,
			 ZOOM::Event::ZEND, \&connected,
			 exception => \&not_connected);
}


sub connected {
    my($conn, $__UNUSED_task, $__UNUSED_udata, $__UNUSED_event) = @_;

    $conn->log("irspy_test", "connected");
    $conn->record()->store_result("probe", ok => 1);

    foreach my $opt (qw(search present delSet resourceReport
			triggerResourceCtrl resourceCtrl
			accessCtrl scan sort extendedServices
			level_1Segmentation level_2Segmentation
			concurrentOperations namedResultSets
			encapsulation resultCount negotiationModel
			duplicationDetection queryType104
			pQESCorrection stringSchema)) {
	#print STDERR "\$conn->option('init_opt_$opt') = '", $conn->option("init_opt_$opt"), "'\n";
	$conn->record()->store_result('init_opt', option => $opt)
	    if $conn->option("init_opt_$opt");
    }

    foreach my $opt (qw(serverImplementationId
			serverImplementationName
			serverImplementationVersion)) {
	my $val = $conn->option($opt);
	next if !defined $val; # not defined for SRU, for example

	# There doesn't seem to be a reliable way to tell what
	# character set the server uses for these.  At least one
	# server (z3950.bcl.jcyl.es:210/AbsysCCFL) returns an ISO
	# 8859-1 string containing an o-acute, which breaks the XML
	# parser if we just insert it naively.  It seems reasonable,
	# though, to guess that the great majority of servers will use
	# ASCII, Latin-1 or Unicode.  The first of these is a subset
	# of the second, so that brings it to down to two.  The
	# strategy is simply this: assume it's ASCII-Latin-1, and try
	# to convert to UTF-8.  If that conversion works, fine; if
	# not, assume it's because the string was already UTF-8, so
	# use it as is.
	Text::Iconv->raise_error(1);
	my $maybe;
	eval {
	    $maybe = $conv->convert($val);
	}; if (!$@ && $maybe ne $val) {
	    $conn->log("irspy", "converted '$val' from Latin-1 to UTF-8");
	    $val = $maybe;
	}
	$conn->record()->store_result($opt, value => $val);
    }

    return ZOOM::IRSpy::Status::TEST_GOOD;
}


sub not_connected {
    my($conn, $__UNUSED_task, $__UNUSED_udata, $exception) = @_;

    $conn->log("irspy", "not connected: $exception");
    $conn->record()->store_result("probe",
				  ok => 0,
				  errcode => $exception->code(),
				  errmsg => $exception->message(),
				  addinfo => $exception->addinfo(),
				  diagset => $exception->diagset());

    return ZOOM::IRSpy::Status::TEST_BAD;
}


1;
