package WWW::HyperGlossary;
use base qw(WWW::HyperGlossary::Base);
use Class::Std;
use Class::Std::Utils;
use DBI;
use DBIx::MySperql qw(DBConnect SQLExec $dbh);
use LWP::Simple;
use Encode;
use HTML::Encoding 'encoding_from_http_message';
use Set::Infinite;
use Regexp::List;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');

our @colors = qw( x 009900 66FF66 FF6666 990000 660000);

{
	my %category_id_of   : ATTR( );
	my %category_name_of : ATTR( :default<''> );
	my %matches_of       : ATTR( :default<''> );  # Used only once below; added at package testing :RAH

	sub BUILD {      
		my ($self, $ident, $arg_ref) = @_;

		# Set category id 
		$category_id_of{$ident}   = $arg_ref->{category_id} ? $arg_ref->{category_id} : 0; 

		# Set category name if hg_categories included
		if ( (defined $arg_ref->{hg_categories}) && (defined $arg_ref->{category_id}) ) {
			foreach my $category ( @{ $arg_ref->{hg_categories} } ) {
				if ( $category->[0] == $arg_ref->{category_id} ) {
					$category_name_of{$ident} = $category->[1];
				}
			}
		}

		return;
	}

	sub get_category_id    { my ($self) = @_; return $category_id_of{ident $self}; }
	sub get_category_name  { my ($self) = @_; return $category_name_of{ident $self}; }

	sub start_url  {
		my ( $self, $arg_ref ) = @_;

		# Get the page
		my $url       = $arg_ref->{url}  ? $self->fill_url( $arg_ref->{url} ) : "";
		my $html      = get( $url );
	
		# Parse head and body and add the body control div
	           $html      =~ m/<head(.*?)>(.*)<\/head>/six;
		my $head_tag  = $1;
		my $head_text = $2;
	           $html      =~ m/<body(.*?)>(.*)<\/body>/six;
		my $body_tag  = $1;
		my $body_text = "    <div name=\"hgDiv\" id=\"hgDiv\">\n" . $2 . "    </div>\n";
		# TODO Add Base URL tag (search Kyles::base_tag)
	
		# TODO Retrieve Cached Pages
		# TODO ELSE
		# Save page 
		my ($page_id) = $self->new_page({ category_id => $arg_ref->{category_id}, 
		                                  url         => $url, 
						  html        => $html, 
						  body        => $body_text });

		# Rebuild the page
		my $text  = "<html>\n";
		   $text .= "    <head$head_tag>\n";
		   $text .= "    $head_text\n";
		   $text .= "    <script src=\"http://bioinformatics.ualr.edu/js/hg3.js\"></script>\n";
		   $text .= "    </head>\n";
		   $text .= "    <body$body_tag onload='myStart(500,\"http://bioinformatics.ualr.edu/catalyst/hg/next_set" . $page_id . "\");'>\n";
		   $text .= "    $body_text\n";
		   $text .= "    </body>\n";
		   $text .= "</html>\n";
		# TODO END ELSE

		return $text;
	}

	sub new_page  {
		my ( $self, $arg_ref ) = @_;
		my $category_id  = $arg_ref->{category_id} ? $self->_sql_escape( $arg_ref->{category_id} ) : "";
		my $html         = $arg_ref->{html}        ? $self->_sql_escape( $arg_ref->{html} ) : "";
		my $body         = $arg_ref->{body}        ? $self->_sql_escape( $arg_ref->{body} ) : "";
		my $url          = $arg_ref->{url}         ? $self->_sql_escape( $arg_ref->{url} )  : "";

		# Save page and return the id
		my $sql   = "insert into hg_pages (category_id, url, html, body) ";
		   $sql  .= "values ('$category_id', '$url', '$html', '$body')";
		SQLExec( $sql );
		   $sql   = "select LAST_INSERT_ID()";
		return SQLExec( $sql, '@' );
	}

	sub next_set  {
		my ( $self, $arg_ref ) = @_;
		my $hg_words    = $arg_ref->{hg_words};
		my $page_id     = $arg_ref->{page_id}     ? $arg_ref->{page_id}     : 0;
# defined below :RAH		my $category_id = $arg_ref->{category_id} ? $arg_ref->{category_id} : 1;
		my $match;
		# Retrieve the body
		my $sql  = "select category_id, body, set_id from hg_pages where page_id = '$page_id'";
		my ( $category_id, $body, $set_id ) = SQLExec( $sql, '@' );
		
#		my $safe_set = $self->create_safe_set( $body );
	
		# TODO Include Kyles::safe_set and otherwise make BETTER 
		# Parse and replace
		my $words = $hg_words->{$category_id}->{$set_id}->{'words'};

		my $wordregex = $self->_build_regex( $words );
		
		# Create set of safe substituion zones
		my $safe_set = $self->create_safe_set( $body );

		# Replace matched words
		$body = $self->search_replace_word( $body, $wordregex, $safe_set, $set_id );
			
		# Update the set_id
		   $sql  = "update hg_pages set body = '" . $self->_sql_escape( $body ) . "', set_id = '" . ($set_id + 1) . "' where page_id = '$page_id'";
		SQLExec( $sql );

		return $body;
	}

	# COPIED CODE

	sub get_url  {
		my ( $self, $url ) = @_;

		# Create basetag
		$url        =~ m/(http.*\/)/i;
		my $basetag = "<base href='" . $1 . "'><\/base>";

		# Get the html
		my $ua      = LWP::UserAgent->new();
		my $html    = $ua->get( $url );
		my $content = $html->decoded_content; 
		   $content =~ s/<head>/<head>$basetag/gi;

		return $content;
	}

	sub create_safe_set {
		my ( $self, $body ) = @_;
	
		$body =~ m/(^(.|\n)*<body(.|\n)*?>)/gi;
		
		my $start      = length($`);
		my $stop       = length($&) + $start;
		my $danger_set = Set::Infinite->new($start, $stop);
		
		# Manage <script>
		while ($body =~ m/(<script(.|\n)*?>(.|\n)*?(<\/script>){1}?)/ig) {
		    my $start   = length($`);
		    my $stop    = length($&) + $start;
		    $danger_set = $danger_set->union($start, $stop);
		}

		# Manage <a>
		while ($body =~ m/(<a(.|\n)*?>(.|\n)*?(<\/a>){1}?)/ig) {
		    my $start   = length($`);
		    my $stop    = length($&) + $start;
		    $danger_set = $danger_set->union($start, $stop);
		}
		
		my $safe_set = Set::Infinite->new( 0, length($body) );
		
		return $safe_set->minus($danger_set);
	}

	sub search_replace_word {
		my ( $self, $body, $wordregex, $safe_set, $set_id ) = @_;
		
		my @intervals = reverse( split(/,/, "$safe_set") );
		
		foreach my $interval (@intervals) {
		    $interval =~ /(\d*)\.\.(\d*)/i;
		    my $start = $1; my $length = $2 - $1;
		    if ($length >= 0) {
			substr($body,$start,$length) =~ s/($wordregex)/<A HREF="javascript:onClick=alert('$1')"><font style="color:#$colors[$set_id]">$1<\/font><\/A>/gi; 
		    }
		}
		return $body;    
	}

	sub add_javascript {
		my ($self, $c) = @_;
		my @matcharray = @_;

		# Get matches
		my @matches = @{ $matches_of{ident $self} };

		my $dbh = $c->model('DBI')->dbh;
		my $hg_id = $c->request->param('hg');
		my $hg_table_name = $c->stash->{'hg_table_name'};
		
		# Create a list of hashrefs that can be iterated over in the template
		foreach my $match (@matches) {
		    my $matchclass = classname_from_string($_);
		    
		    # Get word_id from database
		    my $lang_id = $c->request->param('lang');
		    my $sth = $dbh->prepare("SELECT id, synonym FROM ".$hg_table_name."_words WHERE word=?");
		    $sth->execute($match);
		    if ($sth->rows() != 0) {
		        my ($word_id, $synonym_id) = $sth->fetchrow_array();
		        if ($synonym_id) {$word_id = $synonym_id;}
		        push @matcharray, {'word' => $match,
		                           'class' => $matchclass,
		                           'hg_id' => $hg_id,
		                           'word_id' => $word_id,
		                           'lang_id' => $lang_id};
		    }
		}
		
		$c->stash->{'matches'} = \@matcharray;
		my $javascript = $c->view('TT')->render($c, 'javascript.tt');
		my $divs = $c->view('TT')->render($c, 'matchdivs.tt');
		my $css = $c->view('TT')->render($c, 'css.tt');
		my $html_content = $c->stash->{'html_content'};
		$html_content =~ s/<\/head>/$css\n<\/head>/gi;
		$html_content =~ s/<\/body>/$divs\n<\/body>/gi;
		$html_content =~ s/<\/body>/$javascript\n<\/body>/gi;
		$c->stash->{'html_content'} = $html_content;
	}

	sub span_tag_from_match{
		#my ( $self, $o_string ) = @_;
		my ( $o_string ) = @_;
		my $string = classname_from_string($o_string);
#		print "  STATUS: $o_string, $string \n";
		return '<span class='.$string.' style="color: red">'.$o_string.'</span>';
	}

	sub classname_from_string{
		#my ( $self, $o_string ) = @_;
		my ( $o_string ) = @_;
		my $string = lc($o_string);
		$string =~ tr/\'"\ /____/;
		return $string;
	}

	sub process_html  {
	}

	sub process_text  {
	}

	sub info  {
	}

	sub javascript  {
	}

	sub _build_regex  {
		my ( $self, $words ) = @_;
		my @wordlist               = (); 

		#Get words in set
		foreach my $word_id ( keys %$words ) { push(@wordlist, $words->{$word_id});}
		
		#Build Regular Expression
		my $list   = Regexp::List->new;
		my $regexp = $list->set(modifiers => 'i')->list2re(@wordlist);

		return $regexp
	}
	
}

1; # Magic true value required at end of module
__END__

=head1 NAME

WWW::HyperGlossary - Online Hyperglossary for Eductation


=head1 VERSION

This document describes WWW::HyperGlossary version 0.0.2


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

=head1 PROJECT LEADERS

This project is supported by a grant from National Science Foundation and Arkansas INBRE. The Principal Investigators are:

=over 

=item * Robert Belford (rebelford@ualr.edu) 

=item * Dan Berleant (berleant@gmail.com) 

=back 

=head1 AUTHORS

Feel free to email the authors with questions or concerns. Please be patient for a reply.

=over 

=item * Roger Hall (roger@iosea.com), (rahall2@ualr.edu) 

=item * Michael Bauer (mbkodos@gmail.com), (mabauer@ualr.edu) 

=item * Jon Holmes (jlholmes@chem.wisc.edu) 

=item * John Moore (jwmoore@chem.wisc.edu) 

=item * Shane Sullivan (szsullivan@ualr.edu)

=item * Kyle Yancey (kollydog@IPA.NET)

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
