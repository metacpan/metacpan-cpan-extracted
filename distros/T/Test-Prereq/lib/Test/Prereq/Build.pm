package Test::Prereq::Build;
use strict;

use parent qw(Test::Prereq);
use vars qw($VERSION @EXPORT);

use warnings;
no warnings;

=encoding utf8

=head1 NAME

Test::Prereq::Build - test prerequisites in Module::Build scripts

=head1 SYNOPSIS

   use Test::Prereq::Build;
   prereq_ok();

=cut

$VERSION = '2.005';

use Module::Build;

my $Test = __PACKAGE__->builder;

=head1 METHODS

If you have problems, send me your F<Build.PL>.

This module overrides methods in C<Test::Prereq> to make it work with
C<Module::Build>.

This module does not have any public methods. See L<Test::Prereq>.

To make everything work out with C<Module::Build>, this module overrides
some methods to do nothing.

=over 4

=item create_build_script

=item add_build_element

=item args

=item notes

=back

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


sub import
	{
	my $self   = shift;
	my $caller = caller;
	no strict 'refs';
	*{$caller.'::prereq_ok'}       = \&prereq_ok;

	$Test->exported_to($caller);
	$Test->plan(@_);
	}

sub prereq_ok
	{
	$Test->plan( tests => 1 ) unless $Test->has_plan;
	__PACKAGE__->_prereq_check( @_ );
	}

sub _master_file { 'Build.PL' }

# override Module::Build
sub Module::Build::new {
	my $class = shift;

	my %hash = @_;

	my @requires = sort grep $_ ne 'perl', (
		keys %{ $hash{requires} },
		keys %{ $hash{build_requires} },
		keys %{ $hash{test_requires} },
		keys %{ $hash{configure_requires} },
		keys %{ $hash{recommends} },
		);

	@Test::Prereq::prereqs = @requires;

	# intercept further calls to this object
	return bless {}, __PACKAGE__;
	}

# fake Module::Build methods
sub create_build_script { 1 };
sub add_build_element { 1 };
sub args { 1 };
sub notes { 1 };

1;
