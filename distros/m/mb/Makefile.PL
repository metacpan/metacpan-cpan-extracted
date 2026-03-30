use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{mb},
    'VERSION'   => q{0.59},
    'ABSTRACT'  => q{Can easy script in Big5, Big5-HKSCS, GBK, Sjis(also CP932), UHC, UTF-8, ...},
    'PREREQ_PM' => {
        'Cwd' => '0',
        'ExtUtils::MakeMaker' => '5.4302',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'File::Spec' => '0',
        'FindBin' => '1.42',
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
