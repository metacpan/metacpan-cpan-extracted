package WWW::Hetzner::CLI::Cmd::Certificate::Cmd::List;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: List certificates

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl certificate list';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $certs = $cloud->certificates->list;

    if ($main->output eq 'json') {
        print encode_json([ map { $_->data } @$certs ]), "\n";
        return;
    }

    if (!@$certs) {
        print "No certificates found.\n";
        return;
    }

    printf "%-8s %-30s %-10s %-30s\n", 'ID', 'NAME', 'TYPE', 'DOMAINS';
    printf "%-8s %-30s %-10s %-30s\n", '-' x 8, '-' x 30, '-' x 10, '-' x 30;

    for my $c (@$certs) {
        my $domains = join(', ', @{$c->domain_names // []}) || '-';
        $domains = substr($domains, 0, 27) . '...' if length($domains) > 30;
        printf "%-8s %-30s %-10s %-30s\n",
            $c->id, $c->name // '-', $c->type // '-', $domains;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Certificate::Cmd::List - List certificates

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
