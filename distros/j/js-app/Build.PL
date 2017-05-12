
use App::Build;

my $build = App::Build->new (
    dist_name         => "js-app",
    dist_version      => "0.13",
    dist_author       => "spadkins\@gmail.com",
    dist_abstract     => "A framework for building dynamic widgets or full applications in Javascript",
    license           => "lgpl",
    requires => {
        "App::Options"   => 0,  # needed for option parsing
    },
    build_requires => {
        "App::Build"     => 0,  # needed for installing the software
        "Module::Build"  => 0,  # needed for installing the software
        "File::Spec"     => 0,  # platform-neutral directory processing
    },
    extra_dirs => [ "cgi-bin", "htdocs", ],
    #recommends => {
    #    "JavaScript"     => 0,  # interface to Mozilla's libjs.a (for regression testing)
    #    "Gtk2::MozEmbed" => 0,  # embed Mozilla's Gecko engine (testing?)
    #    "Mozilla::DOM"   => 0,  # (testing?)
    #},
    #auto_features => {
    #    javascript_installed => {
    #        description => "Interface with libjs.a, Mozilla's JavaScript interpreter",
    #        requires => { JavaScript => 0 },
    #    },
    #},
    dynamic_config => 1,
);

$build->create_build_script;

