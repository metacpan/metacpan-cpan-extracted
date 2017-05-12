package inc::BuildUpskirt;
use Moose;
use strict;
use warnings;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';
    
    override _build_WriteMakefile_args => sub { +{
        # Add LIBS => to WriteMakefile() args
        %{ super() },
        OBJECT => 'html.o markdown.o buffer.o autolink.o array.o html_smartypants.o $(BASEEXT)$(OBJ_EXT)',
    } };

1;
