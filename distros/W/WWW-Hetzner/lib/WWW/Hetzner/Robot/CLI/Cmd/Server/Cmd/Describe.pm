package WWW::Hetzner::Robot::CLI::Cmd::Server::Cmd::Describe;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Describe a dedicated server

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hrobot.pl server describe <server-number> [options]';


sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];
    my $robot = $root->robot;

    my $server_number = $args->[0] or die "Usage: hrobot.pl server describe <server-number>\n";

    my $s = $robot->servers->get($server_number);

    if ($root->output eq 'json') {
        require JSON::MaybeXS;
        print JSON::MaybeXS::encode_json({
            server_number => $s->server_number,
            server_name   => $s->server_name,
            server_ip     => $s->server_ip,
            product       => $s->product,
            dc            => $s->dc,
            status        => $s->status,
            traffic       => $s->traffic,
            cancelled     => $s->cancelled,
            paid_until    => $s->paid_until,
        });
        print "\n";
    } else {
        print "Server Number: ", $s->server_number // '', "\n";
        print "Name:          ", $s->server_name // '', "\n";
        print "IP:            ", $s->server_ip // '', "\n";
        print "Product:       ", $s->product // '', "\n";
        print "Datacenter:    ", $s->dc // '', "\n";
        print "Status:        ", $s->status // '', "\n";
        print "Traffic:       ", $s->traffic // '', "\n";
        print "Cancelled:     ", $s->cancelled ? 'yes' : 'no', "\n";
        print "Paid Until:    ", $s->paid_until // '', "\n";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::CLI::Cmd::Server::Cmd::Describe - Describe a dedicated server

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    hrobot.pl server describe <server-number>
    hrobot.pl server describe 123456
    hrobot.pl server describe 123456 -o json

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
