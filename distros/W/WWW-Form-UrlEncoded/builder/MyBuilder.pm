package builder::MyBuilder;

use strict;
use warnings;
use base qw(Module::Build);
use File::Spec;
use File::Path;

sub ACTION_code {
    my $self = shift;
    $self->SUPER::ACTION_code();
    my $archdir = File::Spec->catdir($self->blib,'arch','auto','WWW','Form','UrlEncoded','XS');
    File::Path::mkpath($archdir, 0, oct(777)) unless -d $archdir;
    my $keep_arch = File::Spec->catfile($archdir,'.keep');
    open(my $fh,'>',$keep_arch) or die "Couldnot open file for write: $keep_arch, $!";
    print $fh "This file required to install files to archdir for backward compatibility\n";
}

1;
