package MyMakeMaker;

use strict;
use Exporter; *import =\&Exporter::import;

our @EXPORT = qw(wxWriteMakefile);

eval { require Wx::build::MakeMaker };
my $has_wx = $@ ? 0 : 1;
if( !$has_wx ) {
    require ExtUtils::MakeMaker;

    ExtUtils::MakeMaker->import;
    *wxWriteMakefile = sub {
        my( %args ) = @_;

        unless( $has_wx ) {
            $args{depend} = { '$(FIRST_MAKEFILE)' => 'you_better_rebuild_me' };
            delete $args{$_} foreach grep /WX_|_WX/, keys %args;
        }

        WriteMakefile( %args );

        if( !$has_wx ) {
            sleep 3;
            open my $fh, ">> you_better_rebuild_me";
            print $fh "touched";
        }
    };
} else {
    Wx::build::MakeMaker->import;
}

1;
