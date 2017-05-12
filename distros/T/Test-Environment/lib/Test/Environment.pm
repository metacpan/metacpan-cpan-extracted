package Test::Environment;

=head1 NAME

Test::Environment - Base module for loading Test::Environment::Plugin::*

=head1 SYNOPSIS

	use Test::Environment qw{
		PostgreSQL
		Dump
	};
	
	# now we have 'psql', 'dump_with_name', ... functions in current namespace.
	# imported from Test::Environment::Plugin::PostreSQL and Test::Environment::Plugin::Dump

	eq_or_diff(
		[ psql(
			'switches' => '--expanded',
			'command'  => 'SELECT * FROM Table LEFT JOIN OtherTable USING (other_id) ORDER BY other_id;',
		) ],
		[ dump_with_name('test_01.dump') ],
		'check db loading',
	);

=head1 DESCRIPTION

This is the base module to load Test::Environment::Plugin::* modules.

Also sets:

	$ENV{'RUNNING_ENVIRONMENT'} = 'testing';

The basic idea is to call all the plugins you will need in your testing
script. The plugins will export their routines so you can use them in your tests
easily. By the $ENV{'RUNNING_ENVIRONMENT'} you can announce that you are running
in the testing mode to all the components of your tool. For example MyApp::Config
module can decide uppon the %ENV from where to run the configuration file. (for testing
look in t/conf/ instead of conf/ for ordinary usage)

=cut

use strict;
use warnings;

our $VERSION = "0.07";

use Carp::Clan;
use English '-no_match_vars';
use File::Basename;

BEGIN {
	$ENV{'RUNNING_ENVIRONMENT'} = 'testing';
}


=head1 FUNCTIONS

=head2 import()

Will load choosen Test::Environment::Plugin::? plugins.

=cut

sub import {
	my $package = shift;
	my @args    = @_;

	foreach my $plugin_name (@args) {
		croak 'bad plugin name' if $plugin_name !~ m{^\w+(::\w+)*$}xms;
		
		my $plugin_module_name = 'Test::Environment::Plugin::'.$plugin_name; 
		eval 'use '.$plugin_module_name.';';
		if ($EVAL_ERROR) {
			croak 'Failed to load "'.$plugin_module_name.'" - '.$EVAL_ERROR;
		}
	}
}

1;


=head1 SEE ALSO

Test::Environment::Plugin::* L<http://search.cpan.org/search?query=Test%3A%3AEnvironment%3A%3APlugin%3A%3A&mode=module>

=head1 AUTHOR

Jozef Kutej, E<lt>jkutej@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Jozef Kutej

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
