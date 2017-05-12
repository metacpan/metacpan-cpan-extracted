package Unicorn::Manager::CLI::Proc::Table;

use Moo;
use Time::HiRes 'usleep';
use strict;
use warnings;
use autodie;
use 5.010;

use Unicorn::Manager::Types;

has ptable => (
    is  => 'rw',
    isa => Unicorn::Manager::Types::hashref,
);

sub BUILD {
    my $self = shift;
    $self->_parse_ps;
}

sub refresh {
    my $self = shift;
    return $self->_parse_ps;
}

# build a hash tree of the format
#
# {
#    uid => {
#        unicorn_master_pid => [
#            list_of_worker_pids,
#            {                                #
#                new_master_pid => [          # during graceful restart via SIGUSR2 and SIGWINCH
#                    list_of_new_worker_pids  #
#                ]                            #
#            }                                #
#        ]
#    }
# }
#
# TODO: ignore unicorn processes that are not daemonized
sub _parse_ps {
    my $self = shift;
    my @users;

    # grab the process table of unicorn_rails processes
    # build tree skeleton
    for (qx[ ps fauxn | grep unicorn_rails |grep -v grep ]) {
        ( undef, my $user, my $pid ) = split /\s+/, $_;
        push @users, { $user => $pid };
    }

    my $tree     = {};
    my $sub_tree = {};

    # walk over users with unicorn_rails processes running
    # and check which is worker and which is master
    # then place them inside of the tree
    #
    # build a subtree of processes that have grandparents to
    # sort them into the array of children in the next step
    for (@users) {
        my ( $uid, $current_pid ) = each %{$_};

        my $found_pid_status = 0;

        while ( not $found_pid_status ) {
            $found_pid_status = 1 if -f "/proc/$current_pid/status";

            # check every 1ms
            # TODO implement some timeout to prevent endless loop
            Time::HiRes::usleep 1000;
        }

        open my $fh, '<', "/proc/$current_pid/status";
        while (<$fh>) {

            if ( $_ =~ /PPid:\t\d+/ ) {
                my ( undef, $parent_pid ) = split /\s+/, $&;

                # ppid not equal to 1 means the process is a worker
                # or a new master
                if ( $parent_pid ne '1' ) {

                    open my $parent_fh, '<', "/proc/$parent_pid/status";
                    while (<$parent_fh>) {

                        if ( $_ =~ /PPid:\t\d+/ ) {
                            ( undef, my $parent_parent_pid ) = split /\s+/, $&;

                            # pppid not equal to one means the process
                            # has a grandparent and therefor is a new
                            # master or a new masters child
                            if ( $parent_parent_pid ne '1' ) {
                                push @{ $sub_tree->{$uid}->{$parent_parent_pid}->{$parent_pid} }, $current_pid;
                            }
                            else {
                                push @{ $tree->{$uid}->{$parent_pid} }, $current_pid;
                            }

                        }

                    }
                    close $parent_fh;

                }
            }
        }
        close $fh;

    }

    # build processes with grandparents into the tree
    for my $user ( keys %{$sub_tree} ) {
        for my $grandparent ( keys %{ $sub_tree->{$user} } ) {
            for my $parent ( keys %{ $sub_tree->{$user}->{$grandparent} } ) {

                my $i = 0;
                for ( @{ $tree->{$user}->{$grandparent} } ) {
                    if ( $parent == $_ ) {
                        ${ $tree->{$user}->{$grandparent} }[$i] = { $parent => $sub_tree->{$user}->{$grandparent}->{$parent} };
                    }
                    $i++;
                }
            }
        }
    }

    return $self->ptable($tree) ? 1 : 0;
}

1;

package Unicorn::Manager::CLI::Proc;

use Moo;
use JSON;
use strict;
use warnings;
use autodie;
use 5.010;

has process_table => ( is => 'rw', );

sub BUILD {
    my $self = shift;
    $self->process_table( Unicorn::Manager::CLI::Proc::Table->new );
}

sub refresh {
    my $self = shift;
    $self->process_table->refresh;
}

sub as_json {
    my $self = shift;

    my $json = JSON->new->utf8(1);

    return $json->encode( { $self->as_hash } );
}

sub as_hash {
    my $self      = shift;
    my $with_uids = shift;

    if ($with_uids) {
        return %{ $self->process_table->ptable };
    }
    else {
        return %{ $self->_replace_uid_with_name };
    }
}

sub _replace_uid_with_name {
    my $self = shift;

    my %user_table = %{ $self->process_table->ptable };

    my @users = keys %user_table;

    for (@users) {
        my $username = getpwuid $_;
        $user_table{$username} = $user_table{$_};
        delete $user_table{$_};
    }

    return {%user_table};
}

1;

__END__

=head1 NAME

Unicorn::Manager::CLI::Proc - Process table used by Unicorn::Manager

=head1 VERSION

Version 0.006009

=head1 SYNOPSIS

The Unicorn::Manager::CLI::Proc Module provides a table of unicorn processes.
Master/worker states are correctly represented.
The modules utilizes /proc and thus only works on Linux systems.

=head1 ATTRIBUTES/CONSTRUCTION

=head2 Construction

    my $uniman_proc = Unicorn::Manager::CLI::Proc->new;

=head2 process_table

Get the process table.

=head2 refresh

Refreshes the process table.

    $uniman_proc->refresh;

=head2 as_json

Return process table as json.

    my $json_text = $uniman_proc->as_json;

=head2 as_hash

Return process table as hash.

    my %hash_with_uids = $uniman_proc->as_hash(1);

    my %hash_with_usernames = $uniman_proc->as_hash;

=head1 AUTHOR

Mugen Kenichi, C<< <mugen.kenichi at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Unicorn::Manager issue tracker

L<https://github.com/mugenken/Unicorn/issues>

=item * support at uninets.eu

C<< <mugen.kenichi at uninets.eu> >>

=back

=head1 SUPPORT

=over 2

=item * Technical support

C<< <mugen.kenichi at uninets.eu> >>

=back

=cut


