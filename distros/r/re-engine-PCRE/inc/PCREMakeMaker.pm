package inc::PCREMakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_args => sub { +{
    # Add LIBS => to WriteMakefile() args
    %{ super() },
    LIBS => [ '-lpcre' ],
} };

__PACKAGE__->meta->make_immutable;
