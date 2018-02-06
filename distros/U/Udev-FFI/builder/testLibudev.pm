package builder::testLibudev;
use strict;
use warnings;
use parent 'Module::Build';

use FFI::CheckLib;

sub new {
    my ($class, %arg) = @_;

    my ($libudev) = find_lib( lib => 'udev' );
    die qq{It seems that your system doesn't provide udev library.
Please install udev library.
Installation failed.\n}
        unless defined $libudev;

    $class->SUPER::new(%arg);
}

1;