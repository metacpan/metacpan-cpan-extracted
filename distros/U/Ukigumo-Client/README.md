[![Build Status](https://travis-ci.org/ukigumo/Ukigumo-Client.png?branch=master)](https://travis-ci.org/ukigumo/Ukigumo-Client)
# NAME

Ukigumo::Client - Client library for Ukigumo

# SYNOPSIS

    use Ukigumo::Client;
    use Ukigumo::Client::VC::Git;
    use Ukigumo::Client::Executor::Auto;
    use Ukigumo::Client::Notify::Debug;
    use Ukigumo::Client::Notify::Ikachan;

    my $app = Ukigumo::Client->new(
        vc   => Ukigumo::Client::VC::Git->new(
            branch     => $branch,
            repository => $repo,
        ),
        executor   => Ukigumo::Client::Executor::Perl->new(),
        server_url => $server_url,
        project    => $project,
    );
    $app->push_notifier(
        Ukigumo::Client::Notify::Ikachan->new(
            url     => $ikachan_url,
            channel => $ikachan_channel,
        )
    );
    $app->run();

# DESCRIPTION

Ukigumo::Client is client library for Ukigumo.

# ATTRIBUTES

- `workdir`

    Working directory for the code. It's `$ENV{HOME}/.ukigumo/work/$project/$branch` by default.

- `project`

    Its' project name. This is a mandatory parameter.

- `logfh`

    Log file handle. It's read only parameter.

- `server_url`

    URL of the Ukigumo server. It's required.

- `user_agent`

    instance of [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent). It's have a default value.

- `vc`

    This is a version controller object. It's normally Ukigumo::Client::VC::\*. But you can write your own class.

    VC::\* objects should have a following methods:

        get_revision branch repository

- `executor`

    This is a test executor object. It's normally Ukigumo::Client::Executor::\*. But you can write your own class.

- `notifiers`

    This is a arrayref of notifier object. It's normally Ukigumo::Client::Notify::\*. But you can write your own class.

- `compare_url`

    URL to compare differences between range of commitments.

- `elapsed_time_sec`

    Elapsed time as seconds about executing tests.

# METHODS

- $client->push\_notifier($notifier : Ukigumo::Client::Notify)

    push a notifier object to $client->notifiers.

- $client->run()

    Run a test context.

- $client->send\_to\_server($status: Int)

    Send a notification to the sever.

- reflect\_result($status: Int)

    Send a notification to the server and notify via registered notifier.

- $client->tee($command: Str)

    This method runs `$command` and tee the output of the STDOUT/STDERR to the `logfh`.

    _Return_: exit code by the `$command`.

- $client->logger->infof($message)

    Print `$message` as INFO and write to the `logfh`.

- $client->logger->warnf($message)

    Print `$message` as WARN and write to the `logfh`.

- $client->report\_timeout()

    This method always sends FAIL report to server and notifies to each notifiers.

# CONFIGURATION

If `.ukigumo.yml` file is on the project root, [Ukigumo::Client](https://metacpan.org/pod/Ukigumo::Client) loads that file and applies the settings that are written in it.

Please see also [ukigumo.yml.pod](https://metacpan.org/pod/ukigumo.yml.pod).

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

[Ukigumo::Server](https://metacpan.org/pod/Ukigumo::Server), [Ukigumo](https://github.com/ukigumo/)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
