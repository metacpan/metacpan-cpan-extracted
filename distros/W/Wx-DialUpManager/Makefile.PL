#!/usr/bin/perl -w

BEGIN {
    eval {
        require Wx::build::MakeMaker;
    };
    if($@){
        warn "Warning: prerequisite Wx::build::MakeMaker not found.\n";
        warn "Warning: you need to install wxPerl (http://wxPerl.sf.net).\n";
        exit 1;
    }
}

use ExtUtils::MakeMaker qw[ prompt ];
use strict;


print q[

    Set DO_NET_TEST=1 in your ENV if you want to test
    this module and you're connected to the internet.
    (what it will try to do is disconnect you if you're on dialup).

];

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


Wx::build::MakeMaker::wxWriteMakefile(
    NAME         => 'Wx::DialUpManager',
    VERSION_FROM => 'DialUpManager.pm',
    PREREQ_PM    => {
        'Test'  => 0,
        'Test::More' => 0,
    },
);


sub findWxwin {
    my @dirs;
    for('c'..'z'){
        my @files = glob $_.':/wxWindows*';
        push @dirs,@files if @files;
    }
    return shift @dirs;
}

__END__
perl Makefile.PL && nmake realclean && cls && perl Makefile.PL && nmake test
cpan-upload -mailto yo@yo.yo -verbose -user podmaster  Wx-DialUpManager-0.03.tar.gz
