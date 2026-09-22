package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::List;
# ABSTRACT: List subaccounts of a Storage Box

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl storage-box subaccount list <storage-box>';
use JSON::MaybeXS qw(encode_json);
use WWW::Hetzner::Storage::API::Subaccounts;


sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl storage-box subaccount list <storage-box>\n";
    my $main = $chain->[0];
    my $subaccounts = WWW::Hetzner::Storage::API::Subaccounts->new(
        client         => $main->storage,
        storage_box_id => $id,
    )->list;

    if ($main->output eq 'json') {
        print encode_json([map { $_->data } @$subaccounts]), "\n";
        return;
    }

    if (!@$subaccounts) {
        print "No subaccounts found.\n";
        return;
    }

    printf "%-10s %-25s %-25s %-40s %s\n", 'ID', 'NAME', 'USERNAME', 'HOME_DIRECTORY', 'DESCRIPTION';
    print '-' x 120, "\n";
    for my $sub (@$subaccounts) {
        printf "%-10s %-25s %-25s %-40s %s\n",
            $sub->id,
            ($sub->name // '') ne '' ? $sub->name : '-',
            $sub->username // '-',
            $sub->home_directory // '-',
            ($sub->description // '') ne '' ? $sub->description : '-';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Subaccount::Cmd::List - List subaccounts of a Storage Box

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl storage-box subaccount list 42
    hcloud.pl --output json storage-box subaccount list 42

=head1 DESCRIPTION

Lists subaccounts of a Storage Box.

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
