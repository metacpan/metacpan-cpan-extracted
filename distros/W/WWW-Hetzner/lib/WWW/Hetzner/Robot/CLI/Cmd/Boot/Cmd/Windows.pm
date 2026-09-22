package WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Windows;
# ABSTRACT: Windows installation boot configuration

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hrobot.pl boot windows <server-number> [--enable --os <os> --lang <lang> | --disable]';


option enable => (
    is      => 'ro',
    short   => 'e',
    doc     => 'Activate the Windows installation',
    default => 0,
);

option disable => (
    is      => 'ro',
    short   => 'd',
    doc     => 'Deactivate the Windows installation',
    default => 0,
);

option os => (
    is     => 'ro',
    format => 's',
    doc    => 'Windows edition to install - required with --enable',
);

option lang => (
    is     => 'ro',
    format => 's',
    doc    => 'Installation language - required with --enable',
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];
    my $robot = $root->robot;

    my $server_number = $args->[0]
        or die "Usage: hrobot.pl boot windows <server-number> [--enable --os <os> --lang <lang> | --disable]\n";

    die "--enable and --disable are mutually exclusive\n"
        if $self->enable && $self->disable;

    my $windows;
    if ($self->enable) {
        die "--os is required with --enable\n" unless $self->os;
        die "--lang is required with --enable\n" unless $self->lang;
        $windows = $robot->boot->enable_windows(
            $server_number,
            os   => $self->os,
            lang => $self->lang,
        );
    } elsif ($self->disable) {
        $windows = $robot->boot->disable_windows($server_number);
    } else {
        $windows = $robot->boot->windows($server_number);
    }

    if ($root->output eq 'json') {
        require JSON::MaybeXS;
        print JSON::MaybeXS::encode_json($windows);
        print "\n";
    } else {
        _print_windows($windows);
        print "\nReset the server to start the installation.\n" if $self->enable;
    }
}

sub _print_windows {
    my ($w) = @_;
    my $os = $w->{os};
    $os = join(', ', @$os) if ref $os eq 'ARRAY';
    my $lang = $w->{lang};
    $lang = join(', ', @$lang) if ref $lang eq 'ARRAY';
    print "Server Number: ", $w->{server_number} // '', "\n";
    print "Server IP:     ", $w->{server_ip} // '', "\n";
    print "Active:        ", $w->{active} ? 'yes' : 'no', "\n";
    print "OS:            ", $os // '', "\n";
    print "Lang:          ", $lang // '', "\n";
    print "Password:      ", $w->{password}, "\n" if defined $w->{password};
}

1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Windows - Windows installation boot configuration

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hrobot.pl boot windows <server-number>
    hrobot.pl boot windows 123456
    hrobot.pl boot windows 123456 --enable --os 'Windows Server 2022 Standard Edition' --lang en
    hrobot.pl boot windows 123456 --disable

Activation requires a previously purchased Windows addon for that server.

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
