package Test::Inline::Content::Legacy;
# ABSTRACT: Test::Inline 2 Content Handler for legacy functions

#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod Custom script content generation using Test::Inline 2.000+ with a
#pod custom generator functions
#pod
#pod   my $header = "....";
#pod   my $function = sub {
#pod   	my $Object = shift;
#pod 	my $Script = shift;
#pod 	return $header . $Script->merged_content;
#pod   };
#pod   
#pod   my $Inline = Test::Inline->new(
#pod   	...
#pod   	file_content => $function,
#pod   	);
#pod
#pod Migrating this same code to Test::Inline 2.100+ ContentHandler objects
#pod
#pod   my $header = "....";
#pod   my $function = sub {
#pod   	my $Object = shift;
#pod 	my $Script = shift;
#pod 	return $header . $Script->merged_content;
#pod   };
#pod   
#pod   my $ContentHandler = Test::Inline::Content::Legacy->new( $function );
#pod   
#pod   my $Inline = Test::Inline->new(
#pod   	...
#pod   	ContentHandler => $ContentHandler,
#pod   	);
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class exists to provide a migration path for anyone using the custom
#pod script generators in Test::Inline via the C<file_content> param.
#pod
#pod The synopsis above pretty much says all you need to know.
#pod
#pod =head1 METHODS
#pod
#pod =cut

use strict;
use Params::Util          qw{_CODE _INSTANCE};
use Test::Inline::Content ();

our $VERSION = '2.214';
our @ISA     = 'Test::Inline::Content';

#pod =pod
#pod
#pod =head2 new $CODE_ref
#pod
#pod The C<new> constructor for C<Test::Inline::Content::Legacy> takes a single
#pod parameter of a C<CODE> reference, as you would have previously provided
#pod directly to C<file_content>.
#pod
#pod Returns a new C<Test::Inline::Content::Legacy> object, or C<undef> if not
#pod passed a C<CODE> reference.
#pod
#pod =cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $self  = $class->SUPER::new(@_);
	$self->{coderef} = _CODE(shift) or return undef;
	$self;
}

#pod =pod
#pod
#pod =head2 coderef
#pod
#pod The C<coderef> accessor returns the C<CODE> reference for the object
#pod
#pod =cut

sub coderef { $_[0]->{coderef} }

#pod =pod
#pod
#pod =head2 process $Inline $Script
#pod
#pod The C<process> method works with the legacy function by passing the
#pod L<Test::Inline> and L<Test::Inline::Script> arguments straight through
#pod to the legacy function, and returning it's result as the return value.
#pod
#pod =cut

sub process {
	my $self   = shift;
	my $Inline = _INSTANCE(shift, 'Test::Inline')         or return undef;
	my $Script = _INSTANCE(shift, 'Test::Inline::Script') or return undef;

	# Pass through the params, pass back the result
	$self->coderef->( $Inline, $Script );	
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Inline::Content::Legacy - Test::Inline 2 Content Handler for legacy functions

=head1 VERSION

version 2.214

=head1 SYNOPSIS

Custom script content generation using Test::Inline 2.000+ with a
custom generator functions

  my $header = "....";
  my $function = sub {
  	my $Object = shift;
	my $Script = shift;
	return $header . $Script->merged_content;
  };
  
  my $Inline = Test::Inline->new(
  	...
  	file_content => $function,
  	);

Migrating this same code to Test::Inline 2.100+ ContentHandler objects

  my $header = "....";
  my $function = sub {
  	my $Object = shift;
	my $Script = shift;
	return $header . $Script->merged_content;
  };
  
  my $ContentHandler = Test::Inline::Content::Legacy->new( $function );
  
  my $Inline = Test::Inline->new(
  	...
  	ContentHandler => $ContentHandler,
  	);

=head1 DESCRIPTION

This class exists to provide a migration path for anyone using the custom
script generators in Test::Inline via the C<file_content> param.

The synopsis above pretty much says all you need to know.

=head1 METHODS

=head2 new $CODE_ref

The C<new> constructor for C<Test::Inline::Content::Legacy> takes a single
parameter of a C<CODE> reference, as you would have previously provided
directly to C<file_content>.

Returns a new C<Test::Inline::Content::Legacy> object, or C<undef> if not
passed a C<CODE> reference.

=head2 coderef

The C<coderef> accessor returns the C<CODE> reference for the object

=head2 process $Inline $Script

The C<process> method works with the legacy function by passing the
L<Test::Inline> and L<Test::Inline::Script> arguments straight through
to the legacy function, and returning it's result as the return value.

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
