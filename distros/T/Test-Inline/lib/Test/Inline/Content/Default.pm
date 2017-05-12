package Test::Inline::Content::Default;

=pod

=head1 NAME

Test::Inline::Content::Default - Test::Inline 2 fallback/default Content Handler

=head1 DESCRIPTION

This class implements the default generator for script content. It generates
test script content inteded for use in a standard CPAN dist.

This module contains no user servicable parts.

=cut

use strict;
use Params::Util qw{_INSTANCE};
use Test::Inline::Content ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '2.213';
	@ISA = 'Test::Inline::Content';
}

sub process {
	my $self   = shift;
	my $Inline = _INSTANCE(shift, 'Test::Inline')         or return undef;
	my $Script = _INSTANCE(shift, 'Test::Inline::Script') or return undef;

	# Get the merged content
	my $content = $Script->merged_content;
	return undef unless defined $content;

	# Determine a plan
	my $tests = $Script->tests;
	my $plan  = defined $tests
		? "tests => $tests"
		: "'no_plan'";

	# Wrap the merged contents with the rest of the test
	# file infrastructure.
	my $file = <<"END_TEST";
#!/usr/bin/perl -w

use strict;
use Test::More $plan;
\$| = 1;



$content



1;
END_TEST

	$file;
}

1;

=pod

=head1 SUPPORT

See the main L<SUPPORT|Test::Inline/SUPPORT> section.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2004 - 2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
