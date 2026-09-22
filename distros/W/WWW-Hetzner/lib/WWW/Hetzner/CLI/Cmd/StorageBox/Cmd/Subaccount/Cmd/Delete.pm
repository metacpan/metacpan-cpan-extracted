package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::Delete;
# ABSTRACT: Delete a Storage Box subaccount

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl storage-box subaccount delete <storage-box> <subaccount>';
use WWW::Hetzner::Storage::API::Subaccounts;
with 'WWW::Hetzner::CLI::Role::WaitsForAction';


sub execute {
    my ($self, $args, $chain) = @_;
    my $id  = $args->[0] or die "Usage: hcloud.pl storage-box subaccount delete <storage-box> <subaccount>\n";
    my $sub = $args->[1] or die "Usage: hcloud.pl storage-box subaccount delete <storage-box> <subaccount>\n";

    my $subaccounts = WWW::Hetzner::Storage::API::Subaccounts->new(
        client         => $chain->[0]->storage,
        storage_box_id => $id,
    );
    my $action = $subaccounts->delete($sub);
    $self->handle_action($action);
    print $self->no_wait ? "Subaccount deletion requested.\n" : "Subaccount deleted.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::Delete - Delete a Storage Box subaccount

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl storage-box subaccount delete 42 1
    hcloud.pl storage-box subaccount delete 42 1 --no-wait

=head1 DESCRIPTION

Deletes a subaccount of a Storage Box. Polls the action by default unless
C<--no-wait> is given.

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
