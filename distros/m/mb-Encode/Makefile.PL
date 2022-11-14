use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{mb::Encode},
    'VERSION'   => q{0.04},
    'ABSTRACT'  => q{provides MBCS encoder and decoder},
    'PREREQ_PM' => {
        'Encode' => '0',
        'ExtUtils::MakeMaker' => '5.4302',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'Jacode' => '0',
        'Socket' => '0',
        'lib' => '0',
        'perl' => '5.00503',
        'strict' => '1.01',
        'vars' => '0',
        'warnings' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org>},
);

__END__
