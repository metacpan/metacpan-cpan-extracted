package VIM::Packager::Record;
use warnings;
use strict;
use File::Spec;
use File::Path;
use YAML;

=head2 get_record_dir

=cut

sub get_record_dir {
     $ENV{VIMPKG_RECORDDIR} || File::Spec->join($ENV{HOME},'.vim','record')
}

sub get_record_file { File::Spec->join( get_record_dir() , $_[0] ) }


=head2 find [package name]

=cut

sub find {
    my $path = get_record_file $_[0];
    return $path if -e $path;
    return undef;
}


sub read {
    my $path = shift;
    my $r =  YAML::LoadFile( $path );
    unless( $r ) {
        die "Error: Can not read record from file : $path\n";
    }
    return $r;
}

sub save {
    my ($pkgname , $meta , $files ) = @_;

    my $record_dir = get_record_dir();
    my $record_path = get_record_file( $pkgname );

    mkdir $record_dir unless -e $record_dir;
    YAML::DumpFile( $record_path , { 
        meta => $meta, 
        files => $files 
    } );
}

1;
