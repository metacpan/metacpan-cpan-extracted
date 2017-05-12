package VMS::Process;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw(&process_list &suspend_process &release_process
                &kill_process &change_priority &proc_info_names
                &get_all_proc_info_items       &get_one_proc_info_item
                &decode_proc_info_bitmap);
$VERSION = '1.09';

bootstrap VMS::Process $VERSION;

#sub new {
#  my($pkg,$pid) = @_;
#  my $self = { __PID => $pid || $$ };
#  bless $self, $pkg; 
#}

#sub one_info { get_one_proc_info_item($_[0]->{__PID}, $_[1]); }
#sub all_info { get_all_proc_info_items($_[0]->{__PID}) }

#sub TIEHASH { my $obj = new VMS::ProcInfo @_; $obj; }
#sub FETCH   { $_[0]->one_info($_[1]); }
#sub EXISTS  { grep(/$_[1]/, proc_info_names()) }

# Can't STORE, DELETE, or CLEAR--this is readonly. We'll Do The Right Thing
# later, when I know what it is...

#sub FIRSTKEY {
#  $_[0]->{__PROC_INFO_ITERLIST} = [ proc_info_names() ];
#  $_[0]->one_info(shift @{$_[0]->{__PROC_INFO_ITERLIST}});
#}
#sub NEXTKEY { $_[0]->one_info(shift @{$_[0]->{__PROC_INFO_ITERLIST}}); }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

VMS::Process - Manage processes and retrieve process information on OpenVMS systems

=head1 SYNOPSIS

  use VMS::Process;

Routines to manage processes:

  @pid_list = process_list([@process_characteristics]);
  $WorkedOK = suspend_process($pid);
  $WorkedOK = release_process($pid);
  $WorkedOK = kill_process($pid);
  $WorkedOK = change_priority($pid, $priority);
  @char_list = valid_process_chars();

Routine to return a reference to a hash with all the process info for the
process loaded into it:

  $procinfo = VMS::Process::get_all_proc_info_items(pid);
  $diolimit = $procinfo->{DIOLM};

Fetch a single piece of info:

  $diolm = VMS::Process::get_one_proc_info_item(pid, "DIOLM");

Decode a bitmap into a hash filled with names, with their values set to
true or false based on the bitmap.

  $hashref = VMS::Process::decode_proc_info_bitmap("CREPRC_FLAGS", Bitmap);
  $hashref->{BATCH};

Get a list of valid info names:

  @InfoNames = VMS::Process::proc_info_names;

=head1 DESCRIPTION

VMS::Process allows a perl program to get a list of some or all the
processes on one or more nodes in the cluster, change process priority,
suspend, release, or kill them. Normal VMS system security is in effect, so
a program can't see or modify processes that the process doesn't have the
privs to see.

=head2 Narrowing down the PID list from C<process_list()>

process_list uses the VMS $PROCESS_SCAN system service to narrow down the
list of PIDs that it returns. Normally, a full-wildcard scan is done,
returning all the PIDs for all the cluster nodes that your process has
privileges to see. Oftentimes, though, you'll get more PIDS than you really
want.

The process_list function takes an optional reference to a list with the
characteristics of the processes whose pids will be returned. Each element
of the list is a hash struct with required NAME and VALUE elements, and 
optional COMPARISION and MODIFIER elements.

The NAME element is the name of the thing you want to select on. They're
the names of the constants that $PROCESS_SCAN takes, minus the leading
PSCAN$_. A list is available from the C<process_list_names()> function.

Some of the items you can select on, specifically JOBTYPE, MODE, and STATE,
take symbolic values instead of integers. Rather than having to figure out
what the constant SCH$C_MWAIT really is, you can use "MWAIT" instead.

The VALUE element is the value being compared to. It will be used either in
an integer or string context, depending on what NAME is.

The COMPARISON element specifies what sort of comparison should be
made. The choices are C<gt>, C<lt>, C<eq>, C<le>, C<ge>, and C<ne>, for
greater than, less than, equal, less than or equal, greater than or equal,
or not equal.

If the COMPARISON element is not specified, C<eq> is assumed.

The MODIFIER element specifies the special things that affect this list
item. They are C<pre>, C<*>, C<|>, C<&&>, C<||>, and C<I>. C<pre> indicates
the list item is a prefix, and tacks on an implicit trailing C<*>. C<*>
indicates the item has one or more wildcards in it, and VMS should do
wildcard matching. C<|> indicates this entry should be ORd with the I<next>
entry. C<&&> is a bitwise AND, and C<||> is a bitwise OR (valid only for
bitmask items). C<I> makes comparisons case insensitive, and is valid only
for string comparisions.

The standard VMS wildcards are used--C<*> for any characters, and C<%> for
one character. Sorry, no Perl regexps.

=head2 Getting valid NAME names

The function C<process_list_names()> returns a list of all the valid names
that can be used as elements for the C<process_list()> function.

=head1 BUGS

None known.

=head1 LIMITATIONS

The list is built and passed to $PROCESS_SCAN in the order that they're passed
to C<process_list>. This means you must follow the rules and limitations of
$PROCESS_SCAN. The biggest being that OR'd items I<must> be of the same
type. (No ORing NODENAME and USERNAME, for example)

Currently only one modifier may be used for each item.

VMS system security is in force, so process_list() is likely to show fewer
PIDs than SHOW SYSTEM will. Nothing we can do about that, short if
INSALLing Perl with lots of privs, which is a really, really bad idea, so
don't.

No object or tied hash interface just yet.

Quadword values are returned as string values rather than integers.

Privilege info's not returned. Use VMS::Priv for that.

List info (rightslist and exceptions vectors) are not returned.

The bitmap decoder doesn't grok the CURRENT_USERCAP_MASK, MSGMASK, or
PERMANENT_USERCAP_MASK fields, as I don't know where the bitmask defs for
them are in the header files. When I do, support will get added.

=head1 AUTHOR

Dan Sugalski <dan@sidhe.org>

Craig A. Berry <craigberry@mac.com>

=head1 SEE ALSO

perl(1)

=cut
