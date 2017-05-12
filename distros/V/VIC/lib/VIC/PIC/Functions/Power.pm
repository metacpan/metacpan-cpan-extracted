package VIC::PIC::Functions::Power;
use strict;
use warnings;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Carp;
use POSIX ();
use Moo::Role;

sub sleep {
    my $self = shift;
    unless ($self->doesrole('Power')) {
        carp $self->type . " does not support sleep\n";
        return;
    }
    if (defined $self->chip_config->{on_off}) {
        foreach (keys %{$self->chip_config->{on_off}}) {
            $self->chip_config->{on_off}->{$_} = 1 if $_ =~ /PWRTE|WDT/;
        }
    }
    # best to clear the WDT before sleep always
    return << "...";
\tclrwdt ;; ensure WDT is cleared
\tsleep
\tnop ;; in case the user is using interrupts to wake up
...
}

1;
__END__
