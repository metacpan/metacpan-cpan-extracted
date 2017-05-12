use strict;
BEGIN {
    my @plugins = (
        "Repository",
        "XSUtil" => {
            cc_warnings => 1,
            ppport      => "lib/Text/ppport.h",
            xshelper    => "lib/Text/xshelper.h",
        }
    );

    if (! -f "README.mkdn") {
        push @plugins, "ReadmeMarkdownFromPod";
    }
    require Module::Build::Pluggable;
    Module::Build::Pluggable->import(@plugins);
}

my $builder = Module::Build::Pluggable->new(
    module_name         => 'Text::QueryString',
    license             => 'artistic_2',
    configure_requires  => {
        'Module::Build'                     => '0.40',
        'Module::Build::Pluggable'          => '0.05',
        'Module::Build::Pluggable::XSUtil'  => '1.00',
    },
    create_makefile_pl  => 'small',
    requires            => {
        'URI::Escape' => 0, # XS doesn't need this, but oh well
    },
);

$builder->create_build_script;
if (-f "META.yml" && ! -f "MYMETA.yml") { # fallback if we don't have CPAN::Meta
    require File::Copy;
    File::Copy::copy("META.yml", "MYMETA.yml") or warn "Error: $!\n";
    if ( -f 'MYMETA.yml' ) {
        warn "Copied META.yml to MYMETA.yml for bootstrapping\n";
    } else {
        warn "Could not copy META.yml to MYMETA.yml.  That's odd!\n";
    }
}

