use Module::Build;

Module::Build->new(
    module_name     => "Test::Exports",
    license         => "bsd",
    requires        => {
        "Test::Builder"     => 0,
        "B"                 => 0,
        "parent"            => 0,
    },
    build_requires  => {
        "Test::Tester"      => "0.08",
        "Test::More"        => "0.65",
        "Test::Most"        => "0.23",
    },
    meta_merge => {
        resources => {
            repository  => "http://github.com/mauzo/Test-Exports",
            bugtracker  => "https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Exports",
        },
    },
)->create_build_script;
