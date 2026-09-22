package WWW::Hetzner::Robot::CLI::Cmd::Boot;
# ABSTRACT: Robot boot configuration commands

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hrobot.pl boot <server-number> | hrobot.pl boot [rescue|linux|vnc|windows] <server-number> [options]';



sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];
    my $robot = $root->robot;

    my $server_number = $args->[0] or die "Usage: hrobot.pl boot <server-number>\n";

    my $boot = $robot->boot->get($server_number);

    if ($root->output eq 'json') {
        require JSON::MaybeXS;
        print JSON::MaybeXS::encode_json($boot);
        print "\n";
    } else {
        printf "%-10s %-8s %s\n", 'OPTION', 'ACTIVE', 'AVAILABLE';
        for my $variant (qw(rescue linux vnc windows)) {
            my $o = $boot->{$variant} or next;
            my $available = $o->{os} // $o->{dist};
            $available = join(', ', @$available) if ref $available eq 'ARRAY';
            printf "%-10s %-8s %s\n",
                $variant,
                $o->{active} ? 'yes' : 'no',
                $available // '';
        }
    }
}


1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::CLI::Cmd::Boot - Robot boot configuration commands

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hrobot.pl boot <server-number>              # status of all boot options
    hrobot.pl boot 123456
    hrobot.pl boot 123456 -o json

    hrobot.pl boot rescue 123456 --enable --os linux
    hrobot.pl boot linux 123456 --enable --dist 'Debian 12 minimal' --lang en
    hrobot.pl boot vnc 123456 --enable --dist centOS-5.0 --lang en_US
    hrobot.pl boot windows 123456 --enable --os 'Windows Server 2022 Standard Edition' --lang en

=head1 SUBCOMMANDS

=over 4

=item * L<rescue|WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Rescue> - Configure rescue-system boot

=item * L<linux|WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Linux> - Configure Linux installation boot

=item * L<vnc|WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Vnc> - Configure VNC installation boot

=item * L<windows|WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Windows> - Configure Windows installation boot

=back

=head2 execute

Prints the status of all four boot options for the given server number.

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
