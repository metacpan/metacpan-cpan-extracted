use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{Windows1250},
    'VERSION'   => q{1.23},
    'ABSTRACT'  => q{Source code filter to escape Windows-1250 script},
    'PREREQ_PM' => {
        'ExtUtils::MakeMaker' => '5.4302',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'Socket' => '0',
        'bytes' => '0',
        'perl' => '5.005_03',
        'strict' => '1.01',
        'utf8' => '0',
        'vars' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org>},
);

__END__
