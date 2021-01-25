package Test::Inline::Content::Simple;
# ABSTRACT: Simple templating Content Handler

#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod   In your inline2test.tpl
#pod   ----------------------
#pod   #!/usr/bin/perl -w
#pod   
#pod   use strict;
#pod   use Test::More [% plan %];
#pod   $| = 1;
#pod   
#pod   
#pod   
#pod   [% tests %]
#pod   
#pod   
#pod   
#pod   1;
#pod
#pod =head1 DESCRIPTION
#pod
#pod It is relatively common to want to customise the contents of the generated
#pod test files to set up custom environment things on an all-scripts basis,
#pod rather than file by file (using =begin SETUP blocks).
#pod
#pod C<Test::Inline::Content::Simple> lets you use a very simple Template Toolkit
#pod style template to define this information.
#pod
#pod It contains only two tags, C<plan> and C<tests>.
#pod
#pod The C<plan> tag will be inserted as either C<tests => 123> or C<'no_plan'>.
#pod
#pod The C<tests> tag will be replaced by the actual testing code.
#pod
#pod =head1 METHODS
#pod
#pod =cut

use strict;
use Path::Tiny ();
use Params::Util qw{_INSTANCE};
use Test::Inline::Content ();

our $VERSION = '2.214';
our @ISA     = 'Test::Inline::Content';





#####################################################################
# Constructor and Accessors

#pod =pod
#pod
#pod =head2 new $filename
#pod
#pod Manually create a new C<Test::Inline::Content::Simple> object. Takes as
#pod parameter a single filename which should contain the template code.
#pod
#pod Returns a new C<Test::Inline::Content::Simple> object, or C<undef> on error.
#pod
#pod =cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $file  = (defined $_[0] and -r $_[0]) ? shift : return undef;
	
	# Create the object
	my $self  = $class->SUPER::new() or return undef;

	# Load, check and add the file
	my $template = Path::Tiny::path($file)->slurp or return undef;
	$template =~ /\[%\s+tests\s+\%\]/              or return undef;
	# $template =~ /\[\%\s+plan\s+\%\]/              or return undef;
	$self->{template} = $template;

	$self;
}

#pod =pod
#pod
#pod =head2 template
#pod
#pod The C<template> accessor returns the template content for the object
#pod
#pod =cut

sub template { $_[0]->{template} }





#####################################################################
# Test::Inline::Content Methods

#pod =pod
#pod
#pod =head2 process $Inline, $Script
#pod
#pod The C<process> method is unchanged from C<Test::Inline::Content>.
#pod
#pod =cut

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Inline::Content::Simple - Simple templating Content Handler

=head1 VERSION

version 2.214

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

=head2 new $filename

Manually create a new C<Test::Inline::Content::Simple> object. Takes as
parameter a single filename which should contain the template code.

Returns a new C<Test::Inline::Content::Simple> object, or C<undef> on error.

=head2 template

The C<template> accessor returns the template content for the object

=head2 process $Inline, $Script

The C<process> method is unchanged from C<Test::Inline::Content>.

=head1 SUPPORT

See the main L<SUPPORT|Test::Inline/SUPPORT> section.

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Inline>
(or L<bug-Test-Inline@rt.cpan.org|mailto:bug-Test-Inline@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
