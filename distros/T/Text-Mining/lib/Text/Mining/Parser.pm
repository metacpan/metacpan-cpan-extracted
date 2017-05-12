package Text::Mining::Parser;
use base qw(Text::Mining::Base);
use Class::Std;
use Class::Std::Utils;
use Module::Runtime qw(use_module);

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.8');

# Super alpha
our $parsers = { 1 => 'Text',
                 2 => 'PubMedCentral' };

{
	no warnings 'redefine';
	sub new {      
		my ($self, $arg_ref) = @_;
		return use_module('Text::Mining::Parser::' . $arg_ref->{parser}, 0.0.1)->new( $arg_ref );
	}

}

1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Mining::Parser - Flexible Parsers for Text Mining


=head1 VERSION

This document describes Text::Mining::Parser version 0.0.8


=head1 SYNOPSIS

To parse any document, you must first create a corpus object. 
(The corpus must have been created previously).

You have the option of creating it directly:

    use Text::Mining::Corpus;

    my $corpus   = Text::Mining::Corpus->new({ corpus_id => 1 });

Or you can create one from the $tm object, which is generally 
useful to have around in a text mining script.

    use Text::Mining;

    my $tm       = Text::Mining->new();
    my $corpus   = $tm->get_corpus({ corpus_id => 1 });

Additionally, you must also have a document object to pass to the 
parser. You can create a new one (by submitting a new document 
to the corpus) or retrieve a document already in the corpus.

    my $document = $corpus->submit_document({ document_id => 10 });
    my $document = $corpus->get_document({ document_id => 10 });

The main parser module is a "virtual constructor" and must be told 
what specific parser and token algorithm to use.

    use Text::Mining::Parser;

    my $parser   = Text::Mining::Parser->new({ parser    => 'Text', 
					       algorithm => 'Base' });
  
To parse a document, pass it to parse_document().

    $parser->parse_document({ document => $document }), "\n";

=head1 DESCRIPTION

The functionality of every Text::Mining::Parser is integrated with a 
specific corpus held between a MySQL database and the local file 
system. The primary design considerations are flexible usage and full 
token provenance in the face of ever-changing protocols and algorithms.

This module fronts interchangable parsers and algorithms which are developed by 
you as a Text::Mining system developer. They can be as generic 
as you want (like T_M_P::Text) or as specific as makes sense 
for a corpus import parser (like T_M_P::PubMedCentral). The parsers are 
responsible for dividing a document into parts: all_text, sections, paragraphs, 
and lines. The algorithms are designed to deal with each of these parts in turn. 
This allows us to use the same token handling scheme against both plain text and 
xml tagged documents.

=head1 INTERFACE 

The base module Text::Mining::Parser::Base defines all the methods of the 
parser, and each specific module overrides the base where desired.

The following is the effective interface of a specific parser. Please note 
that only the new() method is implemented in Text::Mining::Parser.

=head2 PUBLIC METHODS

These methods are called in scripts and other object's methods.

=over

=item * new()

Creates a parser using specific modules for parsing and token 
handling.

 my $parser = Text::Mining::Parser->new({ parser    => 'Text', 
					  algorithm => 'Base' });
  

=item * parse_document()

Completes a document parse. Depending on the parser, it may 
create a token list from the full text, mark tokens for 
proximity by section, paragraph, and line, or whatever you 
build a parser to do.

  $parser->parse_document({ document => $document });

The method calls each _get_<scope>() parser method and feeds 
the results to the appropriate algorithm _by_<scope>() method.

The all_text scope is simple:

  my $text = $self->_get_all_text();
  $algorithm->_by_text({ text => $text });

The algorithm would be expected to do whatever token harvesting 
is required in the _by_text() method (which is called first).

All other scopes are ordered lists of text, and use a while loop 
to complete the sequential processing of each.

  my $section = $self->_get_next_section();
  while (defined $section) { 
      $algorithm->_by_section({ section => $section }); 
      $section = $self->_get_next_section(); }

=item * stats()

Report parser and token metrics.

=back

=head2 PRIVATE METHODS

These methods are should not be called outside of the module. They 
are meant to support the Public Methods. They may be completely changed 
in any future revision.

=over

=item * _get_all_text()

This method should return the full text of the document.

=item * _get_next_section()

This method should return the next section of the document, 
starting with the first, and returning null when complete. 
This method uses an internal index which is set to 1 when 
the parser is created.

=item * _get_next_paragraph()

This method should return the next paragraph of the document, 
starting with the first, and returning null when complete. 
This method uses an internal index which is set to 1 when 
the parser is created.

=item * _get_next_line()

This method should return the next line of the document, 
starting with the first, and returning null when complete. 
This method uses an internal index which is set to 1 when 
the parser is created.

=item * _annotate()

This method adds an annotation to the token list for the 
document, noting the type and version of both parser and 
algorithm.

=item * _update_stats()

Marshalls and persists parser and token metrics.

=back

=head1 DIAGNOSTICS

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

Text::Mining::Parser requires no configuration files or environment variables.


=head1 DEPENDENCIES


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-mining-parser@rt.cpan.org>, or through the web interface at
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
