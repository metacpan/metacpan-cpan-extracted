use 5.008001;
use strict;
use warnings;


use inc::Module::Install 0.91;
use ExtUtils::Depends;

name 'XS-Object-Magic';
all_from 'lib/XS/Object/Magic.pm';

requires_external_cc;

requires 'parent';
configure_requires 'ExtUtils::Depends' => 0.302; #minimum version that works on Win32+gcc
test_requires 'Test::Fatal';
test_requires 'Test::More';
test_requires 'Test::use::ok';
test_requires 'Scalar::Util';

my $pkg = ExtUtils::Depends->new('XS::Object::Magic');
$pkg->install('xs_object_magic.h');
$pkg->add_xs('Magic.xs');
$pkg->add_pm('lib/XS/Object/Magic.pm' => '$(INST_LIB)/XS/Object/Magic.pm');
$pkg->add_typemaps('typemap');

mkdir 'build';
$pkg->save_config('build/IFiles.pm');

makemaker_args(
    $pkg->get_makefile_vars,
    DL_FUNCS => { 'XS::Object::Magic' => [] },
	TYPEMAPS => [qw(typemap test_typemap)],
);

repository 'git://github.com/nothingmuch/xs-object-magic.git';

ppport;

WriteAll;

