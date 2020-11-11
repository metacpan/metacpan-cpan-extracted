package
    XS::Install::Util;
use strict;
use warnings;
use XS::Install::Payload;
use Fcntl qw(:flock);   # import LOCK_* constants

sub linearize_dependent {
    my $modules = shift;
    my %modules = map { $_ => 1 } @$modules;
    # make list of all dependent
    my %dependent;
    for my $module (@$modules) {
        my $info = XS::Install::Payload::binary_module_info($module) or next;
        my $dependent = $info->{BIN_DEPENDENT} || [];
        for my $d_module (@$dependent) {
            next unless $modules{$d_module};
            push @{ $dependent{$module} }, $d_module;
        }
    }

    my $get_score; $get_score = sub {
        my $module = shift;
        my $score = 1; # initial value for myself
        my $dependent = $dependent{$module} || [];
        for my $d_module (@$dependent) {
            $score += $get_score->($d_module);
        }
        return $score;
    };
    my %scores = map { $_ => $get_score->($_) } @$modules;
    my @ordered_modules = sort {
           $scores{$a} <=> $scores{$b}
        ||          $a cmp $b
    } @$modules;

    return \@ordered_modules;
}

sub cmd_sync_bin_deps {
    my $myself = shift @ARGV;
    my @modules = @ARGV;
    foreach my $module (sort @modules) {
        my $file = XS::Install::Payload::binary_module_info_file($module);
        my $lock_file = "$file.lock";
        my $fh_lock;
        open $fh_lock, '>', $lock_file or warn "Cannot open $lock_file for writing: $!\n";
        if ($fh_lock) {
            my $ok = eval { flock($fh_lock, LOCK_EX); 1 };
            warn "Cannot lock $lock_file: $! ($@)\n" unless $ok;
        }

        my $info = XS::Install::Payload::binary_module_info($module) or next;
        my $dependent = $info->{BIN_DEPENDENT} || [];
        my %tmp = map {$_ => 1} grep {$_ ne $module} @$dependent;
        $tmp{$myself} = 1;
        $info->{BIN_DEPENDENT} = linearize_dependent([keys %tmp]);
        delete $info->{BIN_DEPENDENT} unless @{$info->{BIN_DEPENDENT}};
        my $ok  = eval { module_info_write($file, $info); 1 };
        unless ($ok) {
            warn("Reverse dependency write failed: $@");
        }
        if ($fh_lock) {
            # possible errors are ignored, as we can do nothing
            flock($fh_lock, LOCK_UN) && unlink($lock_file);
        }
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

    my $temp_file = "$file.$$";
    open my $fh, '>', $temp_file or die "Cannot open $temp_file for writing: $!, binary data could not be written\n";
    print $fh $content;
    close $fh;
    rename $temp_file, $file || die("Cannot rename $temp_file to $file\n");

    chmod $restore_mode, $file if $restore_mode; # restore old perms if we changed it
}

1;
