package Text::Mining::Corpus;
use base qw(Text::Mining::Corpus::Base);
use Class::Std;
use Class::Std::Utils;
use Text::Mining::Corpus::Document;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.8');

{
	my %id_of    : ATTR( );
	my %name_of  : ATTR( );
	my %desc_of  : ATTR( );
	my %path_of  : ATTR( );

	sub BUILD {      
		my ($self, $ident, $arg_ref) = @_;
	               
		if    (defined $arg_ref->{corpus_id})   { $self->_get_corpus($arg_ref); }
		elsif (defined $arg_ref->{corpus_name}) { 
			# Check if already exists 
			my $corpus_id = $self->get_corpus_id_from_name($arg_ref);
			if ( $corpus_id ) {
				$arg_ref->{corpus_id} = $corpus_id;
				$self->_get_corpus($arg_ref);
			} else {
				# Insert new corpus 
				$self->insert( $arg_ref ); 
			}
		}

		return;
	}

	#sub submit_document           { my ( $self, $arg_ref ) = @_; $arg_ref->{corpus_id} = $id_of{ident $self}; return Text::Librarian::SubmitDocument->new( $arg_ref ); }
	#sub submit_document           { my ( $self, $arg_ref ) = @_; $arg_ref->{corpus_id} = $id_of{ident $self}; return Text::Mining::Corpus::Document->new( $arg_ref ); }
	#sub delete_submitted_document { my ( $self, $arg_ref ) = @_; return Text::Librarian::SubmitDocument->delete( $arg_ref ); }
	sub delete_submitted_document { my ( $self, $arg_ref ) = @_; return Text::Mining::Corpus::Document->delete( $arg_ref ); }

	sub get_id              { my ($self) = @_; return $id_of{ident $self}; }
	sub get_corpus_id       { my ($self) = @_; return $id_of{ident $self}; }
	sub get_name            { my ($self) = @_; return $name_of{ident $self}; }
	sub get_path            { my ($self) = @_; return $path_of{ident $self}; }
	sub get_desc            { my ($self) = @_; return $desc_of{ident $self}; }
	sub get_data_dir        { my ($self) = @_; return $self->_get_data_dir( $id_of{ident $self} ); }

	sub set_name            { my ($self, $value) = @_; $name_of{ident $self} = $value; return $self; }
	sub set_desc            { my ($self, $value) = @_; $desc_of{ident $self} = $value; return $self; }
	sub set_path            { my ($self, $value) = @_; $path_of{ident $self} = $value; return $self; }

	sub submit_document { 
		my ( $self, $arg_ref ) = @_; 
		$arg_ref->{corpus_id} = $self->get_corpus_id();
		return Text::Mining::Corpus::Document->new( $arg_ref ); 
	}

	sub _get_corpus {
		my ($self, $arg_ref) = @_;
		my $ident = ident $self;

		my $sql  = "select corpus_id, corpus_name, corpus_desc, corpus_path ";
		   $sql .= "from corpuses ";
	   	   $sql .= "where corpus_id = '$arg_ref->{corpus_id}'";

		($id_of{$ident}, 
	   	 $name_of{$ident}, 
	   	 $desc_of{$ident}, 
	   	 $path_of{$ident}) = $self->library()->sqlexec( $sql, '@' );
	}

	sub update {
		my ( $self, $arg_ref )   = @_; 
		my $ident       = ident $self;
		my @updates     = ();

		if ( defined $arg_ref->{corpus_name} ) { $self->set_name( $arg_ref->{corpus_name} ); push @updates, "corpus_name = '" . $self->_html_to_sql( $arg_ref->{corpus_name} ) . "'"; }
		if ( defined $arg_ref->{corpus_desc} ) { $self->set_desc( $arg_ref->{corpus_desc} ); push @updates, "corpus_desc = '" . $self->_html_to_sql( $arg_ref->{corpus_desc} ) . "'"; }
		if ( defined $arg_ref->{corpus_path} ) { $self->set_path( $arg_ref->{corpus_path} ); push @updates, "corpus_path = '" . $self->_html_to_sql( $arg_ref->{corpus_path} ) . "'"; }

		my $sql  = "update corpuses set " . join( ', ', @updates ) . " where corpus_id = '$id_of{$ident}'";
	   	$self->library()->sqlexec( $sql );
	}

	sub insert {
		my ($self, $arg_ref)  = @_; 
		my $ident       = ident $self;

		# Save the values 
		$name_of{$ident} = $arg_ref->{corpus_name};
		$desc_of{$ident} = $arg_ref->{corpus_desc} ? $arg_ref->{corpus_desc} : $arg_ref->{corpus_name};

		# Insert base values
		foreach ('corpus_name', 'corpus_desc') { $arg_ref->{$_} = $self->_html_to_sql( $arg_ref->{$_} || '' ); }
		my $sql  = "insert into corpuses (corpus_name, corpus_desc) ";
		   $sql .= "values ( '$arg_ref->{corpus_name}', '$arg_ref->{corpus_desc}') ";
	   	$self->library()->sqlexec( $sql );

		# Get the new corpus_id
		   $sql  = "select LAST_INSERT_ID()";
	   	( $id_of{$ident} ) = $self->library()->sqlexec( $sql, '@' );

		# Update the path
		$path_of{$ident} = $arg_ref->{corpus_path} ? $arg_ref->{corpus_path} : $self->_default_corpus_path();
		   $sql  = "update corpuses set corpus_path = '" .  $path_of{$ident} . "' ";
		   $sql .= "where corpus_id = '" . $id_of{$ident} . "'";
	   	$self->library()->sqlexec( $sql );

		# Make sure the path exists
		$self->check_path();
	}

	sub delete {
		my ( $self, $arg_ref )  = @_; 
		my $id = defined($arg_ref->{corpus_id}) ? $arg_ref->{corpus_id} : $id_of{ident $self};
	   	$self->library()->sqlexec( "delete from corpuses where corpus_id = '$id'" );
	   	$self->library()->sqlexec( "delete from submitted_documents where corpus_id = '$id'" );
	}

	sub clean {
		my ( $self ) = @_; 
		my @dirs     = $self->_get_dirs( $self->get_data_dir() );
		foreach my $dir ( @dirs ) { $self->clean_directory( $dir ); }
	}

	sub clean_directory {
		my ( $self, $dir ) = @_; 
		my @files      = $self->_get_files( $dir );
		my @sub_dirs   = $self->_get_dirs( $dir, 0 );
		my $file_count = scalar(@files);
		my $dir_count  = scalar(@sub_dirs);

		if ($file_count + $dir_count == 0) { rmdir($dir); }

		foreach my $file    ( @files )    { if (! ($file =~ m/\.zip$/i) ) { $self->clean_document( $dir . '/' . $file ); } }
		foreach my $sub_dir ( @sub_dirs ) { $self->clean_directory( $sub_dir ); }
	}

	sub clean_document {
		my ( $self, $file ) = @_; 
		my @parts           = split(/\//, $file);
		my $root_dir        = $self->_get_root_dir();
		my $file_name       = pop( @parts );
		   $file_name       =~ m/^([\w\.%-]*)\.([\w%-]*)$/;
		my $path            = join( '/', @parts );
		   $path            =~ s/$root_dir\/documents\/corpus_\d+//;
		foreach ($path, $file_name) { $_ = $self->_html_to_sql($_); }
		my $sql  = "select submitted_document_id, corpus_id from submitted_documents ";
		   $sql .= "where document_path = '$path' ";
		   $sql .= "  and document_file_name = '$file_name' ";
		my ( $id, $corpus_id ) = $self->library()->sqlexec( $sql, '@' );

		if (! $id )  { print STDERR "  Unlinking $file \n"; unlink( $file ); }
	}

	sub compress {
		my ( $self, $arg_ref ) = @_; 
		my $data_dir           = $self->get_data_dir();
		my @dirs               = $self->_get_dirs( $data_dir, 0 );
		foreach my $dir ( @dirs ) { $self->compress_directory( $dir ); }
	}

	sub compress_directory {
		my ( $self, $dir ) = @_; 
		my @files      = $self->_get_files( $dir );
		my @sub_dirs   = $self->_get_dirs( $dir, 0 );
		my $file_count = scalar(@files);
		my $dir_count  = scalar(@sub_dirs);

		if ($file_count + $dir_count == 0) { rmdir($dir); }

		foreach my $file    ( @files )    { if (! ($file =~ m/\.zip$/i) ) { $self->compress_document( $dir . '/' . $file ); } }
		foreach my $sub_dir ( @sub_dirs ) { $self->compress_directory( $sub_dir ); }
	}

	sub compress_document {
		my ( $self, $file ) = @_; 
		my @parts           = split(/\//, $file);
		my $root_dir        = $self->_get_root_dir();
		my $file_name       = pop( @parts );
		   $file_name       =~ m/^([\w\.%-]*)\.([\w%-]*)$/;
		my $file_root       = $1;
		my $path            = join( '/', @parts );
		   $path            =~ s/$root_dir\/documents\/corpus_(\d+)//;
		my $corpus_id       = $1;

		my $zip_file = $root_dir . '/documents/corpus_' . $corpus_id . $path . '/' . $file_root . '.zip';
		`zip -q $zip_file $file`;
		unlink( $file );

  		my @stat  = stat("$root_dir$path/$file_root.zip");
  		my $bytes = $stat[7] || '0';

		my $sql  = "update submitted_documents set compressed_file_name = '$file_root.zip', compressed_bytes = '$bytes' ";
		   $sql .= "where document_path = '$path' ";
		   $sql .= "  and document_file_name = '$file_name' ";
	   	$self->library()->sqlexec( $sql );
	}

	sub decompress {
		my ( $self, $arg_ref ) = @_; 
		my $data_dir           = $self->get_data_dir();
		my @dirs               = $self->_get_dirs( $data_dir, 0 );
		foreach my $dir ( @dirs ) { $self->decompress_directory( $dir ); }
	}

	sub decompress_directory {
		my ( $self, $dir ) = @_; 
		my @files      = $self->_get_files( $dir );
		my @sub_dirs   = $self->_get_dirs( $dir, 0 );

		foreach my $file ( @files ) {
			if ($file =~ m/\.zip$/i) { $self->decompress_document( $dir . '/' . $file ); } }
		foreach my $sub_dir ( @sub_dirs ) {
			$self->decompress_directory( $sub_dir ); }
	}

	sub decompress_document {
		my ( $self, $zip_file ) = @_; 
		`unzip -q -d/ $zip_file`;
		unlink( $zip_file );
	}

	sub import_urls {
		my ( $self, $arg_ref ) = @_; 
		my $ident              = ident $self;
		my $corpus_id          = $id_of{$ident};
		my $user_id            = $arg_ref->{submitted_by_user_id};
		my $source_type        = $arg_ref->{source_type};
		my @urls               = ();
		my $record_count       = 0;
		
		if ($source_type eq 'files' ) { @urls = $self->_parse_urls_from_files( $arg_ref ); }
		else                          { print STDERR "  Warning: no valid source_type for \$corpus->import_url()\n"; }
		
		my @insert_values = ();
		foreach my $url (@urls) {
			foreach ($url) { $_ = $self->_html_to_sql($_); }
			my $sql  = "select submitted_urls.submitted_url_id from submitted_urls ";
			   $sql .= " where submitted_urls.submitted_url = '$url'";
			my ( $url_id ) = $self->library()->sqlexec( $sql, '@' );
		
			if (! $url_id) {
				my @path = split(/\//, $url); shift(@path); shift(@path); 
				my $file = pop(@path);
				my $path = '';
				
				foreach ($path, $file) { $_ = $self->_html_to_sql($_); }
				push @insert_values, "($corpus_id, $user_id, '$url')";
			
				if (@insert_values == 100) {
					$record_count += 100;
					my $url_sql    = "insert into submitted_urls (corpus_id, submitted_by_user_id, submitted_url ) ";
					   $url_sql   .= "values " . join( ',', @insert_values ) . ";";
	   				$self->library()->sqlexec( $url_sql );
					@insert_values = ();
				}
			}
		}
		if ( @insert_values ) {
			$record_count += scalar( @insert_values );
			my $url_sql    = "insert into submitted_urls (corpus_id, submitted_by_user_id, submitted_url ) ";
			   $url_sql   .= "values " . join( ',', @insert_values ) . ";";
	   		$self->library()->sqlexec( $url_sql );
		}
		return $record_count;
	}

	sub _parse_urls_from_files {
		my ( $self, $arg_ref ) = @_; 
		my $ident              = ident $self;
		my $source_dir         = $arg_ref->{source_dir} ? $arg_ref->{source_dir} : $self->_get_root_dir() . '/document_sources/corpus_' . $id_of{$ident};
		my $link_type          = $arg_ref->{link_type};
		my %link               = ();
		
		my @files = $self->_get_files( $source_dir );

		foreach my $file (@files) {
			my $content = $self->_get_file_text($source_dir . "/$file");
			my $parser  = HTML::LinkExtor->new(); $parser->parse($content)->eof;
			my @links   = $parser->links;
		
			foreach my $linkarray (@links) {
				my @elements	= @$linkarray;
				my $elt_type 	= shift @elements;
		
				while (@elements) {
					my ($attr_name, $attr_value) = splice(@elements, 0, 2);
					if ($attr_value =~ m/^http(.*)$link_type$/i) { $link{$attr_value}++; }
				}
			}
		}
		return sort keys %link;
	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Mining::Corpus - Management and Analysis for Documents and Representations 


=head1 VERSION

This document describes Text::Mining::Corpus version 0.0.8


=head1 SYNOPSIS

    use Text::Mining::Corpus;

  
=head1 DESCRIPTION


=head1 INTERFACE 



=head1 DIAGNOSTICS


=head1 CONFIGURATION AND ENVIRONMENT

Text::Mining::Corpus requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-mining-corpus@rt.cpan.org>, or through the web interface at
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
