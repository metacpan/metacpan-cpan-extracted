package
    XS::Install::Util;
use strict;
use warnings;
use XS::Install::Payload;

sub cmd_sync_bin_deps {
    my $myself = shift @ARGV;
    my @modules = @ARGV;
    foreach my $module (@modules) {
        my $info = XS::Install::Payload::binary_module_info($module) or next;
        my $dependent = $info->{BIN_DEPENDENT} || [];
        my %tmp = map {$_ => 1} grep {$_ ne $module} @$dependent;
        $tmp{$myself} = 1;
        $info->{BIN_DEPENDENT} = [sort keys %tmp];
        delete $info->{BIN_DEPENDENT} unless @{$info->{BIN_DEPENDENT}};
        my $file = XS::Install::Payload::binary_module_info_file($module);
        module_info_write($file, $info);
    }
}

sub cmd_check_dependencies {
    require XS::Install::Deps;
    
    my $objext = shift @ARGV;
    
    my (@inc, @cfiles, @xsfiles);
    my $curlist = \@cfiles;
    foreach my $arg (@ARGV) {
        if ($arg =~ s/^-I//) {
            push @inc, $arg;
        }
        elsif ($arg eq '-xs') {
            $curlist = \@xsfiles;
        }
        else {
            push @$curlist, $arg;
        }
    }
    
    my @touch_list = (
        _check_mtimes(
            XS::Install::Deps::find_header_deps({
                files   => \@cfiles,
                headers => ['./'],
                inc     => \@inc,
            }),
            sub {
                my $ofile = shift;
                $ofile =~ s/\.[^.]+$//;
                $ofile .= $objext;
                return $ofile;
            },
        ),
        _check_mtimes(XS::Install::Deps::find_xsi_deps(\@xsfiles))
    );
    
    if (@touch_list) {
        my $now = time();
        utime($now, $now, @touch_list);
    }
}

sub _check_mtimes {
    my ($deps, $reference_file_sub) = @_;
    my %mtimes;
    my @touch_list;
    foreach my $file (keys %$deps) {
        my $list = $deps->{$file} or next;
        my $reference_file = $reference_file_sub ? $reference_file_sub->($file) : $file;
        my $reference_time = (stat($reference_file))[9] or next;
        foreach my $depfile (@$list) {
            my $mtime = $mtimes{$depfile} ||= (stat($depfile))[9];
            next if $mtime <= $reference_time;
            #warn "for file $file dependency $depfile changed";
            push @touch_list, $file;
            last;
        }
    }
    
    return @touch_list;
}

sub module_info_write {
    my ($file, $info) = @_;
    require Data::Dumper;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    my $content = Data::Dumper::Dumper($info);
    my $restore_mode;
    if (-e $file) { # make sure we have permissions to write, because perl installs files with 444 perms
        my $mode = (stat $file)[2];
        unless ($mode & 0200) { # if not, temporary enable write permissions
            $restore_mode = $mode;
            $mode |= 0200;
            chmod $mode, $file;
        }
    }
    open my $fh, '>', $file or die "Cannot open $file for writing: $!, binary data could not be written\n";
    print $fh $content;
    close $fh;
    
    chmod $restore_mode, $file if $restore_mode; # restore old perms if we changed it
}

1;