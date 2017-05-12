# NAME

UnazuSan - IRC reaction bot framework

# SYNOPSIS

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

# DESCRIPTION

UnazuSan is IRC reaction bot framework.

__THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.__

# LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>
