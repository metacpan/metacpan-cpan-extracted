package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::Create;
# ABSTRACT: Create a Storage Box subaccount

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl storage-box subaccount create --home-directory <dir> --password <password> [--name <name>] [--description <description>] <storage-box>';
use WWW::Hetzner::Storage::API::Subaccounts;
with 'WWW::Hetzner::CLI::Role::WaitsForAction';


option home_directory => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Subaccount home directory',
);

option password => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Subaccount password (input only)',
);

option name => (
    is     => 'ro',
    format => 's',
    doc    => 'Subaccount display name',
);

option description => (
    is     => 'ro',
    format => 's',
    doc    => 'Subaccount description',
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl storage-box subaccount create <storage-box>\n";

    my %params = (
        home_directory => $self->home_directory,
        password       => $self->password,
    );
    $params{name} = $self->name if defined $self->name;
    $params{description} = $self->description if defined $self->description;

    print "Creating subaccount for Storage Box $id...\n";
    my $subaccounts = WWW::Hetzner::Storage::API::Subaccounts->new(
        client         => $chain->[0]->storage,
        storage_box_id => $id,
    );
    my $subaccount = $subaccounts->create(%params);
    $self->handle_action($subaccount->action);
    print $self->no_wait ? "Subaccount creation requested.\n" : "Subaccount created.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::Create - Create a Storage Box subaccount

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl storage-box subaccount create 42 --home-directory backup/host01 --password secret
    hcloud.pl storage-box subaccount create 42 --home-directory backup/host01 --password secret --name host01 --no-wait

=head1 DESCRIPTION

Creates a subaccount of a Storage Box. C<--home-directory> and
C<--password> are required. The supplied password is never echoed to the
output. Polls the create action by default unless C<--no-wait> is given.

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
