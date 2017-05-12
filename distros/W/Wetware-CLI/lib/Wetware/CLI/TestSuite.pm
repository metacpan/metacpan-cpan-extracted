#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
package Wetware::CLI::TestSuite;

use strict;
use warnings;
use Wetware::Test::Suite;
use base q{Wetware::Test::Suite};

use Test::Differences qw();
use Test::More;
use Wetware::CLI;

#-----------------------------------------------------------------------------

sub class_under_test { return 'Wetware::CLI'; }

#-----------------------------------------------------------------------------

sub test_get_options: Test(3) {
    my $self    = shift;
    my $cli = $self->object_under_test();
    #Test::More::can_ok( $cli, 'get_options' );
    my @args = qw( --verbose );
    my $expected= { verbose => 1 };
    
    my $got = $cli->get_options(@args);
        
    Test::Differences::eq_or_diff_text( $got, $expected,
        'get_options() returns expected hash ref with verbose set' );
        
     my (%params, $bad_got);
    {
        # Now this is a bit 'over the top' - proving that
        # we visit the right things.
        ## no critic (ProhibitProlongedStrictureOverride)
        no strict qw(refs);       ## no critic (ProhibitNoStrict)
        no warnings qw(redefine); ## no critic (ProhibitNoWarnings)

        my $class = $self->class_under_test();

        # remember pod2usage has been imported in to the class_under_test
        my $method_name = $class . '::pod2usage';
        local *{$method_name} = sub { %params = @_; return; };
        
        my @badArgs = qw(--ReallyBadArg);
        {
            # because GetOptions will warn
        	local $SIG{__WARN__} = sub {};
        	$bad_got =  $cli->get_options(@badArgs);
        }
    }
    # this is a testability thing - since we have it doing a return on a
    # call to pod2usage() that will exit...
    Test::More::ok( ! $bad_got, 'get_options returns undef if GetOptions fail');
    my %expected_params = (
        -message => 'Error Parsing GetOptions',
        -exitval => 2);
        
    Test::Differences::eq_or_diff_text( \%params, \%expected_params,
        'get_options() returns expected params from pod2usaage' );
    return $self;
}

sub test_help_or_pod : Test(3) {
    my $self    = shift;
    my $cli = $self->object_under_test();
    my @args_passed;
    {
        # This is done with intent.
        # a lovely way to show that setting up sensor methods
        # can help make clear that the code does what is expected
        ## no critic (ProhibitProlongedStrictureOverride)
        no strict qw(refs);       ## no critic (ProhibitNoStrict)
        no warnings qw(redefine); ## no critic (ProhibitNoWarnings)

        my $class = $self->class_under_test();

        # remember pod2usage has been imported in to the class_under_test
        my $method_name = $class . '::pod2usage';
        local *{$method_name} = sub { @args_passed = @_; return; };
        my $options = {};
        $cli->help_or_pod($options);
        Test::More::ok(! @args_passed, 'help_or_pod does not visit pod2usage');
        
        $options = { 'help' => 1 };
        my $expected_help_count = 1; # only the exitval passed as a number
        $cli->help_or_pod($options);
        my $got_help_count = scalar @args_passed;
        Test::More::is($got_help_count, $expected_help_count, 'help_or_pod does for help');
        
        
        $options = { 'pod' => 1 };
        my $expected_pod_count = 2; # passes a single fat comma
        $cli->help_or_pod($options);
        my $got_pod_count = scalar @args_passed;
        Test::More::is($got_pod_count, $expected_pod_count, 'help_or_pod does for help');
	}
    return $self;
}
#-----------------------------------------------------------------------------

sub test_new : Test(1) {
    my $self           = shift;
    my $object         = $self->object_under_test();
    my $expected_class = $self->class_under_test();

    Test::More::isa_ok( $object, $expected_class );
    return $self;
}

#-----------------------------------------------------------------------------

sub test_option_defaults : Test(1) {
    my $self    = shift;
    my $cli = $self->object_under_test();
    #Test::More::can_ok( $cli, 'option_defaults' );
    my $expected ={};
    my $got = $cli->option_defaults();
    
    Test::Differences::eq_or_diff_text( $got, $expected,
        'option_defaults() returns expected empty hash' );
    return $self;
}

sub test_option_specifications : Test(1) {
    my $self    = shift;
    my $cli = $self->object_under_test();
    ##Test::More::can_ok( $cli, 'option_specifications' );
    my @expected = qw(
        verbose
        help
        pod
	);
	my @got = $cli->option_specifications();
	
    Test::Differences::eq_or_diff_text( \@got, \@expected,
        'option_specifications() returns expected list' );
    return $self;
}

sub test_required_settings : Test(1) {
    my $self    = shift;
    my $cli = $self->object_under_test();
    Test::More::can_ok( $cli, 'required_settings' );
    return $self;
}

sub test_verify_required_options: Test(3) {
    my $self    = shift;
    my $cli = $self->object_under_test();
    #Test::More::can_ok( $cli, 'verify_required_options' );
    my $visited_pod_to_usage;
    {
        # This is done with intent.
        # a lovely way to show that setting up sensor methods
        # can help make clear that the code does what is expected
        ## no critic (ProhibitProlongedStrictureOverride)
        no strict qw(refs);       ## no critic (ProhibitNoStrict)
        no warnings qw(redefine); ## no critic (ProhibitNoWarnings)

        my $class = $self->class_under_test();

        # remember pod2usage has been imported in to the class_under_test
        my $method_name = $class . '::pod2usage';
        local *{$method_name} = sub { $visited_pod_to_usage++; return; };
        
        # there are no required ones by default.
        my $options = {};
        $cli->verify_required_options($options);
        Test::More::ok(! $visited_pod_to_usage , 'verify_required_options default');
        
        # now to show that we will visit the pod2usage IF the required_attribute is not found.
        my $required_attribute = 'SuperSpecialTestRequiredAttributeStringLeastLikelyToBeFoundInTheWilds';
        my $required_settings =  $class . '::required_settings';
        local *{$required_settings} = sub { return $required_attribute };
        $cli->verify_required_options($options);
        Test::More::ok($visited_pod_to_usage , 'verify_required_options visits pod2usage');
        
        # now reset and recheck with the required attribute in the options.
        $visited_pod_to_usage = 0;
        $options->{$required_attribute} = 1;
        $cli->verify_required_options($options);
        Test::More::ok(! $visited_pod_to_usage , 'verify_required_options if option set');
        
    }
    return $self;
}

sub test_remaining_argv : Test(2) {
    my $self    = shift;
    my $cli = $self->object_under_test();
    #Test::More::can_ok( $cli, 'remaining_argv' );
    
    my $no_new_opt = { 'stuff' => 1 };
    my %expected_no_new_options = %{$no_new_opt};
    my @empty_argv;
    $cli->remaining_argv($no_new_opt, @empty_argv);
    
    Test::Differences::eq_or_diff_text( $no_new_opt, \%expected_no_new_options,
        'remaining_argv() no elements in @argv' );

    
    my $opt = { 'stuff' => 1 };
    my %expected_options = %{$opt};
    my $remaining_value = 'one_arg';
    $expected_options{'remaining_argv'} = [ $remaining_value ];
    my @argv = ( $remaining_value );
    $cli->remaining_argv($opt, @argv);
    
    Test::Differences::eq_or_diff_text( $opt, \%expected_options,
        'remaining_argv() at least one elements in @argv' );

    return $self;
}

#-----------------------------------------------------------------------------

1; 

__END__

=pod

=head1 NAME

Wetware::CLI::TestSuite - The CLI Test::Class

=head1 SYNOPSIS

This requires Wetware::Test distribution. It provides the basic
testing of the Modules.

=head1 OVERRIDDEN ETHODS

=head2 class_under_test()

=head1 TEST METHODS

We use the naming convention I<test_METHODNAME> for test methods.

=head2 test_get_options()

=head2 test_help_or_pod()

=head2 test_new()

=head2 test_option_defaults()

=head2 test_option_specifications()

=head2 test_required_settings()

=head2 test_verify_required_options()

=head2 test_verify_required_options()

=head2 test_remaining_argv()

=head1 COPYRIGHT & LICENSE

Copyright 2009 "drieux", all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# End of Wetware::CLI