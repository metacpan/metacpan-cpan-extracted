# base class.

package Driver::BaseClass;

use Carp;

sub init {
    my %options = @_;
}

sub chdir {
    my ($dir) = @_;
    chdir($dir);
}

sub load_stylesheet {
    my ($filename) = @_;
    croak("load_stylesheet(filename) unimplemented");
}

sub load_input {
    my ($filename) = @_;
    croak("load_input(filename) unimplemented");
}

sub run_transform {
    my ($output) = @_;
    croak("run_transform(output) unimplemented");
}

sub shutdown {
}

1;
