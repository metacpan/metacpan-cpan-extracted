=head1 NAME

XML::Writer::String - Capture output from XML::Writer.

=cut

package XML::Writer::String;
require 5.004;
use warnings;
use strict;

$XML::Writer::String::VERSION = 0.1;

sub new {
	my $class = shift;
	my $scalar = '';
	my $self = bless \$scalar, $class;
	$self->value(@_) if @_;
	return $self;
}

sub print {
	my $self = shift;
	${$self} .= join '', @_;
	return scalar(@_);
}

sub value {
	my $self = shift;
	@_ ? ${$self} = join('', @_)
	   : ${$self};
}

1;

__END__

=head1 SYNOPSIS

  use XML::Writer;
  use XML::Writer::String;

  my $s = XML::Writer::String->new();
  my $writer = new XML::Writer( OUTPUT => $s );

  $writer->xmlDecl();
  $writer->startTag('root');
  $writer->endTag();
  $writer->end();

  print $s->value();

=head1 DESCRIPTION

This module implements a bare-bones class specifically for the purpose 
of capturing data from the XML::Writer module.  XML::Writer expects an 
IO::Handle object and writes XML data to the specified object (or STDOUT) 
via it's print() method.  This module simulates such an object for the 
specific purpose of providing the required print() method.

It is recommended that $writer->end() is called prior to calling $s->value() 
to check for well-formedness.

=head1 METHODS

XML::Writer::String provides three methods, C<new()>, C<print()> and 
C<value()>:

=over

=item C<$s = XML::Writer::String->new([list]);>

new() returns a new String handle.

=item C<$count = $s->print([list]);>

print() appends concatenated list data and returns number of items in list.

=item C<$val = $s->value([list]);>

value() returns the current content of the object as a scalar.  It can also be used to 
initialize/overwrite the current content with concatenated list data.

=back

=head1 NOTES

This module is designed for the specific purpose of capturing the output of XML::Writer 
objects, as described in this document.  It does not inherit form IO::Handle.  For an 
alternative solution look at IO::Scalar, IO::Lines, IO::String or Tie::Handle::Scalar.

=head1 AUTHOR

Simon Oliver <simon.oliver@umist.ac.uk>

=head1 COPYRIGHT

Copyright (C) 2002 Simon Oliver

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<XML::Writer>, L<IO::Handle>, L<IO::Scalar>

=cut
