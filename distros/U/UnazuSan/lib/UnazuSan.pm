package UnazuSan;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.03";

use AnySan;
use AnySan::Provider::IRC;
use Encode qw/decode_utf8/;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $self = bless \%args, $class;

    $self->{nickname}           //= 'unazu_san';
    $self->{port}               ||= 6667;
    $self->{post_interval}      //= 2;
    $self->{reconnect_interval} //= 3;
    $self->{receive_commands}   //= ['PRIVMSG'];

    my ($irc, $is_connect, $connector);
    $connector = sub {
        irc
            $self->{host},
            port       => $self->{port},
            key        => $self->{keyword},
            password   => $self->{password},
            nickname   => $self->{nickname},
            user       => $self->{user},
            interval   => $self->{post_interval},
            enable_ssl => $self->{enable_ssl},
            recive_commands => $self->{receive_commands},
            on_connect => sub {
                my ($con, $err) = @_;
                if (defined $err) {
                    warn "connect error: $err\n";
                    exit 1 unless $self->{reconnect_interval};
                    sleep $self->{reconnect_interval};
                    $con->disconnect('try reconnect');
                } else {
                    warn 'connect';
                    $is_connect = 1;
                }
            },
            on_disconnect => sub {
                warn 'disconnect';
                # XXX: bad hack...
                undef $irc->{client};
                undef $irc->{SEND_TIMER};
                undef $irc;
                $is_connect = 0;
                $irc = $connector->();
            },
            channels => {
                map { my $chan = $_; $chan = '#'.$chan unless $chan =~ /^#/;  ;($chan => +{}) } @{ $self->{join_channels} || [] },
            };
    };
    $irc = $connector->();
    $self->{irc} = $irc;

    AnySan->register_listener(
        echo => {
            cb => sub {
                my $receive = shift;
                $receive->{message} = decode_utf8 $receive->{message};
                $self->_respond($receive);
            }
        }
    );

    $self;
}

sub on_message {
    my ($self, @jobs) = @_;
    while (my ($reg, $sub) = splice @jobs, 0, 2) {
        push @{ $self->_reactions }, [$reg, $sub];
    }
}

sub on_command {
    my ($self, @jobs) = @_;
    while (my ($command, $sub) = splice @jobs, 0, 2) {
        my $reg = _build_command_reg($self->{nickname}, $command);
        push @{ $self->_reactions }, [$reg, $sub, $command];
    }
}

sub _build_command_reg {
    my ($nick, $command) = @_;

    my $prefix = '^\s*'.quotemeta($nick). '_*[:\s]\s*' . quotemeta($command);
}

sub run {
    AnySan->run;
}

sub respond_all { shift->{respond_all} }

sub _reactions {
    shift->{_reactions} ||= [];
}

sub _respond {
    my ($self, $receive) = @_;

    my $message = $receive->message;
    $message =~ s/^\s+//; $message =~ s/\s+$//;
    for my $reaction (@{ $self->_reactions }) {
        my ($reg, $sub, $command) = @$reaction;

        if (my @matches = $message =~ $reg) {
            if (defined $command) {
                @matches = _build_command_args($reg, $message);
            }
            $sub->($receive, @matches);
            return unless $self->respond_all;
        }
    }
}

sub _build_command_args {
    my ($reg, $mes) = @_;
    $mes =~ s/$reg//;
    $mes =~ s/^\s+//; $mes =~ s/\s+$//;
    split /\s+/, $mes;
}

package # hide from pause
    AnySan::Receive;

use Encode qw/encode_utf8/;

sub reply {
    my ($self, $msg) = @_;
    $self->send_reply(encode_utf8 $msg);
}

1;
__END__

=encoding utf-8

=head1 NAME

UnazuSan - IRC reaction bot framework

=head1 SYNOPSIS

    use UnazuSan;
    my $unazu_san = UnazuSan->new(
        host       => 'example.com',
        password   => 'xxxxxxxx',
        enable_ssl => 1,
        join_channels => [qw/test/],
    );
    $unazu_san->on_message(
        qr/^unazu_san:/ => sub {
            my $receive = shift;
            $receive->reply('うんうん');
        },
        qr/(.)/ => sub {
            my ($receive, $match) = @_;
            say $match;
            say $receive->message;
        },
    );
    $unazu_san->on_command(
        help => sub {
            my ($receive, @args) = @_;
            $receive->reply('help '. ($args[0] || ''));
        }
    );
    $unazu_san->run;

=head1 DESCRIPTION

UnazuSan is IRC reaction bot framework.

B<THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.>

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut
