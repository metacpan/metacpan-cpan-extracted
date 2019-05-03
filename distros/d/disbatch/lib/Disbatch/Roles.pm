package Disbatch::Roles;
$Disbatch::Roles::VERSION = '4.103';
use 5.12.0;
use warnings;

use Safe::Isa;
use Try::Tiny;

our @usernames = qw/ disbatchd disbatch_web task_runner queuebalance plugin /;

sub new {
    my $class = shift;
    my $self = { @_ };
    die "A MongoDB::Database object must be passed as 'db'" unless ref ($self->{db} // '') eq 'MongoDB::Database';
    die "Passwords for accounts must be passed as '", join("', '", @usernames), "'" unless scalar(grep { $self->{$_} ? 1 : 0 } @usernames) eq scalar @usernames;

    $self->{userroles} = {
        disbatchd => {
            password => $self->{disbatchd},
            privileges => [
                { resource => { db => $self->{db}{name}, collection => '' }, actions => [ 'find' ] },
                { resource => { db => $self->{db}{name}, collection => 'nodes' },  actions => [ 'insert', 'update', 'createIndex' ] },
                { resource => { db => $self->{db}{name}, collection => 'queues' },  actions => [ 'update', 'createIndex' ] },
                { resource => { db => $self->{db}{name}, collection => 'tasks' },  actions => [ 'update', 'createIndex' ] },
                { resource => { db => $self->{db}{name}, collection => 'tasks.chunks' },  actions => [ 'createIndex' ] },
                { resource => { db => $self->{db}{name}, collection => 'tasks.files' },  actions => [ 'createIndex' ] },
            ],
        },
        disbatch_web => {
            password => $self->{disbatch_web},
            privileges => [
                { resource => { db => $self->{db}{name}, collection => '' }, actions => [ 'find', 'listIndexes' ] },
                { resource => { db => $self->{db}{name}, collection => 'balance' },  actions => [ 'insert', 'update' ] },	# insert needed because 'upsert'
                { resource => { db => $self->{db}{name}, collection => 'nodes' },  actions => [ 'update' ] },
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
        queuebalance => {
            password => $self->{queuebalance},
            privileges => [
                { resource => { db => $self->{db}{name}, collection => 'balance' },  actions => [ 'find', 'insert', 'update' ] },
                { resource => { db => $self->{db}{name}, collection => 'queues' },  actions => [ 'find', 'update' ] },
                { resource => { db => $self->{db}{name}, collection => 'tasks' },  actions => [ 'find' ] },	# for count
            ],
        },
        plugin => {
            password => $self->{plugin},
            privileges => [ map { { resource => { db => $self->{db}{name}, collection => $_ }, actions => $self->{plugin_perms}{$_} } } keys %{$self->{plugin_perms}} ],
        },
    };
    die "CODE ERROR: Keys in \$self->{userroles} do not match values in \@usernames!" unless join(',', sort @usernames) eq join(',', sort keys %{$self->{userroles}});
    bless $self, $class;
}

sub add_additional_perms {
    my ($self, $name) = @_;
    if (defined $self->{additional_perms} and $self->{additional_perms}{$name}) {
        for my $collection (keys %{$self->{additional_perms}{$name}}) {
            my ($privilege) = grep { $_->{resource}{collection} eq $collection } @{$self->{userroles}{$name}{privileges}};
            if (!defined $privilege) {
                #warn "Adding new privilege to role '$name' for collection '$collection'";
                say "Adding new privilege to role '$name': collection '$collection', actions [ '", join("', '", @{$self->{additional_perms}{$name}{$collection}}), "' ]";
                $privilege = { resource => { db => $self->{db}{name}, collection => $collection },  actions => $self->{additional_perms}{$name}{$collection} };
                push @{$self->{userroles}{$name}{privileges}}, $privilege;
                next;
            }
            for my $action (@{$self->{additional_perms}{$name}{$collection}}) {
                if (grep { $action eq $_ } @{$privilege->{actions}}) {
                    #warn "Action '$action' already exists for role '$name' collection '$collection' privilege";
                    say "Privilege action '$action' already exists for '$collection' in role '$name'";
                } else {
                    #warn "Adding action '$action' to role '$name' collection '$collection' privilege";
                    say "Adding privilege action '$action' for '$collection' to role '$name'";
                    push @{$privilege->{actions}}, $action;
                }
            }
        }
    }
}

sub create_roles_and_users {
    my ($self) = @_;
    for my $name (keys %{$self->{userroles}}) {
        $self->add_additional_perms($name);
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

version 4.103

=head1 SUBROUTINES

=over 2

=item new

Parameters: C<< db => $db, plugin_perms => $plugin_perms, additional_perms => $additional_perms, disbatchd => $disbatchd_pw, disbatch_web => $disbatch_web_pw, task_runner => $task_runner_pw, queuebalance => queuebalance, plugin => $plugin_pw >>

  C<db> is a C<MongoDB::Database> object which must be authenticated with an accout having the C<root> role.
  C<plugin_perms> is a C<HASH> in the format of C<< { collection_name => array_of_actions, ... } >>, to give the plugin the needed permissions for MongoDB.
  C<additional_perms> a C<HASH> in the format of C<< role_name => {collection_name => array_of_actions, ...}, ... } >>, to set additional permissions for included roles.
  C<disbatchd>, C<disbatch_web>, C<task_runner>, C<queuebalance>, and C<plugin> are roles and users to create, with their values being their respective passwords.

Dies if invalid parameters.

=item add_additional_perms($name)

Parameters: name of the role to add additional privileges to.

Adds additional privileges to C<userroles> if C<additional_perms> was passed to C<new()>. See C<--additional_perms> in L<disbatch-create-users>.

Returns nothing.

=item create_roles_and_users

Parameters: none.

Creates the roles and users for C<disbatchd>, C<disbatch_web>, C<task_runner>, C<queuebalance>, and C<plugin>, after calling C<add_additional_perms()>.

Dies if the roles or users already exist, or on any other MongoDB error.

=item drop_roles_and_users

Parameters: none.

Drops the roles and users for C<disbatchd>, C<disbatch_web>, C<task_runner>, C<queuebalance>, and C<plugin>.

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

This software is Copyright (c) 2016, 2019 by Ashley Willis.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004
