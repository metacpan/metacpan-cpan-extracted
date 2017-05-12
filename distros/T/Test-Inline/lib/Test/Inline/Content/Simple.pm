package Test::Inline::Content::Simple;

=pod

=head1 NAME

Test::Inline::Content::Simple - Simple templating Content Handler

=head1 SYNOPSIS

  In your inline2test.tpl
  ----------------------
  #!/usr/bin/perl -w
  
  use strict;
  use Test::More [% plan %];
  $| = 1;
  
  
  
  [% tests %]
  
  
  
  1;

=head1 DESCRIPTION

It is relatively common to want to customise the contents of the generated
test files to set up custom environment things on an all-scripts basis,
rather than file by file (using =begin SETUP blocks).

C<Test::Inline::Content::Simple> lets you use a very simple Template Toolkit
style template to define this information.

It contains only two tags, C<plan> and C<tests>.

The C<plan> tag will be inserted as either C<tests => 123> or C<'no_plan'>.

The C<tests> tag will be replaced by the actual testing code.

=head1 METHODS

=cut

use strict;
use File::Slurp  ();
use Params::Util qw{_INSTANCE};
use Test::Inline::Content ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '2.213';
	@ISA     = 'Test::Inline::Content';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new $filename

Manually create a new C<Test::Inline::Content::Simple> object. Takes as
parameter a single filename which should contain the template code.

Returns a new C<Test::Inline::Content::Simple> object, or C<undef> on error.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $file  = (defined $_[0] and -r $_[0]) ? shift : return undef;
	
	# Create the object
	my $self  = $class->SUPER::new() or return undef;

	# Load, check and add the file
	my $template = File::Slurp::read_file( $file ) or return undef;
	$template =~ /\[%\s+tests\s+\%\]/              or return undef;
	# $template =~ /\[\%\s+plan\s+\%\]/              or return undef;
	$self->{template} = $template;

	$self;
}

=pod

=head2 template

The C<template> accessor returns the template content for the object

=cut

sub template { $_[0]->{template} }





#####################################################################
# Test::Inline::Content Methods

=pod

=head2 process $Inline, $Script

The C<process> method is unchanged from C<Test::Inline::Content>.

=cut

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

	# Replace the two values
	my $script = $self->{template};
	$script =~ s/\[%\s+tests\s+\%\]/$content/;
	$script =~ s/\[\%\s+plan\s+\%\]/$plan/;

	$script;
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
