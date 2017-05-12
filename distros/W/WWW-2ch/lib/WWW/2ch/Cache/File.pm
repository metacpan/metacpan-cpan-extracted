package WWW::2ch::Cache::File;
use strict;

use File::Path;

sub new {
    my $class = shift;
    my $dir = shift;

    my $self = bless {dir => $dir}, $class;
    unless (-e $dir && -d _) {
	mkdir($dir, 0755) or die "mkdir $dir: $!";
    }
    $self;
}

sub set {
    my ($self, $key, $data) = @_;

    my $path = $self->{dir} . "/$key";
    my $dir = $path;
    $dir =~ s|/[^/]*$|/|;
    mkpath($dir, 0, 0755);

    open my $fh, ">$path" or die "ope $path: $!";
    print $fh $data;
    close($fh);
}

sub get {
    my ($self, $key) = @_;

    my $path = $self->{dir} . "/$key";
    open my $fh, "$path" or return;
    my $data = join('', <$fh>);
    close($fh);
    $data;
}
1;
