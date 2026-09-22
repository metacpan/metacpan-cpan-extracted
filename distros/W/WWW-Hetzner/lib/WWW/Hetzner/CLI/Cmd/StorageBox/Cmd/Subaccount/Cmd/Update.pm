package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::Update;
# ABSTRACT: Update a Storage Box subaccount

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl storage-box subaccount update [--name <name>] [--description <description>] <storage-box> <subaccount>';
use JSON::MaybeXS qw(encode_json);
use WWW::Hetzner::Storage::API::Subaccounts;


option name => (
    is     => 'ro',
    format => 's',
    doc    => 'New subaccount name',
);

option description => (
    is     => 'ro',
    format => 's',
    doc    => 'New subaccount description',
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id  = $args->[0] or die "Usage: hcloud.pl storage-box subaccount update <storage-box> <subaccount>\n";
    my $sub = $args->[1] or die "Usage: hcloud.pl storage-box subaccount update <storage-box> <subaccount>\n";
    my $main = $chain->[0];

    my %body;
    $body{name} = $self->name if defined $self->name;
    $body{description} = $self->description if defined $self->description;

    my $subaccounts = WWW::Hetzner::Storage::API::Subaccounts->new(
        client         => $main->storage,
        storage_box_id => $id,
    );
    my $subaccount = $subaccounts->update($sub, %body);

    if ($main->output eq 'json') {
        print encode_json($subaccount->data), "\n";
        return;
    }

    print "Subaccount updated:\n";
    printf "  ID:             %s\n", $subaccount->id;
    printf "  Name:           %s\n", ($subaccount->name // '') ne '' ? $subaccount->name : '-';
    printf "  Username:       %s\n", $subaccount->username // '-';
    printf "  Home Directory: %s\n", $subaccount->home_directory // '-';
    printf "  Description:    %s\n", ($subaccount->description // '') ne '' ? $subaccount->description : '-';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::Update - Update a Storage Box subaccount

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl storage-box subaccount update 42 1 --name host01 --description "host01 backup"
    hcloud.pl --output json storage-box subaccount update 42 1 --name host01

=head1 DESCRIPTION

Updates the C<name> and/or C<description> of a subaccount. Only the
supplied fields are sent in the request body. The returned entity is
displayed; no action is polled.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
