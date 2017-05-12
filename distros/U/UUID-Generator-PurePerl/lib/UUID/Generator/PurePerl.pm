package UUID::Generator::PurePerl;

use strict;
use warnings;
use 5.006;

our $VERSION = '0.80';

use Carp;
use Digest;
use Time::HiRes;
use UUID::Object;
use UUID::Generator::PurePerl::RNG;
use UUID::Generator::PurePerl::NodeID;
use UUID::Generator::PurePerl::Util;

sub new {
    my $class = shift;
    my $self  = bless {}, $class;

    return $self;
}

sub rng {
    my ($self) = @_;

    if (! defined $self->{rng}) {
        $self->{rng} = UUID::Generator::PurePerl::RNG->singleton();
    }

    return $self->{rng};
}

sub node_getter {
    my ($self) = @_;

    if (! defined $self->{node_getter}) {
        $self->{node_getter} = UUID::Generator::PurePerl::NodeID->singleton();
    }

    return $self->{node_getter};
}

sub get_timestamp {
    return Time::HiRes::time();
}

sub get_clk_seq {
    my $self = shift;
    my $node_id = shift;

    my $inc_seq = 0;

    my $ts = $self->get_timestamp();
    if (! defined $self->{last_ts} || $ts <= $self->{last_ts}) {
        $inc_seq ++;
    }
    $self->{last_ts} = $ts;

    if (! defined $self->{last_node}) {
        if (defined $node_id) {
            $inc_seq ++;
        }
    }
    else {
        if (! defined $node_id || $node_id ne $self->{last_node}) {
            $inc_seq ++;
        }
    }
    $self->{last_node} = $node_id;

    if (! defined $self->{clk_seq}) {
        $self->{clk_seq} = $self->_generate_clk_seq();
        return $self->{clk_seq} & 0x03ff;
    }

    if ($inc_seq) {
        $self->{clk_seq} = ($self->{clk_seq} + 1) % 65536;
    }

    return $self->{clk_seq} & 0x03ff;
}

sub _generate_clk_seq {
    my $self = shift;

    my @data;
    push @data, q{}  . $$;
    push @data, q{:} . Time::HiRes::time();

    return digest_as_16bit(@data);
}

sub generate_v1 {
    my $self = shift;

    my $node = $self->node_getter->node_id();
    my $ts   = $self->get_timestamp();

    return
        UUID::Object->create_from_hash({
            variant => 2,
            version => 1,
            node    => $node,
            time    => $ts,
            clk_seq => $self->get_clk_seq($node),
        });
}

sub generate_v1mc {
    my $self = shift;

    my $node = $self->node_getter->random_node_id();
    my $ts   = $self->get_timestamp();

    return
        UUID::Object->create_from_hash({
            variant => 2,
            version => 1,
            node    => $node,
            time    => $ts,
            clk_seq => $self->get_clk_seq(undef),
        });
}

sub generate_v4 {
    my ($self) = @_;

    my $b = q{};
    for (1 .. 4) {
        $b .= pack 'I', $self->rng->rand_32bit;
    }

    my $u = UUID::Object->create_from_binary($b);

    $u->variant(2);
    $u->version(4);

    return $u;
}

sub generate_v3 {
    my ($self, $ns, $data) = @_;

    return $self->_generate_digest(3, 'MD5', $ns, $data);
}

sub generate_v5 {
    my ($self, $ns, $data) = @_;

    return $self->_generate_digest(5, 'SHA-1', $ns, $data);
}

sub _generate_digest {
    my ($self, $version, $digest, $ns, $data) = @_;

    $ns = UUID::Object->new($ns)->as_binary;

    my $dg = Digest->new($digest);

    $dg->reset();

    $dg->add($ns);

    $dg->add($data);

    my $u = UUID::Object->create_from_binary($dg->digest);
    $u->variant(2);
    $u->version($version);

    return $u;
}

1;
__END__

=head1 NAME

UUID::Generator::PurePerl - Universally Unique IDentifier (UUID) Generator

=head1 DESCRIPTION

This module is going to be marked as *DEPRECATED*.

Do not use this module in your applications / modules.

Currently, this implementation is still functional.
If you want to know API, please refer to PODs in version 0.05.

=head1 FUTURE PLAN

=over 2

=item (1) will be renewed module that behaves like backend generator to L<Data::GUID>

=item (2) will be stub module, and be marked as DEPRECATE
D

=item (3) will be withdrawn from CPAN after a while

=back

=head1 AUTHOR

ITO Nobuaki E<lt>banb@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::GUID>, L<UUID::Object>.

version 0.05: L<http://search.cpan.org/~banb/UUID-Generator-PurePerl-0.05/>.

=cut
