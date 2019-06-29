package XS::Loader;
use strict;
use warnings;
use DynaLoader;
use XS::Install::Payload;

sub load {
    shift if $_[0] && $_[0] eq __PACKAGE__;
    my ($module, $version, $flags, $noboot) = @_;
    
    $module  ||= caller(0);
    $version ||= XS::Install::Payload::loaded_module_version($module);
    $flags   //= 0x01;
    $noboot    = 1 if $module eq 'MyTest';
    
    if ($flags) {
        no strict 'refs';
        *{"${module}::dl_load_flags"} = sub { $flags };
    }
    
    if (my $info = XS::Install::Payload::binary_module_info($module)) {{
        my $bin_deps = $info->{BIN_DEPS} or last;
        foreach my $dep_module (keys %$bin_deps) {
            next if $dep_module eq 'XS::Install';
            my $path = $dep_module;
            $path =~ s!::!/!g;
            require $path.".pm" or next; # in what cases it returns false without croaking?
            my $dep_version = XS::Install::Payload::loaded_module_version($dep_module);
            next if $dep_version eq $bin_deps->{$dep_module};
            my $dep_info = XS::Install::Payload::binary_module_info($dep_module) || {};
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
    
    my $ok = eval {
        DynaLoader::bootstrap_inherit($module, $version);
        1;        
    };
    DynaLoader::croak($@) if !$ok and !($noboot and $@ and $@ =~ /Can't find 'boot_/i);
    
    if ($flags) {
        no strict 'refs';
        my $stash = \%{"${module}::"};
        delete $stash->{dl_load_flags};
    }
}

sub load_noboot { load($_[0], $_[1], $_[2], 1) }

*bootstrap = *load;

1;