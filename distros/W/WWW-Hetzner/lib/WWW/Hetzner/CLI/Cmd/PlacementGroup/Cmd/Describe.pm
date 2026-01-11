package WWW::Hetzner::CLI::Cmd::PlacementGroup::Cmd::Describe;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Describe a placement group

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl placement-group describe <id>';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl placement-group describe <id>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $pg = $cloud->placement_groups->get($id);

    if ($main->output eq 'json') {
        print encode_json($pg->data), "\n";
        return;
    }

    printf "ID:      %s\n", $pg->id;
    printf "Name:    %s\n", $pg->name;
    printf "Type:    %s\n", $pg->type;
    printf "Created: %s\n", $pg->created // '-';

    my $servers = $pg->servers;
    if ($servers && @$servers) {
        printf "Servers: %s\n", join(', ', @$servers);
    } else {
        print "Servers: none\n";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::PlacementGroup::Cmd::Describe - Describe a placement group

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
