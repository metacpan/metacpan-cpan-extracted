package XML::LibXML::Devel::SetLineNumber;

use 5.008003;
use strict;
use warnings;

use XML::LibXML;
use XML::LibXML::Devel;

our $AUTHORITY  = 'cpan:TOBYINK';
our $VERSION    = '0.002';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = our @EXPORT = qw(set_line_number);

our %EXPORT_TAGS = (
	all     => \@EXPORT_OK,
	default => \@EXPORT,
	);

require XSLoader;
XSLoader::load('XML::LibXML::Devel::SetLineNumber', $VERSION);

sub set_line_number
{
	my ($node, $line) = @_;
	_set_line_number($node, $line);
}

__PACKAGE__
__END__

=head1 NAME

XML::LibXML::Devel::SetLineNumber - set the line number for an XML::LibXML::Node

=head1 SYNOPSIS

  use XML::LibXML::Devel::SetLineNumber;
  
  my $node = $document->getElementsByTagName('foo')->get_node(1);
  set_line_number($node, 8);
  say $node->line_number;  # says "8"

=head1 DESCRIPTION

This module exports one function:

=over

=item C<< set_line_number($node, $number) >>

Sets a node's line number.

=back

Why in name of all that is good and holy would you want to do that?
Frankly, you probably don't. And you probably shouldn't.

There's just about one sitution where it makes sense. If you are,
say, writing a parser for a non-XML format that happens to have an
XML-like data model, then you might wish to parse your format into
an XML::LibXML document with elements, attributes and so on. And
you might want all those nodes to return the correct line numbers
when the C<line_number> method is called on them. Say, for
instance that you're working on L<HTML::HTML5::Parser>.

=head1 THIS MODULE IS WELL DODGY

And you're a fool if you use it.

If you do feel you really must use this module, it's probably best to
load it like this:

 eval {
   require XML::LibXML::Devel::SetLineNumber;
   import XML::LibXML::Devel::SetLineNumber;
   1;
 } or *set_line_number = sub { 1 };

Instead of the normal C<< use XML::LibXML::Devel::SetLineNumber >>.

=head1 SEE ALSO

L<XML::LibXML>,
L<XML::LibXML::Devel>,
L<XML::LibXML::Node>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
