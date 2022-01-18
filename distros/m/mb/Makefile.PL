use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{mb},
    'VERSION'   => q{0.37},
    'ABSTRACT'  => q{run Perl script in MBCS encoding (not only CJK ;-)},
    'PREREQ_PM' => {
        'Cwd' => '0',
        'ExtUtils::MakeMaker' => '5.4302',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'Socket' => '0',
        'lib' => '0',
        'perl' => '5.00503',
        'strict' => '1.01',
        'vars' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org>},
);

__END__
