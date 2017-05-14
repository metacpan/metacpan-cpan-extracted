use strict;
use warnings;
#use ExtUtils::MakeMaker;
use inc::Module::Install;

name 'Weaving-Tablet';
all_from 'lib/Weaving/Tablet.pm';

requires 'Tk' => 0;
requires 'Tk::FontDialog' => 0;
requires 'Data::Dumper' => 0;
requires 'Moose' => 0;
requires 'namespace::autoclean' => 0;
test_requires 'Test::More' => 0;

install_script 'snartemo.pl';

WriteAll;

__END__

WriteMakefile(
    NAME                => 'Weaving::Tablet',
    AUTHOR              => 'Michael Houghton <herveus@cpan.org>',
    VERSION             => '0.009.005',
    ABSTRACT_FROM       => 'lib/Weaving/Tablet.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Tk'	=> 0,
        'Tk::HList' => 0,
        'Tk::FileSelect' => 0,
        'Tk::FontDialog' => 0,
        'Tk::ColorEditor' => 0,
        'Data::Dumper' => 0,
        'Moose' => 0,
        'namespace::autoclean' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Weaving-Tablet-*' },
);
