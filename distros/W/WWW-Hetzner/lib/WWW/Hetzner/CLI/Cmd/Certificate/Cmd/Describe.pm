package WWW::Hetzner::CLI::Cmd::Certificate::Cmd::Describe;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Describe a certificate

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl certificate describe <id>';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl certificate describe <id>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $cert = $cloud->certificates->get($id);

    if ($main->output eq 'json') {
        print encode_json($cert->data), "\n";
        return;
    }

    printf "ID:          %s\n", $cert->id;
    printf "Name:        %s\n", $cert->name;
    printf "Type:        %s\n", $cert->type;
    printf "Fingerprint: %s\n", $cert->fingerprint // '-';
    printf "Valid From:  %s\n", $cert->not_valid_before // '-';
    printf "Valid Until: %s\n", $cert->not_valid_after // '-';
    printf "Created:     %s\n", $cert->created // '-';

    my $domains = $cert->domain_names;
    if ($domains && @$domains) {
        print "Domains:\n";
        for my $d (@$domains) {
            print "  - $d\n";
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Certificate::Cmd::Describe - Describe a certificate

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
