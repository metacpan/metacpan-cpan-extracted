package Text::Mining::Parser::Base;
use base qw(Text::Mining::Base);
use Class::Std;
use Class::Std::Utils;
use Module::Runtime qw(use_module);

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.8');

{
	my %document_of      : ATTR( get => 'document', set => 'document' );
	my %token_list_of    : ATTR( get => 'token_list', set => 'token_list' );
	my %algorithm_of     : ATTR( get => 'algorithm', set => 'algorithm' );
	my %section_ndx_of   : ATTR( default => 1, get => 'section_ndx', set => 'section_ndx' );
	my %paragraph_ndx_of : ATTR( default => 1, get => 'paragraph_ndx', set => 'paragraph_ndx' );
	my %line_ndx_of      : ATTR( default => 1, get => 'line_ndx', set => 'line_ndx' );

	sub version { return "Text::Mining::Parser::Base Version $VERSION"; }

	sub BUILD {      
		my ($self, $ident, $arg_ref) = @_;

		my $algorithm = use_module('Text::Mining::Algorithm::' . $arg_ref->{algorithm}, 0.0.1)->new( $arg_ref );
		$self->set_algorithm( $algorithm );

		return;
	}

	sub parse_document() {
		my ($self, $arg_ref) = @_;

		# Check for new document, get document
		if (defined $arg_ref->{document}) { $self->set_document( $arg_ref->{document} ); }
		my $document  = $self->get_document();

		my $algorithm = $self->get_algorithm();

		# This design assumes text will fit in a scalar. Will probably need 
		# a handle-based method using random access.

		# PD: Parse and process the entire text
		my $text = $self->_get_all_text();
		$algorithm->_by_text({ text => $text });

		# PD: Parse and process each document section
		my $section = $self->_get_next_section();
		while (defined $section) { $algorithm->_by_section({ section => $section }); $section = $self->_get_next_section(); }

		# PD: Parse and process each document paragraph
		my $paragraph = $self->_get_next_paragraph();
		while (defined $paragraph) { $algorithm->_by_paragraph({ paragraph => $paragraph }); $paragraph = $self->_get_next_paragraph(); }
	
		# PD: Parse and process each document line
		my $line = $self->_get_next_line();
		while (defined $line) { $algorithm->_by_line({ line => $line }); $line = $self->_get_next_line(); }

		# PD: Annotate the token list
		#$self->_annotate();

		return;
	}

	sub parse {      
		my ($self, $arg_ref) = @_;

		use Text::Mining::Algorithm::AllTokens;

		my $text = $self->_get_file_text( $self->get_file_name() );
		my $algorithm = Text::Mining::Algorithm::AllTokens->new();
		my $tokens = $algorithm->harvest_tokens( $arg_ref );

		return $tokens;
	}

	sub stats {      
		my ($self, $arg_ref) = @_;

		my $text = $self->_get_file_text( $self->get_file_name() );
		my @lines     = split(/\n/, $text);
		my @sentences = split(/\./, $text);
		my @tokens    = split(/\s+/, $text);

		return " Lines: " . scalar( @lines) . ";",
		       " Sentences: " . scalar( @sentences) . ";",
		       " Tokens: " . scalar( @tokens) . ";";
	}

	sub _get_all_text() {
		my ($self, $arg_ref) = @_;
		return;
	}

	sub _get_next_section() {
		my ($self, $arg_ref) = @_;
		return;
	}

	sub _get_next_paragraph() {
		my ($self, $arg_ref) = @_;
		return;
	}

	sub _get_next_line() {
		my ($self, $arg_ref) = @_;
		return;
	}

	sub _update_stats() {
		my ($self, $arg_ref) = @_;
		return;
	}

	sub _annotate() {
		my ($self, $arg_ref) = @_;
		my $algorithm = $self->get_algorithm();

		$self->get_document()->annotate({ type => 'parser', value => $self->version() });
		$self->get_document()->annotate({ type => 'algorithm', value => $algorithm->version() });
		return;
	}

}

1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Mining::Parser::Base - Flexible Parsers for Text Mining


=head1 VERSION

This document describes Text::Mining::Parser::Base version 0.0.8


=head1 SYNOPSIS

See L<Text::Mining::Parser|http://search.cpan.org/~rogerhall/Text-Mining/lib/Text/Mining/Parser.pm>
  
=head1 DESCRIPTION

This is the base module for parsers. It implements each parse method with nulls returned. 
To create a new parser, create a new module in the same directory, use this module 
as a base, and implement one or more _get_<scope>() methods.

=head1 INTERFACE 


=head1 DEPENDENCIES


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-mining-parser-base@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHORS

Roger A Hall  C<< <rogerhall@cpan.org> >>
Michael Bauer  C<< <mbkodos@gmail.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, the Authors. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
