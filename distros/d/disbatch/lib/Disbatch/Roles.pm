package Disbatch::Roles;
$Disbatch::Roles::VERSION = '3.990';
use 5.12.0;
use warnings;

use Safe::Isa;
use Try::Tiny;

sub new {
    my $class = shift;
    my $self = { @_ };
    die "A MongoDB::Database object must be passed as 'db'" unless ref ($self->{db} // '') eq 'MongoDB::Database';
    die "Passwords for accounts must be passed as 'disbatchd', 'disbatch_web', 'task_runner', and 'plugin'" unless $self->{disbatchd} and $self->{disbatch_web} and $self->{task_runner} and $self->{plugin};

    $self->{userroles} = {
        disbatchd => {
            password => $self->{disbatchd},
            privileges => [
                { resource => { db => $self->{db}{name}, collection => '' }, actions => [ 'find' ] },
                { resource => { db => $self->{db}{name}, collection => 'nodes' },  actions => [ 'find', 'insert', 'update', 'createIndex' ] },
                { resource => { db => $self->{db}{name}, collection => 'queues' },  actions => [ 'update', 'createIndex' ] },
                { resource => { db => $self->{db}{name}, collection => 'tasks' },  actions => [ 'update', 'createIndex' ] },
                { resource => { db => $self->{db}{name}, collection => 'tasks.chunks' },  actions => [ 'createIndex' ] },
                { resource => { db => $self->{db}{name}, collection => 'tasks.files' },  actions => [ 'createIndex' ] },
            ],
        },
        disbatch_web => {
            password => $self->{disbatch_web},
            privileges => [
                { resource => { db => $self->{db}{name}, collection => '' }, actions => [ 'find' ] },
                { resource => { db => $self->{db}{name}, collection => 'nodes' },  actions => [ 'find', 'update' ] },
                { resource => { db => $self->{db}{name}, collection => 'queues' },  actions => [ 'insert', 'update', 'remove' ] },
                { resource => { db => $self->{db}{name}, collection => 'tasks' },  actions => [ 'insert' ] },
            ],
        },
        task_runner => {
            password => $self->{task_runner},
            privileges => [
                { resource => { db => $self->{db}{name}, collection => '' }, actions => [ 'find' ] },
                { resource => { db => $self->{db}{name}, collection => 'queues' },  actions => [ 'update' ] },
                { resource => { db => $self->{db}{name}, collection => 'tasks' },  actions => [ 'update' ] },
                { resource => { db => $self->{db}{name}, collection => 'tasks.chunks' },  actions => [ 'insert' ] },
                { resource => { db => $self->{db}{name}, collection => 'tasks.files' },  actions => [ 'insert' ] },
            ],
        },
        plugin => {
            password => $self->{plugin},
            privileges => [ map { { resource => { db => $self->{db}{name}, collection => $_ }, actions => $self->{plugin_perms}{$_} } } keys %{$self->{plugin_perms}} ],
        },
    };
    bless $self, $class;
}

sub create_roles_and_users {
    my ($self) = @_;
    for my $name (keys %{$self->{userroles}}) {
        $self->{db}->run_command([createRole => $name, roles => [], privileges => $self->{userroles}{$name}{privileges} ]);
        $self->{db}->run_command([createUser => $name, pwd => $self->{userroles}{$name}{password}, roles => [ { role => $name, db => $self->{db}{name} } ]]);
    };
}

sub drop_roles_and_users {
    my ($self) = @_;
    for my $name (keys %{$self->{userroles}}) {
        try {
            $self->{db}->run_command([dropRole => $name]);
        } catch {
            # MongoDB::DatabaseError: No role named disbatch_web@disbatch
            if ($_->$_isa('MongoDB::DatabaseError') and $_->{message} =~ /^No role named $name\@$self->{db}{name}$/) {
                warn "$_->{message} (ignoring error)\n";
            } else {
                die $_;
            }
        };
        # User 'disbatch_web@disbatch' not found
        try {
            $self->{db}->run_command([dropUser => $name]);
        } catch {
            if ($_->$_isa('MongoDB::DatabaseError') and $_->{message} =~ /^User '$name\@$self->{db}{name}' not found$/) {
                warn "$_->{message} (ignoring error)\n";
            } else {
                die $_;
            }
        };
    };
}

1;

__END__

=encoding utf8

=head1 NAME

Disbatch::Roles - define and create MongoDB roles and users for Disbatch

=head1 VERSION

version 3.990

=head1 SUBROUTINES

=over 2

=item new

Parameters: C<< db => $db, plugin_perms => $plugin_perms, disbatchd => $disbatchd_pw, disbatch_web => $disbatch_web_pw, task_runner => $task_runner_pw, plugin => $plugin_pw >>

  C<db> is a C<MongoDB::Database> object which must be authenticated with an accout having the C<root> role.
  C<plugin_perms> is a C<HASH> in the format of C<< { collection_name => array_of_actions, ... } >>, to give the plugin the needed permissions for MongoDB.
  C<disbatchd>, C<disbatch_web>, C<task_runner>, and C<plugin> are roles and users to create, with their values being their respective passwords.

Dies if invalid parameters.

=item create_roles_and_users

Parameters: none.

Creates the roles and users for C<disbatchd>, C<disbatch_web>, C<task_runner>, and C<plugin>.

Dies if the roles or users already exist, or on any other MongoDB error.

=item drop_roles_and_users

Parameters: none.

Drops the roles and users for C<disbatchd>, C<disbatch_web>, C<task_runner>, and C<plugin>.

Dies if the roles or users don't exist(???), or on any other MongoDB error.

=back

=head1 SEE ALSO

L<Disbatch>

L<Disbatch::Web>

L<Disbatch::Plugin::Demo>

L<disbatchd>

L<disbatch.pl>

L<task_runner>

L<disbatch-create-users>

=head1 AUTHORS

Ashley Willis <awillis@synacor.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Ashley Willis.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004
