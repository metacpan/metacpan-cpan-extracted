package DTS_UT::Model::UnitTest;

=pod

=head1 NAME

DTS_UT::Model::UnitTest - class that represents the test to be executed with DTS packages.

=head2 DESCRIPTION

C<DTS_UT::Model::UnitTest> is the test that will be executed again the desired DTS package(s).

This class is based in C<Test::More> and C<Test::Builder> features. C<Test::Builder> is specially necessary because 
of the methods C<output> and C<reset> that will change, respectivally, the default output (STDOUT) to a file and will 
reset the tests and results from previous execution.

The file where the output will be redirected is a temporary file (see L<File::Temp>) that will be removed as soon the 
test is finished and results read.

Since C<Test::Builder> object is a singleton, at the end of each test it's state must be reseted to start a new test
without changing it's results.

With such implementation, C<DTS_UT::Model::UnitTest> can be executed N times against DTS packages without exporting 
lots of subroutines of C<Test::More> into main namespace. By using a temporary file for test output, it can be used 
with environments like mod_perl once it avoids doing system calls by calling the perl program to execute the test and
read the output.

=head2 EXPORTS

Nothing.

=cut

use strict;
use warnings;
use Test::More;
use Win32::SqlServer::DTS::Application;
use File::Temp;

use base qw(Class::Accessor);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(temp_dir dtsapp flat_file_conns exec_pkgs));

=head2 METHODS

=head3 new

Expects as a parameter an hash reference like defined in L<Win32::SqlServer::DTS::Application>.

Returns a C<DTS_UT::Model::UnitTest> object.

=cut

sub new {

    my $class = shift;

    my $self = { temp_dir => shift, credential => shift };

    $self->{dtsapp} = Win32::SqlServer::DTS::Application->new( $self->{credential} );

    bless $self, $class;

    return $self;

}

=head3 run_test

Executes the test agains a given DTS package.

Expects as parameter the name of a DTS package.

Returns the complete pathname of the temporary file where the results of the test are written. B<Beware> that if the
C<DTS_UT::Model::UnitTest> goes out of scope (and it's reclaimed by garbage collector), the temporary file will be 
removed automatically!

=cut

sub run_test {

    my $self     = shift;
    my $pkg_name = shift;

    my $package = $self->get_dtsapp()->get_db_package(
        {
            id               => '',
            version_id       => '',
            name             => $pkg_name,
            package_password => ''
        }
    );

    $self->fetch_flat_file_conns($package);
    $self->fetch_execute_pkgs($package);

    my $test_builder = Test::More->builder();
    my $temp_file = File::Temp->new( DIR => $self->get_temp_dir() );

# keeps a reference until method run_test is called again or the object is destroyed. This will
# garantee that the temporary file will be removed when there are no more references to it.
    $self->{_tempfile} = $temp_file;

    $test_builder->output( $temp_file->filename() );

    #    $test_builder->failure_output( \*STDOUT );

    plan tests => $package->count_connections() + 6 +
      ( $package->count_execute_pkgs() * 2 ) +
      ( $package->count_datapumps() * 8 ) +
      ( ( scalar( @{ $self->get_flat_file_conns() } ) ) * 4 ) + 1;

    ok( !$package->log_to_server, 'Log to SQL Server should be disable' );
    ok( defined( $package->get_log_file ), 'Log to flat file is enable' );
    ok( !$package->use_event_log,
        'Write completion status on Event log should be disable' );
    ok(
        $package->use_explicit_global_vars,
        'Global variable are explicit declared'
    );
    cmp_ok( $package->count_connections, '>=', 2,
        'Package must have at least two connections' );
    cmp_ok( $package->count_datapumps, '>=', 1,
        'Package must have at least one datapump task' );

    $self->test_conn_auto_cfg($package);
    $self->test_datapumps($package);
    $self->test_execute_pkgs($package)
      if ( $package->count_execute_pkgs() > 0 );
    $self->test_flat_file_conns($package);
    $self->test_exec_pkg_auto_conf($package);
    $self->test_pkg_log_auto_conf($package);

    $test_builder->reset();

    return $temp_file->filename();

}

=head3 "Private" methods

=over

=item *
test_flat_file_conns

=item *
fetch_flat_file_conns

=item *
fetch_execute_pkgs

=item *
test_execute_pkgs

=item *
test_pkg_log_auto_conf

=item *
test_exec_pkg_auto_conf

=item *
test_datapumps

=item *
test_conn_auto_cfg

=item *
fetch_conns

=back

=cut

sub test_flat_file_conns {

    my $self    = shift;
    my $package = shift;
    my $conn_name;

    foreach my $conn ( @{ $self->get_flat_file_conns() } ) {

        $conn_name = 'Flat file connection "' . $conn->get_name() . '"';

        my $oledb = $conn->get_oledb();

        foreach my $prop_name ( keys( %{$oledb} ) ) {

          CASE: {

                if ( $oledb->{$prop_name}->{name} eq 'Row Delimiter' ) {

                    is( $oledb->{$prop_name}->{value},
                        "\r\n",
                        "$conn_name row delimiter must be CRLF characters" );
                    last CASE;

                }

                if ( $oledb->{$prop_name}->{name} eq 'Text Qualifier' ) {

                    is( $oledb->{$prop_name}->{value},
                        '', "$conn_name text qualifier should be empty" );
                    last CASE;

                }

                if ( $oledb->{$prop_name}->{name} eq 'Column Delimiter' ) {

                    is( $oledb->{$prop_name}->{value}, '|',
                        "$conn_name column delimiter must be a pipe character"
                    );
                    last CASE;

                }

                if ( $oledb->{$prop_name}->{name} eq 'File Type' ) {

                    is( $oledb->{$prop_name}->{value},
                        'ASCII', "$conn_name file enconding must be ASCII" );
                    last CASE;
                }

            }

        }

    }

}

sub fetch_flat_file_conns {

    my $self    = shift;
    my $package = shift;

    my @flat_file_conns;

    my $iterator = $package->get_connections();

    while ( my $conn = $iterator->() ) {

        push( @flat_file_conns, $conn )
          if ( $conn->get_provider() eq 'DTSFlatFile' );

    }

    $self->{flat_file_conns} = \@flat_file_conns;

}

sub fetch_execute_pkgs {

    my $self    = shift;
    my $package = shift;
    my @tasks_list;

    my $iterator = $package->get_execute_pkgs();

    while ( my $exec_pkg = $iterator->() ) {

        $exec_pkg->kill_sibling();
        push( @tasks_list, $exec_pkg );

    }

    $self->{exec_pkgs} = \@tasks_list;

}

sub test_execute_pkgs {

    my $self    = shift;
    my $package = shift;
    my $package_name;

    foreach my $execute_pkg ( @{ $self->get_exec_pkgs() } ) {

        $package_name =
          'Execute Package task "' . $execute_pkg->get_name() . '"';
        is( $execute_pkg->get_package_id(),
            '', "$package_name must have Package ID empty" );

    }

}

sub test_pkg_log_auto_conf {

    my $self          = shift;
    my $package       = shift;
    my $log_auto_conf = 0;

    my $dyn_iterator = $package->get_dynamic_props();

    while ( my $dyn_prop = $dyn_iterator->() ) {

        my $assign_iterator = $dyn_prop->get_assignments();

        while ( my $assignment = $assign_iterator->() ) {

            my $target = $assignment->get_destination();

            $log_auto_conf = 1
              if ( $target->changes('Package')
                and ( $target->get_destination() eq 'LogFileName' ) );

        }

    }

    ok( $log_auto_conf, 'Package log file configuration is automatic' );

}

sub test_exec_pkg_auto_conf {

    my $self    = shift;
    my $package = shift;

    my %exec_pkg_map;

    foreach my $exec_pkg ( @{ $self->get_exec_pkgs() } ) {

        $exec_pkg_map{ $exec_pkg->get_name() } =
          { ServerName => 0, ServerPassword => 0, ServerUserName => 0 };

    }

    my $dyn_iterator = $package->get_dynamic_props();

    while ( my $dyn_prop = $dyn_iterator->() ) {

        my $assign_iterator = $dyn_prop->get_assignments();

        while ( my $assignment = $assign_iterator->() ) {

            my $target = $assignment->get_destination();

            if ( $target->changes('Task') ) {

                if ( exists( $exec_pkg_map{ $target->get_taskname() } ) ) {

                  CASE: {

                        my $name = $target->get_taskname();
                        my $dest = $target->get_destination();

                        if ( $dest eq 'ServerName' ) {

                            $exec_pkg_map{$name}->{ServerName} = 1;
                            last CASE;

                        }

                        if ( $dest eq 'ServerPassword' ) {

                            $exec_pkg_map{$name}->{ServerPassword} = 1;
                            last CASE;
                        }

                        if ( $dest eq 'ServerUserName' ) {

                            $exec_pkg_map{$name}->{ServerUserName} = 1;
                            last CASE;

                        }

                    }

                }

            }

        }

    }

    foreach my $exec_pkg ( keys(%exec_pkg_map) ) {

        my $total;
        map { $total += $_; } ( values( %{ $exec_pkg_map{$exec_pkg} } ) );

        is( $total, 3,
                'Auto configuration is done for '
              . $exec_pkg
              . ' Execute Package task' );

    }

}

sub test_datapumps {

    my $self    = shift;
    my $package = shift;

    my $iterator = $package->get_datapumps();

    while ( my $datapump = $iterator->() ) {

        $datapump->kill_sibling();

        my $datapump_name = 'Datapump "' . $datapump->get_name() . '"';

        ok(
            (
                defined( $datapump->get_exception_file() )
                  and ( $datapump->get_exception_file() ne '' )
            ),
            $datapump_name . ' uses an exception file for logging'
        );
        ok( !$datapump->use_single_file_7(),
            $datapump_name
              . ' does not use SQL 7 file format for logging (warning)' );
        ok( defined( $datapump->use_source_row_file() ),
            $datapump_name . ' uses Source Row File logging (warning)' );
        ok( defined( $datapump->use_destination_row_file() ),
            $datapump_name . ' uses Destination Row File logging (warning)' );

        ok( $datapump->use_fast_load(),
            $datapump_name . ' uses Fast Load (warning)' );
        ok( $datapump->use_check_constraints(),
            $datapump_name . ' uses Check Constraints (warning)' );
        ok( $datapump->always_commit(),
            $datapump_name . ' uses Always Commit At Final Batch (warning)' );
        cmp_ok( $datapump->get_commit_size(),
            '>=', 1000,
            $datapump_name . ' uses Insert Commit Size >= 1000 (warning)' );

    }

}

sub test_conn_auto_cfg {

    my $self    = shift;
    my $package = shift;

    my $conns_ref = $self->fetch_conns( $package->get_connections() );

    my $dyn_iterator = $package->get_dynamic_props();

    while ( my $dyn_prop = $dyn_iterator->() ) {

        my $assign_iterator = $dyn_prop->get_assignments();

        while ( my $assignment = $assign_iterator->() ) {

            my $target = $assignment->get_destination();

            if ( $target->changes('Connection') ) {

                if ( exists( $conns_ref->{ $target->get_conn_name() } ) ) {

                    if ( $conns_ref->{ $target->get_conn_name() }->[0] eq
                        'SQLOLEDB' )
                    {

                      CASE: {

                            my $dest = $target->get_destination();
                            my $name = $target->get_conn_name();

                            if ( $dest eq 'Catalog' ) {

                                $conns_ref->{$name}->[2]->{catalog} = 1;
                                last CASE;

                            }

                            if ( $dest eq 'DataSource' ) {

                                $conns_ref->{$name}->[2]->{datasource} = 1;
                                last CASE;

                            }

                            if ( $dest eq 'UserID' ) {

                                $conns_ref->{$name}->[2]->{userid} = 1;
                                last CASE;

                            }

                            if ( $dest eq 'Password' ) {

                                $conns_ref->{$name}->[2]->{password} = 1;
                                last CASE;

                            }

                        }

                    }
                    else {

                        if ( $target->get_destination() eq 'DataSource' ) {

                            $conns_ref->{ $target->get_conn_name() }->[1] = 1;

                        }

                    }

                }

            }

        }

    }

    foreach my $conn ( keys %{$conns_ref} ) {

        if ( $conns_ref->{$conn}->[0] eq 'SQLOLEDB' ) {

            map { $conns_ref->{$conn}->[1] += $_ }
              values( %{ $conns_ref->{$conn}->[2] } );

            ( $conns_ref->{$conn}->[1] == 4 )
              ? ( $conns_ref->{$conn}->[1] = 1 )
              : ( $conns_ref->{$conn}->[1] = 0 );

        }

        ok( $conns_ref->{$conn}->[1],
"Connection \"$conn\" automatic configuration done by a Dynamic Property task"
        );

    }

}

sub fetch_conns {

    my $self     = shift;
    my $iterator = shift;
    my %conns;

    while ( my $conn = $iterator->() ) {

        $conns{ $conn->get_name() } = [ $conn->get_provider(), 0 ];

        if ( $conns{ $conn->get_name() }->[0] eq 'SQLOLEBD' ) {

            $conns{ $conn->get_name() }->[2] =
              { userid => 0, password => 0, datasource => 0, catalog => 0 }

        }

    }

    return \%conns;

}

=head1 SEE ALSO

=over

=item *
L<DTS_UT::Test::Harness::Straps::Parameter>

=item *
L<Win32::SqlServer::DTS::Application>

=item *
L<Test::More>

=item *
L<Test::Builder>

=item *
L<File::Temp>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
