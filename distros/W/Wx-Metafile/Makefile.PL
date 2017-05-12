use Wx::build::MakeMaker;
use Wx::build::MakeMaker;
use ExtUtils::MakeMaker qw[ prompt ];

sub findWxwin {
    my @dirs;
    for('c'..'z'){
        my @files = glob $_.':/wxWindows*';
        push @dirs,@files if @files;
    }
    return shift @dirs;
}

$ENV{WXDIR} = $ENV{WXWIN} if $ENV{WXWIN};
$ENV{WXDIR} = $ENV{WXWIN} if $ENV{WXDIR};

unless( $ENV{WXDIR} or $ENV{WXWIN} ) {
    $ENV{WXWIN} = prompt('Where is WXWIN? (aka WXDIR) ', findWxwin() );
    $ENV{WXDIR} = $ENV{WXWIN};
}

$ENV{WXWIN} = $ENV{WXDIR};

print qq[
using:
    WXWIN => $ENV{WXWIN}
    WXDIR => $ENV{WXDIR}



];


wxWriteMakefile( NAME         => 'Wx::Metafile',
                 VERSION_FROM => 'Metafile.pm',
               );