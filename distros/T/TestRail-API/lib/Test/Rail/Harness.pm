# ABSTRACT: TestRail testing harness
# PODNAME: Test::Rail::Harness
package Test::Rail::Harness;
$Test::Rail::Harness::VERSION = '0.044';
use strict;
use warnings;

use parent qw/TAP::Harness/;

# inject parser_class as Test::Rail::Parser.
sub new {
    my $class   = shift;
    my $arg_for = shift;
    $arg_for->{parser_class} = 'Test::Rail::Parser';
    my $self = $class->SUPER::new($arg_for);
    return $self;
}

sub make_parser {
    my ( $self, $job ) = @_;
    my $args     = $self->SUPER::_get_parser_args($job);
    my @configs  = ();
    my @sections = ();

    #XXX again, don't see any way of getting this downrange to my parser :(
    $args->{'apiurl'}   = $ENV{'TESTRAIL_APIURL'};
    $args->{'user'}     = $ENV{'TESTRAIL_USER'};
    $args->{'pass'}     = $ENV{'TESTRAIL_PASS'};
    $args->{'encoding'} = $ENV{'TESTRAIL_ENCODING'};
    $args->{'project'}  = $ENV{'TESTRAIL_PROJ'};
    $args->{'run'}      = $ENV{'TESTRAIL_RUN'};
    $args->{'plan'}     = $ENV{'TESTRAIL_PLAN'};
    @configs = split( /:/, $ENV{'TESTRAIL_CONFIGS'} )
      if $ENV{'TESTRAIL_CONFIGS'};
    $args->{'configs'} = \@configs if scalar(@configs);
    $args->{'result_options'} = { 'version' => $ENV{'TESTRAIL_VERSION'} }
      if $ENV{'TESTRAIL_VERSION'};
    $args->{'step_results'}    = $ENV{'TESTRAIL_STEPS'};
    $args->{'testsuite_id'}    = $ENV{'TESTRAIL_SPAWN'};
    $args->{'testsuite'}       = $ENV{'TESTRAIL_TESTSUITE'};
    $args->{'config_group'}    = $ENV{'TESTRAIL_CGROUP'};
    $args->{'test_bad_status'} = $ENV{'TESTRAIL_TBAD'};
    $args->{'max_tries'}       = $ENV{'TESTRAIL_MAX_TRIES'};

    @sections = split( /:/, $ENV{'TESTRAIL_SECTIONS'} )
      if $ENV{'TESTRAIL_SECTIONS'};
    $args->{'sections'} = \@sections if scalar(@sections);
    $args->{'autoclose'} = $ENV{'TESTRAIL_AUTOCLOSE'};

    #for Testability of plugin XXX probably some of the last remaining grotiness
    if ( $ENV{'TESTRAIL_MOCKED'} ) {
        use lib 't/lib'
          ;    #Unit tests will always run from the main dir during make test
        if ( !defined $Test::LWP::UserAgent::TestRailMock::mockObject ) {
            require 't/lib/Test/LWP/UserAgent/TestRailMock.pm';    ## no critic
        }
        $args->{'debug'}   = 1;
        $args->{'browser'} = $Test::LWP::UserAgent::TestRailMock::mockObject;
    }

    $self->SUPER::_make_callback( 'parser_args', $args, $job->as_array_ref );
    my $parser = $self->SUPER::_construct( $self->SUPER::parser_class, $args );

    $self->SUPER::_make_callback( 'made_parser', $parser, $job->as_array_ref );
    my $session =
      $self->SUPER::formatter->open_test( $job->description, $parser );

    return ( $parser, $session );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Rail::Harness - TestRail testing harness

=head1 VERSION

version 0.044

=head1 DESCRIPTION

Connective tissue for App::Prove::Plugin::TestRail.  Nothing to see here...

Subclass of TAP::Harness.

=head1 OVERRIDDEN METHODS

=head2 new

Tells the harness to use Test::Rail::Parser and passes off to the parent.

=head2 make_parser

Picks the arguments passed to App::Prove::Plugin::TestRail out of $ENV and shuttles them to it's constructor.

=head1 SEE ALSO

L<TestRail::API>

L<Test::Rail::Parser>

L<App::Prove>

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/TestRail-Perl>
and may be cloned from L<git://github.com/teodesian/TestRail-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
