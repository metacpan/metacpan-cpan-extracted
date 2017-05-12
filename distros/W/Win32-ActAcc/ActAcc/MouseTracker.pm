# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) tool: display what's under the mouse

# Usage:  use Win32::ActAcc::MouseTracker;  $ao = aaTrackMouse();

use strict;

package Win32::ActAcc::MouseTracker;

use Win32::ActAcc qw(:EVENTs :ROLEs);
use Data::Dumper;

require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(aaTrackMouse);

sub aaTrackMouse
{
    my $RUN_TIME_SECONDS = shift;
    my $eh = Win32::ActAcc::createEventMonitor(1);
    my $oldMloc;
    my $ao = undef;
    $eh->eventLoop(
		+[+{
			'event'=>EVENT_OBJECT_LOCATIONCHANGE(),
			'role'=>ROLE_SYSTEM_CURSOR(),
			'code'=>sub{
						my $e = shift;
						$ao = $e->getAO();
						my $mloc = describeMouseLocation($e, \$ao);
						if ($mloc ne $oldMloc)
						{
							print "\r$mloc";
							$oldMloc = $mloc;
						}
						undef; # so eventLoop continues
					}
		}], $RUN_TIME_SECONDS);
    return $ao;
}

sub getAncestry
{
    my $ao = shift;
    my @rv;

    my $p = $ao->get_accParent();
    if (defined($p))
    {
	push @rv,getAncestry($p);
    }

    push @rv, $ao;
    return @rv;
}

sub describeAncestors
{
    my $ao = shift;
    my $i = 0;
    return join("\n", map(('  ' x $i++) . $_->describe(1), getAncestry($ao)))."\n";
}

sub describeMouseLocation
{
    my $e = shift;
    my $pAoCursor = shift;
    my $L;
    my $aoCursor = $e->getAO();
    my ($left,$top,$width,$height) = $aoCursor->accLocation();
    $$pAoCursor = Win32::ActAcc::AccessibleObjectFromPoint($left,$top);
    my $rv;
    if (defined($$pAoCursor))
    {
	    $rv = describeAncestors($$pAoCursor); 
    }
    else
    {
	    $rv = "undef\n";
    }
    return $rv;
}

1;
