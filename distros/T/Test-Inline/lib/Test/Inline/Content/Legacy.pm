package Test::Inline::Content::Legacy;

=pod

=head1 NAME

Test::Inline::Content::Legacy - Test::Inline 2 Content Handler for legacy functions

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

=cut

use strict;
use Params::Util          qw{_CODE _INSTANCE};
use Test::Inline::Content ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '2.213';
	@ISA     = 'Test::Inline::Content';
}

=pod

=head2 new $CODE_ref

The C<new> constructor for C<Test::Inline::Content::Legacy> takes a single
parameter of a C<CODE> reference, as you would have previously provided
directly to C<file_content>.

Returns a new C<Test::Inline::Content::Legacy> object, or C<undef> if not
passed a C<CODE> reference.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my $self  = $class->SUPER::new(@_);
	$self->{coderef} = _CODE(shift) or return undef;
	$self;
}

=pod

=head2 coderef

The C<coderef> accessor returns the C<CODE> reference for the object

=cut

sub coderef { $_[0]->{coderef} }

=pod

=head2 process $Inline $Script

The C<process> method works with the legacy function by passing the
L<Test::Inline> and L<Test::Inline::Script> arguments straight through
to the legacy function, and returning it's result as the return value.

=cut

sub process {
	my $self   = shift;
	my $Inline = _INSTANCE(shift, 'Test::Inline')         or return undef;
	my $Script = _INSTANCE(shift, 'Test::Inline::Script') or return undef;

	# Pass through the params, pass back the result
	$self->coderef->( $Inline, $Script );	
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
