package WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::LogicBoxes::Types qw( DomainName Int IP PrivateNameServer );

use WWW::LogicBoxes::PrivateNameServer;

use Try::Tiny;
use Carp;

requires 'submit', 'get_domain_by_id';

our $VERSION = '1.10.0'; # VERSION
# ABSTRACT: Domain Private Nameserver API Calls

sub create_private_nameserver {
    my $self = shift;
    my ( $nameserver ) = pos_validated_list( \@_, { isa => PrivateNameServer, coerce => 1 } );

    return try {
        $self->submit({
            method => 'domains__add_cns',
            params => {
                'order-id' => $nameserver->domain_id,
                'cns'      => $nameserver->name,
                'ip'       => $nameserver->ips,
            }
        });

        return $self->get_domain_by_id( $nameserver->domain_id );
    }
    catch {
        if( $_ =~ m/^No Entity found for Entityid/ ) {
            croak 'No such domain';
        }
        elsif( $_ =~ m/This IpAddress already exists/ ) {
            croak 'Nameserver with this IP Address already exists';
        }

        croak $_;
    };
}

sub rename_private_nameserver {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_id => { isa => Int },
        old_name  => { isa => DomainName },
        new_name  => { isa => DomainName },
    );

    return try {
        $self->submit({
            method => 'domains__modify_cns_name',
            params => {
                'order-id' => $args{domain_id},
                'old-cns'  => $args{old_name},
                'new-cns'  => $args{new_name},
            }
        });

        return $self->get_domain_by_id( $args{domain_id} );
    }
    catch {
        ## no critic (ControlStructures::ProhibitCascadingIfElse RegularExpressions::ProhibitComplexRegexes)
        if( $_ =~ m/^No Entity found for Entityid/ ) {
            croak 'No such domain';
        }
        elsif( $_ =~ m/^Invalid Old Child NameServer. Its not registered nameserver for this domain/ ) {
            croak 'No such existing private nameserver';
        }
        elsif( $_ =~ m/^Parent Domain for New child nameServer is not registered by us/
            || $_ =~ m/^\{hostname=Parent DomainName is not registered by you\}/ ) {
            croak 'Invalid domain for private nameserver';
        }
        elsif( $_ =~ m/^Same value for new and old Child NameServer/ ) {
            croak 'Same value for old and new private nameserver name';
        }
        elsif( $_ =~ m/^\{hostname=Child NameServer already exists\}/ ) {
            croak 'A nameserver with that name already exists';
        }
        ## use critic

        croak $_;
    };
}

sub modify_private_nameserver_ip {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_id => { isa => Int },
        name      => { isa => DomainName },
        old_ip    => { isa => IP },
        new_ip    => { isa => IP },
    );

    return try {
        $self->submit({
            method => 'domains__modify_cns_ip',
            params => {
                'order-id' => $args{domain_id},
                'cns'      => $args{name},
                'old-ip'   => $args{old_ip},
                'new-ip'   => $args{new_ip},
            }
        });

        return $self->get_domain_by_id( $args{domain_id} );
    }
    catch {
        ## no critic (ControlStructures::ProhibitCascadingIfElse RegularExpressions::ProhibitComplexRegexes)
        if( $_ =~ m/^No Entity found for Entityid/ ) {
            croak 'No such domain';
        }
        elsif( $_ =~ m/^Invalid Child Name Server. Its not registered nameserver for this domain/ ) {
            croak 'No such existing private nameserver';
        }
        elsif( $_ =~ m/^Same value for new and old IpAddress/ ) {
            croak 'Same value for old and new private nameserver ip';
        }
        elsif( $_ =~ m/^Invalid Old IpAddress. Its not attached to Nameserver/ ) {
            croak 'Nameserver does not have specified ip';
        }
        ## use critic

        croak $_;
    };
}

sub delete_private_nameserver_ip {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_id => { isa => Int },
        name      => { isa => DomainName },
        ip        => { isa => IP },
    );

    return try {
        $self->submit({
            method => 'domains__delete_cns_ip',
            params => {
                'order-id' => $args{domain_id},
                'cns'      => $args{name},
                'ip'       => $args{ip},
            }
        });

        return $self->get_domain_by_id( $args{domain_id} );
    }
    catch {
        ## no critic (ControlStructures::ProhibitCascadingIfElse RegularExpressions::ProhibitComplexRegexes)
        if( $_ =~ m/^No Entity found for Entityid/ ) {
            croak 'No such domain';
        }
        elsif( $_ =~ m/^Invalid Child Name Server. Its not registered nameserver for this domain/ ) {
            croak 'No such existing private nameserver';
        }
        elsif( $_ =~ m/^\{ipaddress1=Invalid IpAddress .* Its not attached to Nameserver\}/ ) {
            croak 'IP address not assigned to private nameserver';
        }
        ## use critic

        croak $_;
    };
}

sub delete_private_nameserver {
    my $self = shift;
    my ( $nameserver ) = pos_validated_list( \@_, { isa => PrivateNameServer, coerce => 1 } );

    return try {
        for my $ip (@{ $nameserver->ips } ) {
            $self->delete_private_nameserver_ip(
                domain_id => $nameserver->domain_id,
                name      => $nameserver->name,
                ip        => $ip,
            );
        }

        return $self->get_domain_by_id( $nameserver->domain_id );
    }
    catch {
        if( $_ =~ m/^No Entity found for Entityid/ ) {
            croak 'No such domain';
        }

        croak $_;
    };
}

1;

__END__
=pod

=head1 NAME

WWW::LogicBoxes::Role::Command::Domain::PrivateNameServer - Private Nameserver Related Operations

=head1 SYNOPSIS

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;
    use WWW::LogicBoxes::PrivateNameServer;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $domain      = WWW::LogicBoxes::Domain->new( ... );

    # Creation
    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ips       => [ '4.2.2.1' ],
    );

    $logic_boxes->create_private_nameserver( $private_nameserver );

    # Rename
    $logic_boxes->rename_private_nameserver(
        domain_id => $domain->id,
        old_name  => 'ns1.' . $domain->name,
        new_name  => 'ns2.' . $domain->name,
    );

    # Modify IP
    $logic_boxes->modify_private_nameserver_ip(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        old_ip    => '4.2.2.1',
        new_ip    => '8.8.8.8',
    );

    # Delete IP
    $logic_boxes->delete_private_nameserver_ip(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ip        => '4.2.2.1',
    );

    # Delete Private Nameserver
    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new( ... );
    $logic_boxes->delete_private_nameserver( $private_nameserver )

=head1 REQUIRES

=over 4

=item submit

=item get_domain_by_id

=back

=head1 DESCRIPTION

Implementes Private Nameserver related operations (what L<LogicBoxes|http://www.logicboxes.com> refers to as "Child Nameservers") with the L<LogicBoxes|http://www.logicboxes.com> API.

B<NOTE> All private nameservers must be a subdomain of the parent domain.  If the domain name is test-domain.com, ns1.test-domain.com would be valid while ns1.something-else.com would not be.

=head1 METHOD

=head2 create_private_nameserver

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;
    use WWW::LogicBoxes::PrivateNameServer;

    my $logic_boxes = WWW::LogicBoxes->new( ... );
    my $domain      = WWW::LogicBoxes::Domain->new( ... );

    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ips       => [ '4.2.2.1', '2001:4860:4860:0:0:0:0:8888' ],
    );

    $logic_boxes->create_private_nameserver( $private_nameserver );

Given a L<WWW::LogicBoxes::PrivateNameServer> or a HashRef that can be coerced into a L<WWW::LogicBoxes::PrivateNameServer>, creates the specified private nameserver with L<LogicBoxes|http://www.logicboxes.com>.

=head2 rename_private_nameserver

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;

    my $domain = WWW::LogicBoxes::Domain->new( ... );

    $logic_boxes->rename_private_nameserver(
        domain_id => $domain->id,
        old_name  => 'ns1.' . $domain->name,
        new_name  => 'ns2.' . $domain->name,
    );

Given an Integer L<domain|WWW::LogicBoxes::Domain> id, the old nameserver hostname, and a new nameserver hostname, renames a L<WWW::LogicBoxes::PrivateNameServer>.

=head2 modify_private_nameserver_ip

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;

    my $domain = WWW::LogicBoxes::Domain->new( ... );

    $logic_boxes->modify_private_nameserver_ip(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        old_ip    => '4.2.2.1',
        new_ip    => '2001:4860:4860:0:0:0:0:8888',
    );

Given an Integer L<domain|WWW::LogicBoxes::Domain> id, nameserver hostname, an old_ip (that is currently assigned to the L<private nameserver|WWW::LogicBoxes::PrivateNameServer>), and a new_ip, modifies the ips assoicated with a L<WWW::LogicBoxes::PrivateNameServer>.

=head2 delete_private_nameserver_ip

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;

    my $domain = WWW::LogicBoxes::Domain->new( ... );

    $logic_boxes->delete_private_nameserver_ip(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ip        => '4.2.2.1', # Or an IPv4 Address
    );

Given an Integer L<domain|WWW::LogicBoxes::Domain> id, nameserver hostname, and an ip (that is currently assigned to the L<private nameserver|WWW::LogicBoxes::PrivateNameServer>), removes the ip assoicated with a L<WWW::LogicBoxes::PrivateNameServer>.

=head2 delete_private_nameserver

    use WWW::LogicBoxes;
    use WWW::LogicBoxes::Domain;
    use WWW::LogicBoxes::PrivateNameServer;

    my $domain = WWW::LogicBoxes::Domain->new( ... );

    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new( ... );
    $logic_boxes->delete_private_nameserver( $private_nameserver )


Given a L<WWW::LogicBoxes::PrivateNameServer> or a HashRef that can be coerced into a L<WWW::LogicBoxes::PrivateNameServer>, deletes the specified private nameserver with L<LogicBoxes|http://www.logicboxes.com>.

=cut
