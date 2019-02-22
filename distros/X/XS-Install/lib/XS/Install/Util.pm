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

sub cmd_check_header_dependencies {
    require XS::Install::HeaderDeps;
    
    my $objext = shift @ARGV;
    
    my (@inc, @files);
    foreach my $arg (@ARGV) {
        if ($arg =~ s/^-I//) {
            push @inc, $arg;
        } else {
            push @files, $arg;
        }
    }
    
    my $deps = XS::Install::HeaderDeps::find_deps({
        files   => \@files,
        headers => ['./'],
        inc     => \@inc,
    });
    
    my %mtimes;
    my @touch_list;
    foreach my $file (keys %$deps) {
        my $list = $deps->{$file} or next;
        my $ofile = $file;
        $ofile =~ s/\.[^.]+$//;
        $ofile .= $objext;
        my $build_time = (stat($ofile))[9] or next;
        foreach my $hdr (@$list) {
            my $mtime = $mtimes{$hdr} ||= (stat($hdr))[9];
            next if $mtime <= $build_time;
            #warn "for file $file header changed $hdr";
            push @touch_list, $file;
            last;
        }
    }
    
    if (@touch_list) {
        my $now = time();
        utime($now, $now, @touch_list);
    }
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