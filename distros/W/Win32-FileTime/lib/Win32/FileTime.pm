package Win32::FileTime;

use Carp;
use Win32::API;
use Win32API::File qw/ :ALL /;

use strict;
use vars qw/ $VERSION /;

$VERSION = '0.04';


sub Access {
    my ( $self, @args ) = @_;
    return $self->getTime( $self->{'ACCESS'}, @args );
}


sub Create {
    my ( $self, @args ) = @_;
    return $self->getTime( $self->{'CREATE'}, @args );
}


sub Modify {
    my ( $self, @args ) = @_;
    return $self->getTime( $self->{'MODIFY'}, @args );
}


sub getTime {
    my ( $self, $FileTimePointer, @args ) = @_;

    my $LocalTime = pack( 'LL', 0, 0 );
    my $FileTimeToLocalFileTime = Win32::API->new(
        'kernel32',
        'FileTimeToLocalFileTime',
        [ 'P', 'P' ],
        'I'
    );
    $FileTimeToLocalFileTime->Call( $FileTimePointer, $LocalTime );

    my $SystemTime = pack( 'SSSSSSSS', 0, 0, 0, 0, 0, 0, 0, 0 );

    my $FileTimeToSystemTime = Win32::API->new(
        'kernel32',
        'FileTimeToSystemTime',
        [ 'P', 'P' ],
        'I'
    );
    $FileTimeToSystemTime->Call( $LocalTime, $SystemTime );

    my @time = unpack( 'SSSSSSSS', $SystemTime );

    my %filetime = (
        'year'      =>  $time[0],
        'month'     =>  $time[1],
        'wday'      =>  $time[2],
        'day'       =>  $time[3],
        'hour'      =>  $time[4],
        'minute'    =>  $time[5],
        'second'    =>  $time[6],
        'msecond'   =>  $time[7]
    );

    return @time unless scalar @args;

    my @return;
    foreach (@args) {
        defined $filetime{$_} or croak( __PACKAGE__, '->getTime : Unknown time field argument passed to object method' );
        push @return, $filetime{$_};
    }
    return @return;
}


sub new {
    my ( $class, $filename ) = @_;

    my $self = {};
    $self->{'FILENAME'} = $filename;
    $self->{'HFILE'} = CreateFile(
        $self->{'FILENAME'},
        GENERIC_READ(),
        FILE_SHARE_READ(),
        [],
        OPEN_EXISTING(),
        0,
        []
    ) or croak( __PACKAGE__, '->new : Cannot read file - ', $self->{'FILENAME'} );

    my %filetime = (
        'create'    =>  undef,
        'access'    =>  undef,
        'modify'    =>  undef
    );
    $filetime{$_} = pack( "LL", 0, 0 ) for keys %filetime;

    my $GetFileTime = Win32::API->new(
        'kernel32',
        'GetFileTime',
        [ 'N', 'P', 'P', 'P' ],
        'I'
    );
    $GetFileTime->Call(
        $self->{'HFILE'},
        $filetime{'create'},
        $filetime{'access'},
        $filetime{'modify'}
    );
    $self->{ uc $_ } = $filetime{ $_ } for keys %filetime;

    CloseHandle( $self->{'HFILE'} );

    bless $self, $class;
    return $self;
}


1;


__END__

=pod

=head1 NAME

Win32::FileTime - Perl module for accessing Win32 file times

=head1 SYNOPSIS

 use Win32::FileTime;

 my $filename = "foo.txt";
 my $filetime = Win32::FileTime->new( $filename );

 printf( 
     "Accessed : %4d/%02d/%02d %02d:%02d:%02d",
     $filetime->Access( 
         'year', 
         'month', 
         'day', 
         'hour', 
         'minute', 
         'second' 
     )
 );

=head1 DESCRIPTION

This module is designed to provide an easy-to-use interface for obtaining 
creation, access and modification times for files on Win32 systems.

=head1 METHODS

The following methods are available through this module for use with 
B<Win32::FileTime> objects.  No methods can be exported into the calling namespace.

=over 4

=item B<new>

 my $filetime = Win32::FileTime->new( $filename );

This object constructor creates and returns a new B<Win32::FileTime> object.  The 
only mandatory argument to this object constructor is a relative or absolute file 
path.  It is the creation, access and modification times of this file which are 
obtained and returned by this B<Win32::FileTime> object.

=item B<Access( @arguments )>

 my @AccessTime = $filetime->Access( @arguments );

This method returns an array corresponding to the last access time of the file 
specified in the object constructor.

=item B<Create( @arguments )>

 my @CreateTime = $filetime->Create( @arguments );

This method returns an array corresponding to the creation time of the file 
specified in the object constructor.

=item B<Modify( @arguments )>

 my @ModifyTime = $filetime->Modify( @arguments );

This method returns an array corresponding to the modification time of the file 
specified in the object constructor.

=back

The arguments to these methods can be any combination of the following list of time 
field arguments - C<year>, C<month>, C<wday>, C<day>, C<hour>, C<minute>, C<second> 
and C<msecond>.  The passing of any of these time field arguments to 
B<Win32::FileTime> methods returns the respective time field in the order passed to 
the object method.

If no arguments are specified, the entire array of time fields is returned in the 
order defined above.

=head1 VERSION

0.04

=head1 AUTHOR

Frank Bardelli, Rob Casey

=cut
