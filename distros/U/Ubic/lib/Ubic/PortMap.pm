package Ubic::PortMap;
$Ubic::PortMap::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: update and read mapping of ports to service names.


use Try::Tiny;
use Params::Validate qw(:all);

use Ubic::Logger;
use Ubic::Persistent;
use Ubic;

sub _portmap_file {
    my $ubic_dir = Ubic->get_data_dir;
    my $PORTMAP_FILE = $ubic_dir.'/portmap';
    return $PORTMAP_FILE;
}

sub update {
    validate_pos(@_);

    my $portmap = Ubic::Persistent->new(_portmap_file());
    my %port2service;

    my $process_tree;
    $process_tree = sub {
        my $service = shift() || Ubic->root_service;
        for $_ ($service->services) {
            if ($_->isa('Ubic::Multiservice')) {
                # multiservice
                $process_tree->($_);
            }
            else {
                try {
                    my $port = $_->port;
                    if ($port) {
                        push @{ $portmap->{$port} }, $_->full_name;
                    }
                }
                catch {
                    ERROR $_;
                };
            }
        }
        return;
    };

    for (keys %{$portmap}) {
        next unless /^\d+$/;
        delete $portmap->{$_};
    }
    $process_tree->();
    $portmap->commit();
    undef $portmap; # fighting memory leaks - closure doesn't allow local variable to be destroyed

    return;
}

sub port2name($) {
    my ($port) = validate_pos(@_, { regex => qr/^\d+$/ });
    my $portmap = Ubic::Persistent->load(_portmap_file());
    return unless $portmap->{$port};
    my @names = @{ $portmap->{$port} };
    while (my $name = shift @names) {
        return $name unless @names; # return last service even if it's disabled
        return $name if Ubic->is_enabled($name);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::PortMap - update and read mapping of ports to service names.

=head1 VERSION

version 1.60

=head1 SYNOPSIS

    use Ubic::PortMap;

    Ubic::PortMap::update();
    print Ubic::PortMap::port2name(12345); # ubic.ping

=head1 INTERFACE SUPPORT

This is considered to be a non-public class. Its interface is subject to change without notice.

=head1 METHODS

=over

=item B<< update() >>

Update portmap file.

=item B<< port2name($port) >>

Get service by port.

If there are several services with one port, it will try to find enabled service among them.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
