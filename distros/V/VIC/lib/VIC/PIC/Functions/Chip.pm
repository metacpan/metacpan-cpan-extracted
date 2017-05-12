package VIC::PIC::Functions::Chip;
use strict;
use warnings;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Moo::Role;

##allow adjusting of this based on user input. for now fixed to this
#string
sub get_chip_config {
    my $self = shift;
    my $conf = $self->chip_config;
    return "\n" unless (defined $conf and ref $conf eq 'HASH');
    my $onoff = $conf->{on_off} || {};
    my $clkout = $conf->{f_osc} || {};
    if ($self->pcl_size == 13) {
        my @flags = ();
        foreach (keys %$onoff) {
            push @flags, "_$_" . ($onoff->{$_} ? '_ON' : '_OFF');
        }
        foreach (keys %$clkout) {
            push @flags, "_$_" . ($clkout->{$_} ? '_NOCLKOUT' : '_CLKOUT');
        }
        return "\t__config (" . join(' & ', sort @flags) . ")\n" if @flags;
    } elsif ($self->pcl_size == 21) {
    } else {
    }
    return "\n";
}

1;
__END__
