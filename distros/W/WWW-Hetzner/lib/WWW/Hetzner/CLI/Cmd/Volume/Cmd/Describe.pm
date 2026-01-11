package WWW::Hetzner::CLI::Cmd::Volume::Cmd::Describe;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Describe a volume

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl volume describe <id>';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl volume describe <id>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $volume = $cloud->volumes->get($id);

    if ($main->output eq 'json') {
        print encode_json($volume->data), "\n";
        return;
    }

    printf "ID:           %s\n", $volume->id;
    printf "Name:         %s\n", $volume->name;
    printf "Size:         %s GB\n", $volume->size;
    printf "Status:       %s\n", $volume->status;
    printf "Location:     %s\n", $volume->location // '-';
    printf "Server:       %s\n", $volume->server // 'not attached';
    printf "Linux Device: %s\n", $volume->linux_device // '-';
    printf "Format:       %s\n", $volume->format // '-';
    printf "Created:      %s\n", $volume->created // '-';

    my $labels = $volume->labels;
    if ($labels && %$labels) {
        print "Labels:\n";
        for my $k (sort keys %$labels) {
            printf "  %s: %s\n", $k, $labels->{$k};
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Volume::Cmd::Describe - Describe a volume

=head1 VERSION

version 0.002

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

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
