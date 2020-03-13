package XS::Loader;
use strict;
use warnings;
use Config();
use DynaLoader;
use XS::Install::Payload;
use XS::Install::Util;

our $UNIQUE_LIBNAME = ($^O eq 'MSWin32');

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
            $bin_dependent = XS::Install::Util::linearize_dependent($bin_dependent);
            die << "EOF";
******************************************************************************
XS::Loader: XS module $module binary depends on XS module $dep_module.
$module was compiled with $dep_module version $bin_deps->{$dep_module}, but current version is $dep_version.
Please reinstall all modules that binary depend on $dep_module:
cpanm --reinstall @$bin_dependent
******************************************************************************
EOF
        }
    }}

    local *DynaLoader::mod2fname = \&mod2fname_unique if $UNIQUE_LIBNAME;

    my $ok = eval {
        DynaLoader::bootstrap_inherit($module, $version);
        1;
    };
    die($@) if !$ok and !($noboot and $@ and $@ =~ /Can't find 'boot_/i);

    if ($flags) {
        no strict 'refs';
        my $stash = \%{"${module}::"};
        delete $stash->{dl_load_flags};
    }
}

sub load_noboot {
    @_ = ($_[0], $_[1], $_[2], 1);
    goto &load;
}

*bootstrap = *load;

############## taken from DynaLoader_pm.PL, needed on Windows #####################
sub mod2fname_unique {
    my $parts = shift;
    my $so_len = length($Config::Config{dlext}) + 1;
    my $name_max = 255; # No easy way to get this here

    my $libname = "PL_".join("__", @$parts);

    return $libname if (length($libname)+$so_len) <= $name_max;

    # It's too darned big, so we need to go strip. We use the same
    # algorithm as xsubpp does. First, strip out doubled __
    $libname =~ s/__/_/g;
    return $libname if (length($libname)+$so_len) <= $name_max;

    # Strip duplicate letters
    1 while $libname =~ s/(.)\1/\U$1/i;
    return $libname if (length($libname)+$so_len) <= $name_max;

    # Still too long. Truncate.
    $libname = substr($libname, 0, $name_max - $so_len);
    return $libname;
}

1;
