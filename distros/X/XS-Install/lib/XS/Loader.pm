package XS::Loader;
use strict;
use warnings;
use DynaLoader;
use XS::Install::Payload;

sub load {
    no strict 'refs';
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my ($module, $version, $flags) = @_;
    $flags = 0x01 unless defined $flags;
    $module ||= caller(0);
    *{"${module}::dl_load_flags"} = sub { $flags } if $flags;
    $version ||= ${"${module}::VERSION"};
    if (!$version and my $vsub = $module->can('VERSION')) { $version = $module->VERSION }
    
    if (my $info = XS::Install::Payload::module_info($module)) {{
        my $bin_deps = $info->{BIN_DEPS} or last;
        foreach my $dep_module (keys %$bin_deps) {
            next if $dep_module eq 'XS::Install';
            my $path = $dep_module;
            $path =~ s!::!/!g;
            require $path.".pm" or next;
            my $dep_version = ${"${dep_module}::VERSION"};
            if (!$dep_version and my $vsub = $dep_module->can('VERSION')) { $dep_version = $dep_module->VERSION }
            next if $dep_version eq $bin_deps->{$dep_module};
            my $dep_info = XS::Install::Payload::module_info($dep_module) || {};
            my $bin_dependent = $dep_info->{BIN_DEPENDENT};
            $bin_dependent = [$module] if !$bin_dependent or !@$bin_dependent;
            die << "EOF";
******************************************************************************
XS::Loader: XS module $module binary depends on XS module $dep_module.
$module was compiled with $dep_module version $bin_deps->{$dep_module}, but current version is $dep_version.
Please reinstall all modules that binary depend on $dep_module:
cpanm -f @$bin_dependent
******************************************************************************
EOF
        }
    }}
    
    DynaLoader::bootstrap_inherit($module, $version);
    my $stash = \%{"${module}::"};
    delete $stash->{dl_load_flags};
}
*bootstrap = *load;

sub load_tests {
    my ($module) = @_;
    require Config;
    my $fname = 'ctest.'.$Config::Config{dlext};
    
    my $file;
    foreach my $dir (@INC) {
        next unless $dir =~ m#(.*\bblib[/\\:]+)arch\b#;
        $file = $1.$fname;
        last;
    }
    $file ||= 'blib/'.$fname;
    $module ||= '';
    my $libref = DynaLoader::dl_load_file($file, 0x01) or die "Can't load '$file' for module $module: ".DynaLoader::dl_error();
    
    return unless $module;
    my $bootname = "boot_$module";
    $bootname =~ s/\W/_/g;
    
    my $boot_symbol_ref = DynaLoader::dl_find_symbol($libref, $bootname) or die "Can't find '$bootname' symbol in $file\n";
    my $xs = DynaLoader::dl_install_xsub("${module}::bootstrap", $boot_symbol_ref, $file);
    $xs->($module);
}

1;