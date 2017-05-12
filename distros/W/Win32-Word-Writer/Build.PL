use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Win32::Word::Writer',
    license => 'perl',
    requires => {
        'perl'               => '5.6.0',
        'Test::More'         => 0.54,
        'Test::Exception'    => 0.20,
        'Class::MethodMaker' => 1.12,
        'File::Temp'         => 0.14,
        'File::Spec'         => 0.87,
        'Win32::OLE'         => 0.17,
        'Win32::OLE::Const'  => 0,
        'File::Temp'         => 0.14,
        'Data::Dumper'       => 0,
        'Carp'               => 0,
    },
    create_readme => 1,
    create_makefile_pl => 'traditional',            
    add_to_cleanup      => [ 'Win32-Word-Writer-*' ],
);
$build->create_build_script;

__END__
