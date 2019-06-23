package eris::log::context::dhcpd;
# ABSTRACT: Parses dhcpd messages into structured data.

use Const::Fast;
use Moo;
with qw(
    eris::role::context
);
use namespace::autoclean;

our $VERSION = '0.008'; # VERSION


sub sample_messages {
    my @msgs = split /\r?\n/, <<'EOF';
Jul  4 17:06:58 10.0.1.1 dhcpd: DHCPDISCOVER from f0:f6:1c:b9:20:57 (Necktie) via igb1
Jul  4 17:06:58 10.0.1.1 dhcpd: DHCPOFFER on 10.0.1.33 to f0:f6:1c:b9:20:57 (Necktie) via igb1
Jul  4 17:06:59 10.0.1.1 dhcpd: DHCPREQUEST for 10.0.1.33 (10.0.1.1) from f0:f6:1c:b9:20:57 (Necktie) via igb1
Jul  4 17:06:59 10.0.1.1 dhcpd: DHCPACK on 10.0.1.33 to f0:f6:1c:b9:20:57 (Necktie) via igb1
EOF
    return @msgs;
}


sub contextualize_message {
    my ($self,$log) = @_;

    local $_ = $log->context->{message};
    my $matched =  /^(?>(?<action>DHCPACK) on (?<src_ip>\S+) to (?<src_mac>\S+) (?:\((?<src>[^)]+)\) )?via (?<dev>\S+))/
                || /^(?>(?<action>DHCPREQUEST) for (?<src_ip>\S+) (?:\([^)]+\) )?from (?<src_mac>\S+) (?:\((?<src>[^)]+)\) )?via (?<dev>\S+))/
                || /^(?>(?<action>DHCPDISCOVER) from (?<src_mac>\S+) (?:\((?<src>[^)]+)\) )?via (?<dev>\S+))/
                || /^(?>(?<action>DHCPOFFER) on (?<src_ip>\S+) to (?<src_mac>\S+) (?:\((?<src>[^)]+)\) )?via (?<dev>\S+))/
                || 0;
    if( $matched ) {
        $log->add_context($self->name,{%+});
        $log->add_tags(qw(inventory));
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::context::dhcpd - Parses dhcpd messages into structured data.

=head1 VERSION

version 0.008

=head1 SYNOPSIS

Parses dhcpd messages into structured data.

=head1 METHODS

=head2 contextualize_message

Parses the DHCP daemon's log into structured data containing the keys:

    action   => DHCPACK/REQUEST/DISCOVER/OFFER
    dev      => Physical interface
    src      => Client ID, if specified
    src_ip   => Source IP Address
    src_mac  => Source MAC Address

Tags messages with 'inventory'

=for Pod::Coverage sample_messages

=head1 SEE ALSO

L<eris::log::contextualizer>, L<eris::role::context>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
