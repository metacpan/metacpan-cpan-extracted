package Text::Mining::Parser::PubMedCentral;
use base qw(Text::Mining::Base);
use Class::Std;
use Class::Std::Utils;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.8');

{
        sub version { return "Text::Mining::Parser::Text Version $VERSION"; }
	my %document_path_of          : ATTR( get => 'attribute', set => 'attribute' );
	my %document_id_of 	      : ATTR( get => 'attribute', set => 'attribute' );
	my %section_id_of 	      : ATTR( get => 'attribute', set => 'attribute' );
	my %paragraph_id_of 	      : ATTR( get => 'attribute', set => 'attribute' );
	my %sentence_id_of            : ATTR( get => 'attribute', set => 'attribute' );
	my %document_token_id_of      : ATTR( get => 'attribute', set => 'attribute' );
	
        sub BUILD {
                my ($self, $ident, $arg_ref) = @_;

                if    (defined $arg_ref->{document_id})        { $self->_get_document($arg_ref); }
                elsif (defined $arg_ref->{document_file_name}) { $self->insert( $arg_ref ); }

                return;
        }
	
	sub get_root_dir              { my ( $self ) = @_; return $self->_get_root_dir(); }
	
	sub _get_file_text {
		my( $self, $arg_ref ) = @_;
		
		my $text = do { local( @ARGV, $/ ) = $file ; <> } ;
		return $text;
	}
	
	sub parse_doc {
		my( $self, $arg_ref ) = @_;

		my $text = $self->_get_file_text();
	}

	sub parse_sentence {
		my( $self ) = @_;
	}

	sub parse_token {
		my( $self ) = @_;
	}
	
	sub text_to_file {
		my( $self ) = @_;
	}

	sub insert {
		my( $self ) = @_;
	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Mining::Parser::PubMedCentral - Parse XML documents from PubMed Central


=head1 VERSION

This document describes Text::Mining::Parser::PubMedCentral version 0.0.8


=head1 SYNOPSIS

    use Text::Mining;
    #use Text::Mining::Parser::PubMedCentral;

    my $tm = Text::Mining->new();

    my $corpus = $tm->get_corpus({ corpus_id => 1 });
    my $result = $corpus->add_dir({ dir    => '/home/user/data', 
                                    parser => 'PubMedCentral' });

  
  
=head1 DESCRIPTION

Parses XML formatted data from PubMed Central into 
Text::Mining::Corpus::Documents.

=head1 INTERFACE 


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Text::Mining::Parser::Text requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-mining-parser-text@rt.cpan.org>, or through the web interface at
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
