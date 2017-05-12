package Tie::MLDBM::Lock::File;

use Fcntl qw/ :flock /;
use IO::File;

use strict;
use vars qw/ $VERSION /;

$VERSION = '1.04';


sub lock_exclusive {
    my ( $self ) = @_;

    #   This module stores the file handle of the lock file in the self object 
    #   under the name 'Lock' - If this is the first lock action which is called of 
    #   this module, this file handle will not have been created and as such will 
    #   need to be created and stored before any further action can be taken.

    unless ( exists $self->{'Lock'} ) {

        #   The filename of the lock file can be specified by the 'Lockfile' 
        #   argument which can be passed to the Tie::MLDBM object constructor - 
        #   Alternatively, the name 'Tie-MLDBM-Lock-File.lock' is used.

        my $file = $self->{'Config'}->{'Lockfile'} or 'Tie-MLDBM-Lock-File.lock';

        #   Open lock file and store file handle in the self object

        my $fh = IO::File->new( '+>' . $file ) or
            croak( __PACKAGE__, '->lock_exclusive : Cannot open temporary lock file - ', $! );
        $self->{'Lock'} = $fh;

    }
    
    flock( $self->{'Lock'}, LOCK_EX ) or
        croak( __PACKAGE__, '->lock_exclusive : Cannot acquire exclusive lock on file handle - ', $! );

    return 1;
}


sub lock_shared {
    my ( $self ) = @_;

    #   This module stores the file handle of the lock file in the self object
    #   under the name 'Lock' - If this is the first lock action which is called of
    #   this module, this file handle will not have been created and as such will
    #   need to be created and stored before any further action can be taken.

    unless ( exists $self->{'Lock'} ) {

        #   The filename of the lock file can be specified by the 'Lockfile'
        #   argument which can be passed to the Tie::MLDBM object constructor -
        #   Alternatively, the name 'Tie-MLDBM-Lock-File.lock' is used.

        my $file = $self->{'Config'}->{'Lockfile'} or 'Tie-MLDBM-Lock-File.lock';

        #   Open lock file and store file handle in the self object

        my $fh = IO::File->new( '+>' . $file ) or 
            croak( __PACKAGE__, '->lock_shared : Cannot open temporary lock file - ', $! );
        $self->{'Lock'} = $fh;

    }
    
    flock( $self->{'Lock'}, LOCK_SH ) or
        croak( __PACKAGE__, '->lock_shared : Cannot acquire shared lock on file handle - ', $! );

    return 1;
}


sub unlock { 
    my ( $self ) = @_;

    #   This module stores the file handle of the lock file in the self object
    #   under the name 'Lock' - If this object element does not exist then
    #   presumably no lock file has been created and no action should be taken.

    if ( exists $self->{'Lock'} ) {

        flock( $self->{'Lock'}, LOCK_UN );
        $self->{'Lock'}->close;

        delete $self->{'Lock'};

    }
    $self->{'Lock'} = undef;

    return 1;
}


1;


__END__

=pod

=head1 NAME

Tie::MLDBM::Lock::File - Tie::MLDBM Locking Component Module

=head1 SYNOPSIS

 use Tie::MLDBM;

 tie %hash, 'Tie::MLDBM', {
     'Lock'      =>  'File',
     'Lockfile'  =>  '/tmp/Tie-MLDBM-Lock-File.lock'
 } ... or die $!;

=head1 DESCRIPTION

This module forms a locking component of the Tie::MLDBM framework, employing 
synchronisation through use of the C<flock> function.  This use of C<flock> is 
performed with a temporary lock file which is specified in the Tie::MLDBM 
framework constructor.

The temporary lock file which is used for synchronisation within the Tie::MLDBM 
framework may be specified by the 'Lockfile' element of the hash reference 
which is passed in the framework constructor.  If this configuration argument 
is not specified, the file 'Tie-MLDBM-Lock-File.lock' within the current 
directory is employed.

Note that this module does not unlink created temporary lock files as this 
could interfere with locking and synchronisation of other instances of the 
Tie::MLDBM framework.

=head1 AUTHOR

Rob Casey <robau@cpan.org>

=head1 COPYRIGHT

Copyright 2002 Rob Casey, robau@cpan.org

=head1 SEE ALSO

L<Tie::MLDBM>, L<Fcntl>

=cut
