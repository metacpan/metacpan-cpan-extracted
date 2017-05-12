package Win32::FileSecurity;

use Carp;

$VERSION = '1.09';

require Win32 unless defined &Win32::IsWinNT;
croak "The Win32::FileSecurity module works only on Windows NT" unless Win32::IsWinNT();

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(
	Get
	Set
	EnumerateRights
	MakeMask
	DELETE
	READ_CONTROL
	WRITE_DAC
	WRITE_OWNER
	SYNCHRONIZE
	STANDARD_RIGHTS_REQUIRED
	STANDARD_RIGHTS_READ
	STANDARD_RIGHTS_WRITE
	STANDARD_RIGHTS_EXECUTE
	STANDARD_RIGHTS_ALL
	SPECIFIC_RIGHTS_ALL
	ACCESS_SYSTEM_SECURITY
	MAXIMUM_ALLOWED
	GENERIC_READ
	GENERIC_WRITE
	GENERIC_EXECUTE
	GENERIC_ALL
	F
	FULL
	R
	READ
	C
	CHANGE
	A
	ADD
);

sub AUTOLOAD {
    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    #reset $! to zero to reset any current errors.
    local $! = 0;
    $val = constant($constname);
    if($! != 0) {
	if($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    ($pack,$file,$line) = caller;
	    die "Your vendor has not defined Win32::FileSecurity macro "
	       ."$constname, used in $file at line $line.";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Win32::FileSecurity;

1;

__END__

=head1 NAME

Win32::FileSecurity - Manage FileSecurity Discretionary Access Control Lists in Perl

=head1 SYNOPSIS

    use Win32::FileSecurity;

=head1 DESCRIPTION

This module offers control over the administration of system
FileSecurity DACLs.  You may want to use Get and EnumerateRights to
get an idea of what mask values correspond to what rights as viewed
from File Manager.

=head1 CONSTANTS

  DELETE, READ_CONTROL, WRITE_DAC, WRITE_OWNER,
  SYNCHRONIZE, STANDARD_RIGHTS_REQUIRED,
  STANDARD_RIGHTS_READ, STANDARD_RIGHTS_WRITE,
  STANDARD_RIGHTS_EXECUTE, STANDARD_RIGHTS_ALL,
  SPECIFIC_RIGHTS_ALL, ACCESS_SYSTEM_SECURITY,
  MAXIMUM_ALLOWED, GENERIC_READ, GENERIC_WRITE,
  GENERIC_EXECUTE, GENERIC_ALL, F, FULL, R, READ,
  C, CHANGE

=head1 FUNCTIONS

=over

=item constant( $name, $set )

Stores the value of named constant $name into $set.
Same as C<$set = Win32::FileSecurity::NAME_OF_CONSTANT();>.

=item Get( $filename, \%permisshash )

Gets the DACLs of a file or directory.

=item Set( $filename, \%permisshash )

Sets the DACL for a file or directory.

=item EnumerateRights( $mask, \@rightslist )

Turns the bitmask in $mask into a list of strings in @rightslist.

=item MakeMask( qw( DELETE READ_CONTROL ) )

Takes a list of strings representing constants and returns a bitmasked
integer value.

=back

Note: All of the functions return false if they fail, unless otherwise
noted.  Errors returned via $! containing both Win32 GetLastError()
and a text message indicating Win32 function that failed.

=head2 %permisshash

Entries take the form $permisshash{USERNAME} = $mask ;

Get() may return a SID or the string "<Unknown>" when the account
name cannot be determined.

=head1 EXAMPLE1

    # Gets the rights for all files listed on the command line.
    use Win32::FileSecurity qw(Get EnumerateRights);

    foreach( @ARGV ) {
        next unless -e $_ ;
        if ( Get( $_, \%hash ) ) {
            while( ($name, $mask) = each %hash ) {
                print "$name:\n\t";
                EnumerateRights( $mask, \@happy ) ;
                print join( "\n\t", @happy ), "\n";
            }
        }
        else {
            print( "Error #", int( $! ), ": $!" ) ;
        }
    }

=head1 EXAMPLE2

    # Gets existing DACL and modifies Administrator rights
    use Win32::FileSecurity qw(MakeMask Get Set);

    # These masks show up as Full Control in File Manager
    $file = MakeMask( qw( FULL ) );

    $dir = MakeMask( qw(
        FULL
        GENERIC_ALL
    ) );

    foreach( @ARGV ) {
        s/\\$//;
        next unless -e;
        Get( $_, \%hash ) ;
        $hash{Administrator} = ( -d ) ? $dir : $file ;
        Set( $_, \%hash ) ;
    }

=head1 COMMON MASKS FROM CACLS AND WINFILE

=head2 READ

    MakeMask( qw( FULL ) ); # for files
    MakeMask( qw( READ GENERIC_READ GENERIC_EXECUTE ) ); # for directories

=head2 CHANGE

    MakeMask( qw( CHANGE ) ); # for files
    MakeMask( qw( CHANGE GENERIC_WRITE GENERIC_READ GENERIC_EXECUTE ) ); # for directories

=head2 ADD & READ

    MakeMask( qw( ADD GENERIC_READ GENERIC_EXECUTE ) ); # for directories only!

=head2 FULL

    MakeMask( qw( FULL ) ); # for files
    MakeMask( qw( FULL  GENERIC_ALL ) ); # for directories

=head1 LIMITATIONS

=over

=item *

The module currently only supports ALLOW ACLs; DENY ACLs are not being
reported by Get() and cannot be Set() either.

=item *

The Get() function may return an SID when the account cannot be found,
but the Set() function doesn't allow the use of SIDs for setting ACLs.

=back

=head1 KNOWN ISSUES / BUGS

=over

=item *

May not work on remote drives.

=item *

Errors croak, don't return via $! as documented.

=back

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
