package Text::Mining;
use base qw(Text::Mining::Base);
use Class::Std;
use Class::Std::Utils;
use Text::Mining::Corpus;
use Text::Mining::Corpus::Document;
use Text::Mining::Shell;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.8');

{
	my %attribute_of : ATTR( get => 'attribute', set => 'attribute' );
	
	sub BUILD {      
		my ($self, $ident, $arg_ref) = @_;
	               
	#	&DBConnect( %{ $self->_library_connect_parameters() } );

		return;
	}

	sub shell { my $shell = Text::Mining::Shell->new(); $shell->cmdloop(); }
	sub version { return "VERSION $VERSION"; }

	sub create_corpus             { my ( $self, $arg_ref ) = @_; return Text::Mining::Corpus->new( $arg_ref ); }
	sub get_corpus                { my ( $self, $arg_ref ) = @_; return Text::Mining::Corpus->new( $arg_ref ); }
	sub delete_corpus             { my ( $self, $arg_ref ) = @_; my $corpus = Text::Mining::Corpus->new(); return $corpus->delete( $arg_ref ); }

	sub get_root_dir              { my ( $self ) = @_; return $self->_get_root_dir(); }
	sub get_root_url              { my ( $self ) = @_; return $self->_get_root_url(); }
	sub get_data_dir              { my ( $self, $corpus_id ) = @_; return $self->_get_data_dir( $corpus_id ); }

	sub get_submitted_document    { my ( $self, $arg_ref ) = @_; return Text::Mining::Corpus::Document->new( $arg_ref ); }
	sub count_submitted_waiting   { my ( $self ) = @_; my ( $count ) = $self->library()->sqlexec( "select count(*) from submitted_documents where exit_date = '0000-00-00 00:00:00'", '@' ); return $count; }
	sub count_submitted_complete  { my ( $self ) = @_; my ( $count ) = $self->library()->sqlexec( "select count(*) from submitted_documents where exit_date != '0000-00-00 00:00:00'", '@' ); return $count; }

	sub parse_document {
		my ( $self, $arg_ref ) = @_; 
		my $document  = defined $arg_ref->{document}  ? $arg_ref->{document}  : $self->_status( "No document to parse." );
		my $algorithm = defined $arg_ref->{algorithm} ? $arg_ref->{algorithm} : $self->_status( "No algorithm defined." );

		return $document; 
	}

	sub get_all_corpuses          { 
		my ( $self, @corpuses) = @_; 
		my $corpuses = $self->library()->sqlexec( "select corpus_id from corpuses order by corpus_id asc", '\@@' ); 
		foreach my $corpus (@$corpuses) { push @corpuses, Text::Mining::Corpus->new({ corpus_id => $corpus->[0] }); } 
		return \@corpuses; 
	}

	sub get_corpus_id             { 
		my ( $self, $arg_ref ) = @_; 
		my   $corpus           = Text::Mining::Corpus->new(); 
		my ( $corpus_id )      = $self->library()->sqlexec( "select corpus_id from corpuses where corpus_name = '" . $arg_ref->{corpus_name} . "'", '@' ); 
		return $corpus_id; 
	}

	sub process_urls {
		my ( $self ) = @_; 
		my $corpuses = $self->get_all_corpuses();
		foreach my $corpus( @$corpuses ) {
			my $data_dir      = $self->get_data_dir( $corpus->get_id() );
			my $sql           = "select submitted_url_id, corpus_id, submitted_by_user_id, submitted_url from submitted_urls where exit_date = '0000-00-00 00:00:00' and file_not_found = 0";
			my $urls          = $self->library()->sqlexec( $sql, '\@@' );
			foreach my $url ( @$urls ) { $self->_download_url( $url, $data_dir ); }
		}
	}

	sub reprocess_urls {
		my ( $self ) = @_; 
		my $corpuses = $self->get_all_corpuses();
		foreach my $corpus( @$corpuses ) {
			my ( $corpus_id ) = @$corpus;
			my $data_dir      = $self->get_data_dir( $corpus->get_id() );
			my $sql           = "select submitted_url_id, corpus_id, submitted_by_user_id, submitted_url from submitted_urls where file_not_found = 1";
			my $urls          = $self->library()->sqlexec( $sql, '\@@' );
			foreach my $url ( @$urls ) { $self->_download_url( $url, $data_dir ); }
		}
	}

	sub _download_url {
		my ( $self, $url_row, $data_dir )          = @_; 
		my ( $id, $corpus_id, $user_id, $url ) = @$url_row;
		my $file_name = $self->_parse_file_name( $url );
		my $path      = $self->_build_directories( $url, $data_dir );
		my $bytes     = $self->_download_file({ target_dir => $data_dir . $path,
		                                        url        => $url,
						        file_name  => $file_name });
		if ( $bytes ) { 
			my $sql  = "insert into submitted_documents (submitted_url_id, corpus_id, submitted_by_user_id, document_path, document_file_name, bytes ) ";
			   $sql .= "values ('$id', '$corpus_id', '$user_id', '$path', '$file_name', '$bytes' )";
			$self->library()->sqlexec( $sql );
			$self->library()->sqlexec( "update submitted_urls set exit_date = now(), file_found = 1, file_not_found = 0 where submitted_url_id = '$id'" ); }
		else 	      { 
			$self->library()->sqlexec( "update submitted_urls set exit_date = now(), file_found = 0, file_not_found = 1 where submitted_url_id = '$id'" ); }
	}

	sub _build_directories {
		my ( $self, $url, $corpus_data_dir ) = @_; 
		my @path     = split(/\//, $url); shift(@path); shift(@path); # Remove protocol
		my $file     = pop(@path);
		my $path     = '';
	
		foreach my $part (@path) { 
			$path .= '/' . $part; 
			if (! -e $corpus_data_dir . $path) { mkdir $corpus_data_dir . $path; } 
		}
		return $path;
	}
	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Mining - Perl Tools for Text Mining Research


=head1 VERSION

This document describes Text::Mining version 0.0.8


=head1 SYNOPSIS

To run the shell:

    use Text::Mining;

    my $tm = Text::Mining->new();
    $tm->shell();

To use the objects:

    use Text::Mining;

    my $tm = Text::Mining->new();
    my $corpus = $tm->get_corpus({ corpus_name => 'Test' });
    my $document = $corpus->add_document({ file_path => 'data/file42.txt' });
    my $parser   = Text::Mining::Parser->new({ parser    => 'Text', 
					       algorithm => 'Base' });

  
=head1 DESCRIPTION

Text::Mining manages multiple corpuses with unlimited documents and annotations 
and calculates representations of the documents using a variety of algorithms.

The primary design considerations are token provenance in the face of ever-changing 
protocols of analysis and pipeline automation for corpus recalculations.

=head1 INTERFACE 

The command line interface is self-describing via the "help" command. Copy the 
"kodos" script from package "scripts" directory to someplace in your path. Check 
the permissions and adjust as necessary. To start the shell, enter "kodos" at 
the prompt.

=head2 METHODS 

=item * shell

 $tm->shell();

Uses Term::Shell plus a few enhancements to provide a live 
environment for developing flexible and repreatable text mining 
protocols and manage multi-release projects encompassing multiple 
corpuses.

=item * version

 print $tm->version(), "\n";

Reports the version of Text::Mining.

=item * create_corpus            

 print $tm->version(), "\n";

Reports the version of Text::Mining.

=item * get_corpus               

 my $corpus = $tm->get_corpus({ corpus_id = 1 });
 my $corpus = $tm->get_corpus({ corpus_name = 'Test' });

Retrieves a corpus object from the database.

=item * delete_corpus            

 $corpus->delete();

Deletes a corpus from the database. Deletes all related documents.

=item * get_root_dir             

 print $tm->get_root_dir(), "\n";

Reports the root directory from the configuration file.

=item * get_root_url             

 print $tm->get_root_url(), "\n";

Reports the root URL of the the webserver from the configuration file.

=item * get_data_dir             

 print $tm->get_data_dir(), "\n";

Reports the main data directory from the configuration file.

=item * get_submitted_document   

 print $tm->submitted_document(), "\n";

Reports the 

=item * count_submitted_waiting  

 print $tm->count_submitted_waiting(), "\n";

Reports the number of documents waiting to be included for a 
given corpus.

=item * count_submitted_complete 

 print $tm->count_submitted_complete(), "\n";

Reports the number of documents ...

=item * get_all_corpuses         

 my $corpuses = $tm->get_all_corpuses();

Returns the corpuses as DBI table.

=item * get_corpus_id            

 print $corpus->get_corpus_id(), "\n";

Reports the corpus_id of the current_corpus

=back


=head1 CONFIGURATION AND ENVIRONMENT

Text::Mining requires a set of configuration files stored at "~/.corpus": 

=over

=item * shellrc

Currently holds pwd and current_corpus. Loaded when you start the shell. 
These settings are saved in real time with _updated_config();

=item * shell_history

Holds the last 1,000 commands. Reloaded when you start the shell. Saved 
in postcmd().

=head1 DEPENDENCIES

 Test::More
 version
 Class::Std
 Class::Std::Utils
 YAML
 Carp
 LWP::Simple
 Time::HiRes
 DBIx::MySperqlOO
 File::Spec
 

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-mining@rt.cpan.org>, or through the web interface at
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
