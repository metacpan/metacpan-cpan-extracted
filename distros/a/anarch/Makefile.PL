BEGIN { require 5 }

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'anarch',
    AUTHOR          => 'Father Chrysostomos <sprout at, um, cpan dot org>',
    VERSION_FROM    => 'anarch',
    ABSTRACT_FROM   => 'anarch',
    EXE_FILES       => [ 'anarch' ],
    PREREQ_PM => {
     CSS'DOM                  =>  .03, # constructor interface
     CSS'DOM'Parser           => 0,
     CSS::DOM::Rule           =>  .03, # constructor interface
     Encode                   => 0,
     File::Basename           => 0,
     File::Path               => 0,
     File::Slurp              => 0,
     HTML'DOM                 =>  .025, # text nodes created out of objects
     LWP::UserAgent           => 5.815, # handlers
     URI                      => 0,
     URI'file                 => 0,
     WWW::Scripter            => 0,
     WWW'Scripter'Plugin'Ajax => 0,
# for testing:
     Config              => 0,
     Cwd                 => 0,
     File'Spec           => 0,
     File'Spec'Functions => 0,
     File'Temp           => 0,
     strict              => 0,
     vars                => 0,
    },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'anarch-*' },
);
