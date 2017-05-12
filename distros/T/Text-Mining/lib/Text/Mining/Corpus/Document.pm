package Text::Mining::Corpus::Document;
use base qw(Text::Mining::Base);
use Class::Std;
use Class::Std::Utils;
use Text::Mining::Parser;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.8');

{
	my %document_id_of           : ATTR( :set<document_id> :get<document_id> );
	my %document_type_of         : ATTR( :set<document_type> :get<document_type> :default<> );
	my %corpus_id_of             : ATTR( :init_arg<corpus_id> :set<corpus_id> :get<corpus_id> :default<> );
	my %corpus_name_of           : ATTR( :set<corpus_name> :get<corpus_name> :default<> );
	my %submitted_by_user_id_of  : ATTR( :set<submitted_by_user_id> :get<submitted_by_user_id> :default<> );
	my %document_title_of        : ATTR( :set<document_title> :get<document_title> :default<> );
	my %document_url_of          : ATTR( :set<document_url> :get<document_url> :default<> );
	my %document_path_of         : ATTR( :set<document_path> :get<document_path> :default<> );
	my %file_name_of             : ATTR( :init_arg<file_name> :set<file_name> :get<file_name> :default<> );
	my %file_type_of             : ATTR( :init_arg<file_type> :set<file_type> :get<file_type> :default<> );
	my %bytes_of                 : ATTR( :set<bytes> :get<bytes> :default<> );
	my %enter_date_of            : ATTR( :set<enter_date> :get<enter_date> :default<> );
	my %exit_date_of             : ATTR( :set<exit_date> :get<exit_date> :default<> );

	sub BUILD {      
		my ($self, $ident, $arg_ref) = @_;

		return;
	}

	sub START {      
		my ($self, $ident, $arg_ref) = @_;
	               
		#print "  FILE TYPE: ", $self->get_file_type(), "\n\n";

		if    (defined $arg_ref->{document_id})        { $self->_get_document($arg_ref); }
		elsif (defined $arg_ref->{file_name})          { $self->insert( $arg_ref ); }

		return;
	}

	sub parse {
		my ( $self, $arg_ref )  = @_; 
		$arg_ref->{file_type}   = $self->get_document_type();
		$arg_ref->{file_name}   = $self->get_file_name();
		$arg_ref->{document_id} = $self->get_document_id();

		my $parser = Text::Mining::Parser->new( $arg_ref );
		
		print STDERR $parser->version(), "\n";
		print STDERR $parser->stats(), "\n";
		print STDERR $parser->parse(), "\n";

		my $document_id = $self->get_document_id();
		return $document_id; 
	}

#	sub get_id                    { my ($self)  = @_; return $id_of{ident $self}; }
#	sub get_document_id           { my ($self)  = @_; return $id_of{ident $self}; }
#	sub get_submitted_document_id { my ($self)  = @_; return $id_of{ident $self}; }
#	sub get_corpus_id             { my ($self)  = @_; return $corpus_id_of{ident $self}; }
#	sub get_submitted_by_user_id  { my ($self)  = @_; return $submitted_by_user_id_of{ident $self}; }
#	sub get_document_url          { my ($self)  = @_; return $document_url_of{ident $self}; }
#	sub get_document_path         { my ($self)  = @_; return $document_path_of{ident $self}; }
#	sub get_file_name    { my ($self)  = @_; return $file_name_of{ident $self}; }
#	sub get_enter_date            { my ($self)  = @_; return $enter_date_of{ident $self}; }
#	sub get_exit_date             { my ($self)  = @_; return $exit_date_of{ident $self}; }

	sub _get_document {
		my ($self, $arg_ref) = @_;
		my $ident = ident $self;

		my $sql  = "select document_id, document_type_id, corpus_id, document_path, document_file_name, bytes, enter_date ";
		   $sql .= "from documents ";
	   	   $sql .= "where document_id = '$arg_ref->{document_id}'";

		($document_id_of{$ident}, 
	   	 $document_type_of{$ident}, 
	   	 $corpus_id_of{$ident}, 
	   	 $document_path_of{$ident}, 
	   	 $file_name_of{$ident}, 
	   	 $bytes_of{$ident}, 
	   	 $enter_date_of{$ident}) = $self->library()->sqlexec($sql, '@');
	}

	sub all { 
		my ($self)  = @_; 
		my (@documents);

		my $sql  = "select document_id from documents order by document_id asc";
		my $documents = $self->library()->sqlexec( $sql, '\@@' );

		foreach my $document (@$documents) { push @documents, Text::Librarian::Document->new({ document_id => $document->[0] }); }

		return \@documents;
	}

	sub display_all { 
		my ($self, $c, $root_url)     = @_; 
		my @switch                    = (1, 0);
		my @classes                   = ('rowB', 'rowA');
		my $documents                      = Text::Librarian::Document->all();
		my ($html, $switch, $class);
	
		$html                        .= "<table width='800'> \n";
		$html                        .= "	<tr> \n";
		$html                        .= "		<td valign='top'> &nbsp; </td> \n";
		$html                        .= "		<td valign='top' class='head'>Name </td> \n";
		$html                        .= "		<td valign='top' class='head'>Description </td> \n";
		$html                        .= "		<td valign='top' class='head'>Path </td> \n";
		$html                        .= "	</tr> \n";
		foreach my $document (@$documents) {
			$switch               = $switch[$switch];
			$class                = $classes[$switch];
		        $html                .= "	<tr> \n";
			$html                .= "		<td valign='top'> <a href='javascript:if(confirm(\"Are you sure you want to delete this documentlication and its related roles and resources?\")){document.location.href=\"" . $root_url . "documents/documentlication_delete" . $document->get_document_id() . "\";}'>[X]</a> </td> \n";
			$html                .= "		<td valign='top' class='$class'> <a href='" . $root_url . "documents/document_edit" . $document->get_document_id() . "'> " . $document->get_name() . " </a> </td> \n";
			$html                .= "	        <td valign='top' class='$class'> " . $document->get_desc() . "</td> \n";
			$html                .= "	        <td valign='top' class='$class'> " . $document->get_path() . "</td> \n";
			$html                .= "	</tr> \n";
		}
		$html                        .= "</table> \n";
		return $html;
	}

	sub update {
		my ( $self, $arg_ref )   = @_; 
		my $ident       = ident $self;
		my @updates     = ();

		if ( defined $arg_ref->{corpus_id} )          { $self->set_desc( $arg_ref->{corpus_id} ); push @updates, "corpus_id = '" . $self->_html_to_sql( $arg_ref->{corpus_id} ) . "'"; }
		if ( defined $arg_ref->{document_path} )      { $self->set_path( $arg_ref->{document_path} ); push @updates, "document_path = '" . $self->_html_to_sql( $arg_ref->{document_path} ) . "'"; }
		if ( defined $arg_ref->{file_name} )          { $self->set_file_name( $arg_ref->{file_name} ); push @updates, "file_name = '" . $self->_html_to_sql( $arg_ref->{file_name} ) . "'"; }
		if ( defined $arg_ref->{bytes} )              { $self->set_desc( $arg_ref->{bytes} ); push @updates, "bytes = '" . $self->_html_to_sql( $arg_ref->{bytes} ) . "'"; }

		my $sql  = "update documents set " . join( ', ', @updates ) . " where document_id = '$document_id_of{$ident}'";
		$self->library()->sqlexec($sql);
	}

	sub insert {
		my ($self, $arg_ref)  = @_; 
		foreach ('corpus_id', 'document_title', 'document_path', 'file_name', 'bytes') { $arg_ref->{$_} = $self->_html_to_sql( $arg_ref->{$_} || '' ); }

		# Set doc_type_id : alpha - should be live or at least configured
		my %doc_types = ( txt => 1, xml => 2, pdf => 3 );
		$arg_ref->{document_type_id} = $doc_types{ $arg_ref->{file_type} };
	
		my $sql  = "insert into documents (document_type_id, corpus_id, document_title, document_path, document_file_name, bytes) ";
		   $sql .= "values ('$arg_ref->{document_type_id}', '$arg_ref->{corpus_id}', '$arg_ref->{document_title}', '$arg_ref->{document_path}', '$arg_ref->{file_name}', '$arg_ref->{bytes}') ";
		#print "\n", $sql, "\n\n";
		$self->library()->sqlexec($sql);

		   $sql  = "select LAST_INSERT_ID()";
		( $arg_ref->{document_id} ) = $self->library()->sqlexec($sql, '@');

		$self->_get_document( $arg_ref );
	}

	sub delete {
		my ( $self )  = @_; 
		my $ident             = ident $self;

		$self->library()->sqlexec("delete from documents where document_id = '" . $self->get_document_id() . "'");
	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Mining::Corpus::Document - Provenance and Representations for Documents


=head1 VERSION

This document describes Text::Mining::Corpus::Document version 0.0.8


=head1 SYNOPSIS

    use Text::Mining::Corpus::Document;

    my $wizard = CatalystX::Wizard->new({attribute => 'value'});

    print $wizard->get_attribute(), "\n";

    $wizard->set_attribute('new value');

    print $wizard->get_attribute(), "\n";

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


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
  
Text::Mining::Corpus::Document requires no configuration files or environment variables.


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
C<bug-text-mining-corpus-document@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Roger A Hall  C<< <rogerhall@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Roger A Hall C<< <rogerhall@cpan.org> >>. All rights reserved.

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
