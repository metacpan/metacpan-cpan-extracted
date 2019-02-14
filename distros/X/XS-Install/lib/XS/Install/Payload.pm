package XS::Install::Payload;
use strict;
use warnings;
use Cwd();

my (%module_info, %vcache);

sub data_dir {
    my $module = pop;
    $module =~ s/::/\//g;
    
    # first try search in loaded module's dir
    if (my $path = $INC{"$module.pm"}) {
        $path =~ s/\.pm$//;
        my $pldir = "$path.x";
        return Cwd::realpath($pldir) if -d $pldir;
    }
    
    foreach my $inc (@INC) {
        my $pldir = "$inc/$module.x";
        return Cwd::realpath($pldir) if -d $pldir;
    }
    
    return undef;
}

sub payload_dir {
    my $data_dir = data_dir(@_) or return undef;
    my $dir = "$data_dir/payload";
    return $dir if -d $dir;
    return undef;
}

sub include_dir {
    my $data_dir = data_dir(@_) or return undef;
    my $dir = "$data_dir/i";
    return $dir if -d $dir;
    return undef;
}

sub typemap_dir {
    my $data_dir = data_dir(@_) or return undef;
    my $dir = "$data_dir/tm";
    return $dir if -d $dir;
    return undef;
}

sub binary_module_info_file {
    my $data_dir = data_dir(@_) or return undef;
    return "$data_dir/info";
}

sub binary_module_info {
    my $module = shift;
    my $info = $module_info{$module};
    unless ($info) {
        my $file = binary_module_info_file($module) or return undef;
        return undef unless -f $file;
        $info = do($file) or return undef;
        unless (ref($info) eq 'HASH') {
            warn "bad module info file: $file";
            return undef;
        }
        $module_info{$module} = $info;
    }
    return $info;
}

sub loaded_module_version {
    my $module = shift;
    no strict 'refs';
    my $version = ${"${module}::VERSION"};
    if (!$version and my $vsub = $module->can('VERSION')) { $version = $module->VERSION }
    return $version || 0;
}

1;
