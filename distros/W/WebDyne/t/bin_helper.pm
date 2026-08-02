package bin_helper;

use strict;
use warnings;

use Exporter qw(import);
use Capture::Tiny qw(capture);
use File::Path qw(make_path);
use File::Basename qw(dirname);

our @EXPORT_OK=qw(run_cmd write_file write_module);


sub run_cmd {

    my @cmd=@_;
    my ($stdout, $stderr, $exit)=capture {
        system(@cmd);
    };
    return ($stdout, $stderr, ($exit >> 8));

}


sub write_file {

    my ($fn, $data)=@_;
    my $dn=dirname($fn);
    make_path($dn) unless -d $dn;
    open(my $fh, '>', $fn) || die "unable to open '$fn' for write, $!";
    print {$fh} $data;
    close($fh) || die "unable to close '$fn', $!";
    return $fn;

}


sub write_module {

    my ($root_dn, $module, $data)=@_;
    (my $rel_fn="$module.pm") =~ s{::}{/}g;
    return write_file("$root_dn/$rel_fn", $data);

}


1;
