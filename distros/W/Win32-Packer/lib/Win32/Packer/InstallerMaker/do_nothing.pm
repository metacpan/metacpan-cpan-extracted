package Win32::Packer::InstallerMaker::do_nothing;

use Moo;
use namespace::autoclean;

extends 'Win32::Packer::InstallerMaker';

sub run {
    my $self = shift;
    $self->log->info("Can I do nothing?");
}

1;
