#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
package Wetware::Test::CreateTestSuite::TestSuite;

use strict;
use warnings;
use Wetware::Test::Suite;
use base q{Wetware::Test::Suite};

use Test::Differences qw();
use Test::More;
use Wetware::Test::CreateTestSuite;

#-----------------------------------------------------------------------------

sub class_under_test { return 'Wetware::Test::CreateTestSuite'; }

#-----------------------------------------------------------------------------

sub test_new : Test(1) {
    my $self           = shift;
    my $object         = $self->object_under_test();
    my $expected_class = $self->class_under_test();
    Test::More::isa_ok( $object, $expected_class );   
    return $self;
}

#-----------------------------------------------------------------------------

sub test_run  : Test(1) {
	my $self = shift;
	my $class = $self->class_under_test();
	Test::More::can_ok($class, 'run');
	return $self;
}
#-----------------------------------------------------------------------------

sub test_find_pm : Test(1) {
	my $self = shift;
	my $class = $self->class_under_test();
	Test::More::can_ok($class, 'find_pm');
	return $self;
}
#-----------------------------------------------------------------------------

sub test_is_testsuite  : Test(1) {
	my $self = shift;
	my $class = $self->class_under_test();
	Test::More::can_ok($class, 'is_testsuite');
	return $self;
}
#-----------------------------------------------------------------------------

sub test_has_testsuite  : Test(1) {
	my $self = shift;
	my $class = $self->class_under_test();
	Test::More::can_ok($class, 'has_testsuite');
	return $self;
}
#-----------------------------------------------------------------------------

sub test_parse_pm_file  : Test(1) {
	my $self = shift;
	my $class = $self->class_under_test();
	Test::More::can_ok($class, 'parse_pm_file');
	return $self;
}
#-----------------------------------------------------------------------------

sub test_write_testsuites_for  : Test(1) {
	my $self = shift;
	my $class = $self->class_under_test();
	Test::More::can_ok($class, 'write_testsuites_for');
	return $self;
}
#-----------------------------------------------------------------------------

sub test_write_t_dir_files  : Test(1) {
	my $self = shift;
	my $class = $self->class_under_test();
	Test::More::can_ok($class, 'write_t_dir_files');
	return $self;
}
#-----------------------------------------------------------------------------

sub test_content_for_test_class_t  : Test(1) {
	my $self = shift;
	my $class = $self->class_under_test();
	Test::More::can_ok($class, 'content_for_test_class_t');
	return $self;
}
#-----------------------------------------------------------------------------

sub test_content_for_compile_pm_t  : Test(1) {
	my $self = shift;
	my $class = $self->class_under_test();
	Test::More::can_ok($class, 'content_for_compile_pm_t');
	return $self;
}
#-----------------------------------------------------------------------------

sub test_content_for_pod_coverage_t  : Test(1) {
	my $self = shift;
	my $class = $self->class_under_test();
	Test::More::can_ok($class, 'content_for_pod_coverage_t');
	return $self;
}
#-----------------------------------------------------------------------------

sub test_search_dir  : Test(1) {
	my $self = shift;
    my $object         = $self->object_under_test();
	my $expected = q{./lib};
	my $got = $object->search_dir();
	Test::More::is($got,$expected, 'search_dir');
	return $self;
}
#-----------------------------------------------------------------------------

sub test_t_dir  : Test(1) {
	my $self = shift;
    my $object         = $self->object_under_test();
	my $expected = q{./t};
	my $got = $object->t_dir();
	Test::More::is($got,$expected, 't_dir');
	return $self;
}

#-----------------------------------------------------------------------------

sub test_overwrite_t_files  : Test(1) {
	my $self = shift;
	my $class = $self->class_under_test();
	Test::More::can_ok($class, 'overwrite_t_files');
	return $self;
}

#-----------------------------------------------------------------------------

# sub test_new_method_name  : Test(1) {
# 	my $self = shift;
# 	my $class = $self->class_under_test();
# 	Test::More::can_ok($class, 'new_method_name');
# 	return $self;
# }

#-----------------------------------------------------------------------------

1; 

__END__

=pod

=head1 NAME

Wetware::Test::CreateTestSuite::TestSuite - The CLI Test::Class

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