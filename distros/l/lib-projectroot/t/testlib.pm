package testlib;
use Exporter 'import';
use File::Spec::Functions qw(splitdir);

@EXPORT_OK = qw(cleanup);

sub cleanup {
    my $dir = shift;
    my @clean;
    my $drin=1;
    foreach my $part (reverse splitdir($dir)) {
        $drin=0 if $part=~/lib-projectroot/;
        push(@clean, $part) if $drin;
    }

    return join('/',reverse @clean);
}


