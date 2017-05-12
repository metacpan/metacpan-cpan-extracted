package inc::TREMakeMaker;
use strict;
use warnings qw(all);
use utf8;

use Config;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_args => sub {
    my @OBJ = map {
        my $tmp = $_;
        $tmp =~ s/\.c$/.o/;
        $tmp;
    } grep {
        !/test/
    } glob 'tre/*.c';

    return +{
        %{ super() },
        OBJECT => join(' ' => @OBJ, 'TRE.o'),
        LIBS => [qw[-lintl]],
    }
};

__PACKAGE__->meta->make_immutable;
