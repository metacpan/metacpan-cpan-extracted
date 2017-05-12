package VIM::Packager::Utils;
use warnings;
use strict;
use Exporter::Lite;

our @EXPORT = ();
our @EXPORT_OK = qw(vim_inst_record_dir vim_rtp_home findbin);

sub vim_inst_record_dir { File::Spec->join( $ENV{HOME} , '.vim-packager' , 'installed' ) }

sub vim_rtp_home { return File::Spec->join( $ENV{HOME} , '.vim' ) }

sub findbin {
    my $which = shift;
    my $path  = $ENV{PATH};
    my @paths = split /:/, $path;
    for (@paths) {
        my $bin = $_ . '/' . $which;
        return $bin if ( -x $bin );
    }
}



1;
