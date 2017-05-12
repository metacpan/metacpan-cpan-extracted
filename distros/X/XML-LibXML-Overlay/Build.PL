use Module::Build;
my $build = Module::Build->new(
    module_name => 'XML::LibXML::Overlay',
    license     => 'perl',
    dist_author => 'Alexander Keusch <kalex@cpan.org>',
    requires     => {
        'XML::LibXML'  => '1.70',
    },
    create_makefile_pl => 'passthrough',
    create_readme => 1,
);
$build->create_build_script;

