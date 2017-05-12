package WWW::HyperGlossary::Base;
use Class::Std;
use Class::Std::Utils;
use DBI;
use DBIx::MySperql qw(DBConnect SQLExec $dbh);
use Digest::MD5 qw (md5_hex);

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');

{
	my %data_of        : ATTR( );

	sub BUILD {      
		my ($self, $ident, $arg_ref) = @_;

#		my $data = IOSea::Hyperglossary::Words->new();
#		$data_of{$ident} = $data->get_data();

		return;
	}

	sub get_languages  {
	    my ( $self ) = @_;
	    my $sql = "select language_id, language from hg_languages order by language asc";
	    return SQLExec( $sql, '\@@' );
	}
	    
	sub get_definition_types  {
	    my ( $self ) = @_;
	    my $sql = "select definition_type_id, definition_type from hg_definition_types order by definition_type asc";
	    return SQLExec( $sql, '\@@' );
	}
	    
	sub get_categories  {
	    my ( $self ) = @_;
	    my $sql = "select category_id, category from hg_categories order by category asc";
	    return SQLExec( $sql, '\@@' );
	}
	    
	sub get_category_words  {
	    my ( $self, $category_id ) = @_;
	    my $sql = "select hg_category_words.category_word_id, hg_words.word from hg_category_words, hg_words where hg_category_words.category_id = $category_id and hg_category_words.word_id = hg_words.word_id";
	    return SQLExec( $sql, '\@@' );
	}
	    
	sub get_set_words  {
	    my ( $self, $category_id, $set_id ) = @_;
	    my $sql = "select hg_category_words.category_word_id, hg_words.word from hg_category_words, hg_words where hg_category_words.category_id = $category_id and hg_category_words.word_id = hg_words.word_id and hg_category_words.set_id = '$set_id' order by length(hg_words.word) desc";
	    return SQLExec( $sql, '\@@' );
	}
	    
	sub fill_url  {
	    my ( $self, $url ) = @_;
	    
	    # Fix up url so it doesn't cause an error message
	    # add http:// if the user didn't
	    # add trailing slash if bare domain e.g. www.google.com
	    # todo: See if URI library makes this all trivial
	    if ( !($url =~ /http:/) ) { $url = 'http://'.$url;}
	    if (! ($url =~ /\/.*\..*$/) ) {if ( $url =~ /\.\w*$/ ) { $url = $url.'/';}}

	    return $url;
	}
	
	
	sub _sql_escape { 
		my ( $self, $string ) = @_;
		if ($string) { $string =~ s/(['"\\])/\\$1/g; }
		return $string; 
	}
	
	sub _html_to_sql {
		my ( $self, $string ) = @_;
		$string = $self->_html_unescape( $string );
		$string = $self->_sql_escape( $string );
		return $string;
	}
	
	sub _html_escape {
		my ( $self, $string ) = @_;
		$string =~ s/'/&#39;/g;
		$string =~ s/"/&#34;/g;
		return $string;
	}
		
	sub _html_encode {
		my ( $self, $string ) = @_;
		$string =~ s/ /%20/g;
		$string =~ s/'/%27/g;
		$string =~ s/\{/%7B/g;
		$string =~ s/\}/%7D/g;
		return $string;
	}
		
	sub _html_unescape {
		my ( $self, $string ) = @_;
		$string =~ s/&#39;/'/g;
		$string =~ s/&#34;/"/g;
		$string =~ s/%20/ /g;
		return $string;
	}
	
	sub _phone_format {
		my ( $self, $string ) = @_;
		$string =~ s/(\d{3})(\d{3})(\d{4})/($1) $2-$3/;
		return $string;
	}
	
	sub _phone_unformat {
		my ( $self, $string ) = @_;
		$string =~ s/[^\d]//g;
		return $string;
	}
	
	sub _commify { # Perl Cookbook 2.17
		my ( $self, $string ) = @_;
		my $text = reverse $string;
		$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
		return scalar reverse $text;
	}
	
	sub _build_html_select_options {
		my ($self, $data, $current_id) = @_; 
		my ($html, $selected);
	
		if (! $current_id) { $current_id = 0; $html .= "	<option value=''> "; }
	
		foreach my $datum (@{ $data }) {
			my ($id, $label) = @$datum;
			if ($id == $current_id) { $selected = ' selected'; } else { $selected = ''; } 
			$html .= "	<option value='$id'$selected> $label ";
		}
	
		return $html;
	}
	
	sub _get_files {
		my ( $self, $root_dir ) = @_;
		if (opendir(DIR, $root_dir)) {
			my (@files);
			my (@nodes) = (readdir(DIR));
	
			foreach my $node (@nodes) {
				if ($node =~ m/^\./) { next; }
	
	          		my $pathnode = $root_dir . "/" . $node;
				my @stat = stat($pathnode);
	
				my $value = defined $stat[2] ? $stat[2] : '';
				if ($value =~ /^[^1]/) {
					push(@files, $node);
			  	}
			}
			return @files;
		} else {
			return 0;
		}
	}
	
	sub _get_dirs {
		my ( $self, $path, $nestedflag) = @_;
		
		# If the directory opens
		if (opendir(DIR, $path)) {
			# Read it 
			my (@dirs);
			my (@nodes) = sort (readdir(DIR));
	
			foreach my $node (@nodes) {
			  # Drop any dirs (or files) that start with a period
			  if ($node =~ m/^\./) { next; }
	
			  # Get file system node status
			  my @stat = stat($path . '/' . $node);
	
			  # if the first character of $mode is 1, then it is a dir
			  if ($stat[2] =~ /^1/) {
			    my $newpath = $path . "/" . $node;
			    push(@dirs, $newpath);
	
			    if ($nestedflag) {
			      my @subnodes = &GetDirs($newpath, $nestedflag);
			      push(@dirs, @subnodes);
			    }
			  }
			}
			return @dirs;
		} else {
			return 0;
		}
	}
	
	sub _get_file_text {
		my ( $self, $path_file_name ) = @_;
		my ($text, $line);
		if (-e $path_file_name) {
			open  (my $IN, '<', $path_file_name) || $self->_status( "(Get) Cannot open $path_file_name: $!" );
			while ($line = <$IN>) { $text .= $line; }
			close ($IN)                          || $self->_status( "(Get) Cannot close $path_file_name: $!" );
		}
		return $text;
	}
	
	sub _set_file_text {
		my ( $self, $path_file_name, $text ) = @_;
		open  (my $OUT, '>', $path_file_name)        || $self->_status( "(Set) Cannot open $path_file_name: $!" );
		print {$OUT} $text                           || $self->_status( "(Set) Cannot write $path_file_name: $!" );
		close ($OUT)                                 || $self->_status( "(Set) Cannot close $path_file_name: $!" );
	}
	
	sub _add_file_text {
		my ( $self, $path_file_name, $text ) = @_;
		open  (my $OUT, '>>', $path_file_name)       || $self->_status( "(Add) Cannot open $path_file_name: $!" );
		print {$OUT} $text                           || $self->_status( "(Add) Cannot write $path_file_name: $!" );
		close ($OUT)                                 || $self->_status( "(Add) Cannot close $path_file_name: $!" );
	}
	
	sub _status {
		my ( $self, $msg ) = @_;
		my $status_file = $self->get_status_filename();
		open  (my $OUT, '>>', $status_file)          || croak( "(Status) Cannot open $status_file: $!" );
		print {$OUT} "  STATUS: $msg \n"             || croak( "(Status) Cannot write $status_file: $!" );
		close ($OUT)                                 || croak( "(Status) Cannot close $status_file: $!" );
		return;
	}
	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

WWW::HyperGlossary::Base - Online Hyperglossary for Eductation


=head1 VERSION

This document describes WWW::HyperGlossary::Base version 0.0.2


=head1 SYNOPSIS

    use WWW::HyperGlossary;

  
=head1 DESCRIPTION

The HyperGlossary inserts links on glossary-specific words with definitions and 
related multi-media resources.

=head1 DEPENDENCIES

 Class::Std
 Class::Std::Utils
 YAML
 Carp
 LWP::Simple
 DBIx::MySperql
 Digest::MD5

=head1 AUTHORS

Feel free to email the authors with questions or concerns. Please be patient for a reply.

=over 

=item * Roger Hall (roger@iosea.com), (rahall2@ualr.edu) 

=item * Michael Bauer (mbkodos@gmail.com), (mabauer@ualr.edu) 

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, the Authors

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
