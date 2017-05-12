package DTS_UT::Model::UnitTestExec;

=pod

=head1 NAME

DTS_UT::Model::UnitTestExec - model implementation for MVC architeture

=head1 DESCRIPTION

C<DTS_UT::Model::UnitTestExec> is a model of MVC implementation of L<CGI::Application>. It executes the unit tests
and returns the values to the controller.

=cut

use DTS_UT::Test::Harness::Straps::NoExec;
use Params::Validate qw(validate_pos :types);
use base qw(Class::Accessor);
use DTS_UT::Model::UnitTest;

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(temp_dir ut_config));

=head2 EXPORTS

Nothing.

=head2 METHODS

=head3 new

Creates a new C<DTS_UT::Model::UnitTestExec> object.

Expects as parameters (in the following order):

=over

=item 1
complete pathname of the directory that will be used to hold temporary files.

=item 2
the YAML file used for unit test configuration.

=back

Returns a C<DTS_UT::Model::UnitTestExec> object.

=cut

sub new {

    validate_pos(
        @_,
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR }
    );

    my $class = shift;
    my $self = { temp_dir => shift, ut_config => shift };

    bless $self, $class;

    return $self;

}

=head3 run_tests

Execute the defined tests for one or more packages.

Expects as parameter an array reference with package(s) name(s) to test.

Returns an array reference with the following structure:

=begin text

	array reference -> [n] -> { 
		package      => package name
		ok           => tests that are OK
		max          => total number of tests executed
		failed       => total number of tests that failed
		failed_tests => array reference -> [n] = name of the test
	}

=end text

=begin html

<pre>

	array reference -> [n] -> { 
		package      => package name
		ok           => tests that are OK
		max          => total number of tests executed
		failed       => total number of tests that failed
		failed_tests => array reference -> [n] = name of the test
	}

</pre>

=end html

=cut

sub run_tests {

    validate_pos( @_, { type => HASHREF }, { type => ARRAYREF } );

    my $self     = shift;
    my $packages = shift;

    $yml_conf = Config::YAML->new( config => $self->get_ut_config() );

# :TODO:12/11/2008:arfreitas: check out if it's not possible to read configuration and processing properties directly.
# This should avoid cases where user and password is expected.
    my $strap = DTS_UT::Test::Harness::Straps::NoExec->new(
        DTS_UT::Model::UnitTest->new(
            $self->get_temp_dir(),
            {
                server => $yml_conf->get_server(),
                use_trusted_connection =>
                  $yml_conf->get_use_trusted_connection()
            }

        )
    );

    my @results;

    foreach my $package ( @{$packages} ) {

        my $results = $strap->analyze_file($package);

        if ( defined( $strap->{error} ) ) {

            die $strap->{error};

        }

        my @failed_tests;

        foreach my $test ( @{ $results->{details} } ) {

            push( @failed_tests, { test => $test->{name} } )
              unless ( $test->{ok} );

        }

        # :TRICKY:7/8/2008:arfreitas: could not find a better way to
        # catch errors when the script tests fails
        unless (( defined( $results->{ok} ) )
            and ( defined( $results->{seen} ) ) )
        {

            die "It was not possible to test $package: invalid test results";

        }
        else {

            push(
                @results,
                {
                    package      => $package,
                    ok           => $results->{ok},
                    max          => $results->{seen},
                    failed       => $results->{seen} - $results->{ok},
                    failed_tests => \@failed_tests
                }
            );

        }

    }

    return \@results;

}

=head1 SEE ALSO

=over

=item *
L<DTS_UT::Test::Harness::Straps::Parameter>

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
