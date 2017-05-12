package Win32::Net::Session;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Net::Session ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    local $! = 0;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Win32::Net::Session macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Win32::Net::Session $VERSION;

# Preloaded methods go here.

sub new
{
	my $class = shift;
	if(!@_) { die "parameter required!\n"; }
	my $self = {
		servername=>shift, 
		level=>shift,
		clientname=>shift || "", 
		username=>shift || "",
		isError=>0,
		readed=>0,
		Error=>undef
		};
	bless $self, $class;
	
	return $self;

}

sub GetSessionInfo
{
	my $self = shift;
	my $error = "";
	my $argc = 0;
	my %hs;
	if(length($self->{servername}) == 0) { $self->{servername} = "NULL"; }
	if(length($self->{clientname}) == 0) { $self->{clientname} = "NULL"; }
	if(length($self->{username}) == 0)   { $self->{username} = "NULL" }
	my $ret = GetSessionInfos($self->{servername}, $self->{clientname}, $self->{username}, $self->{level}, $self->{readed}, $error);
	return $ret;
	
	
}

sub NumberofSessions
{
	my $self = shift;
	return $self->{readed};
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Win32::Net::Session - Perl extension for getting informations about connected clients to a server or workstation.

=head1 SYNOPSIS

  use Win32::Net::Session;
  my $SESS = Win32::Net::Session->new($server, $level, [$clientname, $username]);
  my $ret = $SESS->GetSessionInfo();
  my $numsessions = $SESS->NumberofSessions();
  if($numsessions == 0) {print "No Clients connected\n"; exit; }
  print "Number of Sessions: " . $numsessions . "\n";
  my %hash = %$ret;
  my $key;
  my $count=0;
  
  while($count < $numsessions)
  {
	my %h = %{$hash{$count}};
	print "The key: $count\n";
	foreach $key (keys %h)
	{
		print "$key=" . $h{$key} . "\n";
	}
	print "\n";
	$count++;
  }


=head1 DESCRIPTION

   With Win32::Net::Session you can list informations about conected clients on a Windows server.
   Depending on the level you pass to the function you will get more or less informations.
   Valid levels are: 0,1,2,3 and 4.
   
   The module uses the Win32 API function NetSessionEnum() to retrive the informations.
   
   Lets talk a little bit more about the \"level\":
   At first a restriction: The levels 1,2 and 4 can only be used with an administrator account.
   
   Level 0: Return the name of the computer that established the session.
   (structure: SESSION_INFO_0)
   Level 1: Return the name of the computer, name of the user, and open files, pipes, and devices on the computer.
   (structure: SESSION_INFO_1)
   Level 2: In addition to the information indicated for level 1, return the type of client and how the user established the session.
   (structure: SESSION_INFO_2)
   Level 3: Return the name of the computer, name of the user, and active and idle times for the session.
   (structure: SESSION_INFO_10)
   Level 4: Return the name of the computer; name of the user; open files, pipes, and devices on the computer; and the name of the transport the client is using.
   (structure: SESSION_INFO_502)

=head1 FUNCTIONS

=over 4

=item new(server, level, [clientname, username])

   The initialation of the module.
   The parameters server and level are mandatory. Clientname and username can be used if you want to get
   informations about a specific client and user.

=item GetSessionInfo()

  Returns a reference to a hash of hash references.
  Please see the example above how to deal with. 

=item NumberofSessions()

  Returns the number of session established on a server or 0 if there are no conections.

=back


=head1 AUTHOR

Reinhard Pagitsch<lt>rpirpag@gmx.atE<gt>

=head1 SEE ALSO

L<perl>.

=cut
