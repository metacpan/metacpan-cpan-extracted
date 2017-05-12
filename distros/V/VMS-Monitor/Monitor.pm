package VMS::Monitor;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.07';


bootstrap VMS::Monitor $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

VMS::Monitor - Access system performace information on OpenVMS systems

=head1 SYNOPSIS

  use VMS::Monitor;
  $hashref = VMS::Monitor::all_monitor_info();
  $one_piece = VMS::Monitor::one_monitor_piece($Thing_to_get);
  @InfoNames = VMS::Monitor::monitor_info_names(); (Well, not yet)

=head1 DESCRIPTION

Retrieve performace info via the $GETSPI system call. 

=head1 RANDOM THINGS

Important stuff that I might otherwise forget (yes, it is sort of stream of
consciousness documentation. Be afraid, be I<very> afraid...):

=item Almost everything's an integer

unless otherwise noted, all the return values are integers

=item Most of this stuff is a count!

Most of the data returned is a count, rather than a delta value. So, for
example, when you retrieve the FAULTS item, it's the total number of faults
since reboot. If you want to do any sort of monitoring, you'll need to take
multiple samples and do the math yourself.

=item SCS returns a reference to an array of hashrefs

Each entry in the array represents a single cluster member (including HSJs
and other cluster storage). The entry is a reference to a hash, which has a
bunch of key/value pairs. (Whod've though?) Currently the keys are
C<DGDISCARD> C<DGRCVD> C<KBYTMAPD> C<KBYTREQD> C<KBYTSENT> C<MSGRCVD>
C<MSGSENT> C<NODENAME> C<QBDT_CNT> C<QCR_CNT> C<REQDATS> C<SNDDATS>, and
pretty much correspond to the names MONITOR uses.

note that at some point this might change from returning an arrayref to
returning the actual array, but I don't know when. (Or if, really) I'm up
for suggestions.

=item DISKS returns a reference to an array of hashrefs

Like the SCS class, DISKS returns a reference to an array of hashrefs, one
ref per disk. Each of those hashes has the keys C<NODENAME>, C<VOLNAME>,
C<DEVNAME>, C<ALLOCLASS>, C<FLAGS>, C<OPTCNT>, C<QCOUNT>, and C<UNITNUM>,
which correspond to the data that MONITOR returns.

Note that C<VOLNAME> has trailing blanks for some reason. (No, I don't know
why. Probably backwards compatibility or something like that) They may get
stripped off at some point before this goes final, though.

=head1 AUTHOR

Dan Sugalski <dan@sidhe.org>
Maintained by Craig A. Berry <craigberry@mac.com>

=head1 SEE ALSO

perl(1), I<OpenVMS System Management Utilities Reference Manual: M-Z,
Appendix A>

=cut
