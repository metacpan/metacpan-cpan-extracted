#
#
#
package Win32::Process::User;

use 5.006;
use strict;
use warnings;
use Carp;
use Win32::Process::List;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Process::User ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our $VERSION = '0.02';

bootstrap Win32::Process::User $VERSION;

# Preloaded methods go here.

sub new
{
	my $class = shift;
	my $self = { };
	bless $self, $class;
	return $self;
}
sub GetByPID
{
	my $self=shift;
	my $pid=shift;
	my $domain=shift|| $ENV{COMPUTERNAME};
	$self->{error}=undef;
	my $username=_GetUserByPid($pid,$domain,$self->{error});
	if($self->{error}) { return; }
	else {
		return %{$username}; 
	}
}

sub GetByName
{
	my $self=shift;
	$self->{error}=undef;
	my $pr = shift;
	my $USER=Win32::Process::List->new();
	my @pid=$USER->GetProcessPid($pr);
	my %username=$self->GetByPID($pid[0]);
		if($self->{error}) { return; }
	else {
		return %username; 
	}
	
}

sub GetError
{
	my $self=shift;
	return $self->{error};
	
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Win32::Process::User - Perl extension for to get the user and domain name of a process

=head1 SYNOPSIS

  use Win32::Process::User;
  my $USER = Win32::Process::User->new();
  my %h = $USER->GetByPID($ARGV[0]) if $ARGV[0];
  if(!%h) { print "Error: " . $USER->GetError() . "\n"; exit; }
  foreach (keys %h)
  {
	print "$_=" . $h{$_} . "\n";
  }
  %h=$USER->GetByName("hamster.exe");
  if(!%h) { print "Error: " . $USER->GetError() . "\n"; exit; }
  foreach (keys %h)
  {
	print "$_=" . $h{$_} . "\n";
  }


=head1 DESCRIPTION

Win32::Process::User is a module to get the the user and domain name of a running process.

=head1 FUNCTIONS

=over 4

=item new()

The constructor. There are no parameters.


=item GetByPid()

This function takes the process ID of the process you want to get the domain and user name.
It returns a hash on success and undef on failur. Use GetError to get the error message.


=item GetByName()

This function takes the name of the process e.g. explorer.exe and returns also a hash on success
and undef on failur. Use GetError to get the error message.
GetByName uses my module Win32::Process::List to translate the process name to the process ID.
Therefore Win32::Process::List is a pre requiste to use Win32::Process::User.


=item GetError()

returns the error string on if one of the both functions are faild.

=back

=head2 EXPORT

None by default.


=head1 AUTHOR

Reinhard Pagitsch, E<lt>rpirpag@gmx.at<gt>

=head1 SEE ALSO

L<perl> and L<Win32::Process::List>.

=cut
