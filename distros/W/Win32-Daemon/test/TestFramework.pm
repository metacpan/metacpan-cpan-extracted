#//////////////////////////////////////////////////////////////////////////////
#//
#//  TestFramework.pm
#//  Test framework package
#//
#//  Copyright (c) 2008 Dave Roth
#//  Courtesy of Roth Consulting
#//  http://www.roth.net/
#//
#//  This file may be copied or modified only under the terms of either 
#//  the Artistic License or the GNU General Public License, which may 
#//  be found in the Perl 5.0 source kit.
#//
#//  2008.03.24  :Date
#//  20080324    :Version
#//////////////////////////////////////////////////////////////////////////////

package TestFramework;

$PACKAGE = $Package = "TestFramework";

$VERSION = 20080321;


@ISA= qw( Exporter DynaLoader );
    # Items to export into callers namespace by default. Note: do not export
    # names by default without a very good reason. Use EXPORT_OK instead.
    # Do not simply export all your public functions/methods/constants.

@EXPORT = qw();
@EXPORT_OK = qw();      


# For a module, you *always* return TRUE...
return( 1 );



sub new
{
    my( $type, @Options ) = @_;
    my $self = bless {};

	my ( $SCRIPT_DIR, $SCRIPT_FILE_NAME ) = ( Win32::GetFullPathName( $0 ) =~ /^(.*)\\([^\\]*)$/ );

	@{$self->{default}->{log_path_list}} = ( "$SCRIPT_DIR\\$SCRIPT_FILE_NAME.log", "\\\\.\\pipe\\syslog" );
	$self->{log_path_list} = ();

    return( $self );
}

sub DESTROY 
{
    my( $self ) = @_;

	$self->LogClose();
	
    undef $self;
    
}

sub _LogConnect
{
	my( $self, $Path ) = @_;
	my $FileHandle;
	if( open( $FileHandle, ">$Path" ) )
	{
	   local *LOG = $FileHandle;
	   my $StartTime = localtime();
	   my $BackupHandle = select( LOG );
	   $| = 1;
	   select( $BackupHandle );
	   push( @{$self->{log_filehandle_list}}, $FileHandle );
	   print LOG << "EOT"
# Service Starting
# Script: $0
# Perl: $^X
# PID: $$
# Date: $StartTime
EOT

	}
}


sub LogClear
{
	my( $self ) = @_;
	
	$self->{log_path_list} = ();
}

sub LogClose
{
	my( $self ) = @_;
	#
	# Close open log files
	#
	foreach $FileHandle ( @{$self->{log_filehandle_list}} )
	{
		local *LOG = $FileHandle;
		if( fileno( LOG ) )
		{
			close( LOG );
		}   
	}
}

sub LogMessage
{
	my( $self, $Message ) = @_;

	foreach my $FileHandle ( @{$self->{log_filehandle_list}} )
	{
		local *LOG = $FileHandle;
		if( fileno( LOG ) )
		{
			print LOG "[" . localtime() . "] $Message\n";
		}   
	}
}   


sub LogAdd
{
	my( $self, @PathList ) = @_;
	
	if( scalar @{$self->{log_filehandle_list}} )
	{
		foreach my $Path ( @PathList )
		{
			$self->_LogConnect( $Path );
		}
	}
	else
	{
		push( @{$self->{log_path_list}}, @PathList );
	}
}

sub LogStart
{
	my( $self ) = @_;
	return if( scalar @{$self->{log_filehandle_list}} );
	
	if( 0 == scalar @{$self->{log_path_list}} )
	{
		push( @{$self->{log_path_list}}, @{$self->{default}->{log_path_list}} );
	}
	
	foreach my $Path ( @{$self->{log_path_list}} )
	{
		$self->_LogConnect( $Path );
	}
}