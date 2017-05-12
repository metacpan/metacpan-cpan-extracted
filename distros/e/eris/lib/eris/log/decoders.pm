package eris::log::decoders;

use eris::log;
use Moo;
use Time::HiRes qw(gettimeofday tv_interval);
use Types::Standard qw(ArrayRef);
use namespace::autoclean;

with qw(
    eris::role::pluggable
);


########################################################################
# Attributes

########################################################################
# Builders
sub _build_namespace { 'eris::log::decoder' }

########################################################################
# Methods
{
    my $decoders = undef;
    sub decode {
        my ($self,$raw) = @_;

        # Initialize the decoders
        $decoders //= $self->plugins;

        # Create the log entry
        my $log = eris::log->new( raw => $raw );

        # Store the decoded data
        my %t=();
        foreach my $decoder (@{ $decoders }) {
            my $t0 = [gettimeofday];
            my $data = $decoder->decode_message($raw);
            my $decoder_name = $decoder->name;
            if( defined $data && ref $data eq 'HASH' ) {
                $log->set_decoded($decoder_name => $data);
            }
            $t{"decoder::$decoder_name"} = tv_interval($t0);
        }
        $log->add_timing(%t);

        return $log;      # Return the log object
    }
} # end closure

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::decoders

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
