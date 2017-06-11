package WebService::Moodle::Simple::CLI;
$WebService::Moodle::Simple::CLI::VERSION = '0.06';
use strict;
use warnings;
use OptArgs;

# ABSTRACT: CLI for WebService::Moodle::Simple

opt help => (
    isa     => 'Bool',
    comment => 'print a help message and exit',
    ishelp  => 1,
);


arg command => (
    isa     => 'SubCmd',
    comment => 'sub command to run',
    required => 1,
);

opt domain => (
    isa     => 'Str',
    alias   => 'd',
    comment => 'something like moodle.server.name.com',
    default => sub { die '--domain [-d] - the moodle server like moodle.example.com is required' },
);

opt port => (
    isa     => 'Int',
    comment => '--port - The port on which the Moodle service listens',
    default => 443,
);

opt timeout => (
    isa     => 'Int',
    comment => '--timeout - Seconds we wait for the server to respond',
);

opt target => (
    isa     => 'Str',
    alias   => 't',
    comment => '--target [-t] - The name of the target Moodle service to access',
);

opt token => (
    isa      => 'Str',
    alias    => 'o',
    comment  => '--token [-o] - token (required)',
);

opt scheme => (
    isa     => 'Str',
    comment => '--scheme - The uri scheme - defaults to "https"',
);

subcmd (
    cmd     => 'add_user',
    comment => 'Create a Moodle user account',
);

opt username => (
    isa     => 'Str',
    alias   => 'u',
    comment => '--username [-u] - The Moodle username being created',
    default => sub { die '--username [-u] - username is required' },
);

opt firstname => (
    isa      => 'Str',
    alias    => 'f',
    comment  => '--firstname [-f] - user firstname',
    default => sub { die '--firstname [-f] - firstname is required' },
);

opt lastname => (
    isa      => 'Str',
    alias    => 'l',
    comment  => '--lastname [-l] - user lastname',
    default => sub { die '--lastname [-l] - lastname required' },
);

opt email => (
    isa      => 'Str',
    alias    => 'e',
    comment  => '--email [-e] - email (required)',
    default => sub { die '--email [-e] - email required' },
);


opt password => (
    isa      => 'Str',
    alias    => 'p',
    comment  => '--password [-p] - user password (required)',
    default => sub { die '--password [-p] - user password required' },
);

subcmd (
    cmd     => 'enrol',
    comment => 'Enrol student into a course',
);

opt username => (
    isa     => 'Str',
    alias   => 'u',
    comment => '--username [-u] - username being enrolled',
    default => sub { die '--username [-u] - username required' },
);

opt course => (
    isa     => 'Str',
    alias   => 'c',
    comment => '--course [-c] - The Moodle course being enrolled in',
    default => sub { die '--course required' },
);


subcmd (
    cmd     => 'set_password',
    comment => 'Update a user account password',
);

opt username => (
    isa     => 'Str',
    alias   => 'u',
    comment => '--username [-u] - username requiring a password reset',
    default => sub { die '--username [-u] - username required' },
);

opt password => (
    isa      => 'Str',
    alias    => 'p',
    comment  => '--password [-p] - user password',
    default => sub { die '--password [-p] - password required' },
);

subcmd (
    cmd     => 'suspend',
    comment => 'Suspend a user account',
);

opt username => (
    isa     => 'Str',
    alias   => 'u',
    comment => '--username [-u] - username of account to be suspended',
    default => sub { die '--username [-u] - username required' },
);

opt undo => (
    isa     => 'Bool',
    comment => '--undo un-suspend a user',
    default => 0,
);

subcmd (
    cmd => 'check_password',
    comment => 'Check that the username/password is a correct combination',
);

opt username => (
    isa     => 'Str',
    alias   => 'u',
    comment => '--username [-u] - the user of the password',
    default => sub { die '--username [-u] - username required' },
);

opt password => (
    isa      => 'Str',
    alias    => 'p',
    comment  => '--password [-p] - user password',
    default => sub { die '--password [-p] - password required' },
);

subcmd (
    cmd => 'get_user',
    comment => 'Get data about username',
);

opt username => (
    isa     => 'Str',
    alias   => 'u',
    comment => '--username [-u] - the user of the password',
    default => sub { die '--username [-u] - username required' },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Moodle::Simple::CLI - CLI for WebService::Moodle::Simple

=head1 VERSION

version 0.06

=head1 AUTHOR

Andrew Solomon

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Copyright 2014- Andrew Solomon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
