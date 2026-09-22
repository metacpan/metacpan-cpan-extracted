package WWW::Hetzner::Robot::CLI::Cmd::Rdns;
# ABSTRACT: Robot reverse DNS commands

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hrobot.pl rdns [<ip> [--ptr <hostname> | --delete]]';


option ptr => (
    is     => 'ro',
    format => 's',
    doc    => 'Set the PTR record for the given IP',
);

option delete => (
    is      => 'ro',
    short   => 'd',
    doc     => 'Delete the reverse DNS entry of the given IP',
    default => 0,
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];
    my $robot = $root->robot;

    my $ip = $args->[0];

    unless ($ip) {
        die "An IP address is required with --ptr\n"    if defined $self->ptr;
        die "An IP address is required with --delete\n" if $self->delete;
        return $self->_list($robot, $root);
    }

    die "--ptr and --delete are mutually exclusive\n"
        if defined $self->ptr && $self->delete;

    if ($self->delete) {
        $robot->rdns->delete($ip);
        print "Reverse DNS entry for $ip deleted\n" unless $root->output eq 'json';
        return;
    }

    my $entry = defined $self->ptr
        ? $robot->rdns->update($ip, $self->ptr)
        : $robot->rdns->get($ip);

    if ($root->output eq 'json') {
        require JSON::MaybeXS;
        print JSON::MaybeXS::encode_json({ ip => $entry->ip, ptr => $entry->ptr });
        print "\n";
    } else {
        print "IP:  ", $entry->ip // '', "\n";
        print "PTR: ", $entry->ptr // '', "\n";
    }
}

sub _list {
    my ($self, $robot, $root) = @_;

    my $entries = $robot->rdns->list;

    if ($root->output eq 'json') {
        require JSON::MaybeXS;
        print JSON::MaybeXS::encode_json([map { +{
            ip  => $_->ip,
            ptr => $_->ptr,
        } } @$entries]);
        print "\n";
    } else {
        printf "%-40s %s\n", 'IP', 'PTR';
        for my $e (@$entries) {
            printf "%-40s %s\n", $e->ip // '', $e->ptr // '';
        }
    }
}

1.

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::CLI::Cmd::Rdns - Robot reverse DNS commands

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hrobot.pl rdns                                      # List all entries
    hrobot.pl rdns 203.0.113.50                         # Show one entry
    hrobot.pl rdns 203.0.113.50 --ptr mail.example.com  # Set the PTR record
    hrobot.pl rdns 203.0.113.50 --delete                # Delete the entry
    hrobot.pl rdns -o json

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
