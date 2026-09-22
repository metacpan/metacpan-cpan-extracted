package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Folders;
# ABSTRACT: List Storage Box folders

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl storage-box folders [--path <path>] <storage-box>';
use JSON::MaybeXS qw(encode_json);


option path => (
    is     => 'ro',
    format => 's',
    doc    => 'Folder path (default /)',
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl storage-box folders <storage-box>\n";
    my $main = $chain->[0];

    my %params;
    $params{path} = $self->path if defined $self->path;

    my $folders = $main->storage->storage_boxes->folders($id, %params);

    if ($main->output eq 'json') {
        print encode_json($folders), "\n";
        return;
    }

    if (!@$folders) {
        print "No folders found.\n";
        return;
    }

    printf "%s\n", 'PATH';
    print '-' x 60, "\n";
    for my $folder (@$folders) {
        printf "%s\n", $folder;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Folders - List Storage Box folders

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl storage-box folders 42
    hcloud.pl storage-box folders 42 --path /backup
    hcloud.pl --output json storage-box folders 42

=head1 DESCRIPTION

Lists the folders exposed by a Storage Box at the supplied path (default
C</>).

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
