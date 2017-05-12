
package WWW::Patent::Page::Response
	;    #modeled on LWP::UserAgent and HTTP::Response
use strict;
use warnings;
use diagnostics;
use Carp;

use subs qw( new get_parameter set_parameter content is_success message );
our ($VERSION);

$VERSION = 0.021;

sub new    #_HTTP_Response
{
	my ( $class, %patent_parameters_passed ) = @_;
	my $self = {
		'doc_id'     => undef,
        'doc_id_standardized' => undef,              # US6123456    sparse
		'doc_id_commified'    => undef,              # US6,123,456
		'is_success' => undef,
		'content'    => undef,
		'message'    => undef,
		'format'     => undef,
		'office'     => undef,
		'office_username' => undef,
		'office_password' => undef,
		'session_token' => undef,
		'country'    => undef,
		'doc_type'       => undef,
		'number'     => undef,
		'kind'		=> undef,
		'pages'      => undef,
		'page'       => undef,
		'version'    => undef,
		'comment'    => undef,
		'tempdir'    => undef,

	};
	for my $key ( keys %patent_parameters_passed ) {
		if ( exists $self->{$key} ) {
			$self->{$key} = $patent_parameters_passed{$key};
		}
		else {
			carp "parameter '$key' not recognized-",
				" value '$patent_parameters_passed{$key}'";
		}
	}
	bless $self, $class;
}

sub content {
	my $self = shift;
	return ($self->{'content'})
}
sub is_success {
	my $self = shift;
	return ($self->{'is_success'})
}
sub message {
	my $self = shift;
	return ($self->{'message'})
}

sub get_parameter {
	my $self = shift;
	my $parameter = shift;
	if (defined($self->{$parameter})) {return $self->{$parameter}; }
	else {return undef };
}

sub set_parameter {
	my $self = shift;
	my $parameter = shift;
	my $value = shift;
	if (exists($self->{$parameter})) { $self->{$parameter} = $value; return (1);}
	else {return undef };
}

__END__

=head1 NAME

WWW::Patent::Page::Response

object holding a patent page or document (e.g. htm, pdf, tif)
from selected source (e.g. from United States Patent and Trademark Office
(USPTO) website or the European Patent Office (ESPACE_EP), as constructed by WWW::Patent::Page,
in passing analogy to LWP::UserAgent and HTTP::Response


=head1 SYNOPSIS

Please see the test suite for working examples.  The following is not guaranteed to be working or up-to-date.

  $ perl -I. -MWWW::Patent::Page -e 'print $WWW::Patent::Page::VERSION,"\n"'
  0.02

  use WWW::Patent::Page;

  print $WWW::Patent::Page::VERSION,"\n";

  my $patent_browser = WWW::Patent::Page->new(); # new object

  my $document1 = $patent_document->get('6,123,456');
  	# defaults:
  	#       office 	=> 'ESPACE_EP',
	# 	    country => 'US',
	#	    format 	=> 'pdf',
	#		page   	=> 'all',
	# and usual defaults of LWP::UserAgent (subclassed)

  my $document2 = $patent_document->provide_doc('US6123456',
  			office 	=> 'ESPACE_EP' ,
			format 	=> 'pdf',
			page   	=> 2 ,
			);

  my $pages_known = $patent_document->pages_available(  # e.g. TIFF
  			document=> '6123456',
			);

=head1 DESCRIPTION

  Intent:  Use public sources to retrieve patent documents such as
  TIFF images of patent pages, html of patents, pdf, etc.
  Expandable for your office of interest by writing new submodules..

=head1 USAGE

  See also SYNOPSIS above

     Standard process for building & installing modules:

          perl Build.PL
          ./Build
          ./Build test
          ./Build install

Examples of use:

  $patent_browser = WWW::Patent::Page->new(
  			doc_id	=> 'US6,654,321(B2)issued_2_Okada',
  			office 	=> 'ESPACE_EP' ,
			format 	=> 'pdf',
			page   	=> 'all' ,
			agent   => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
			);

	$patent_response = $patent_browser->get('US6,654,321(B2)issued_2_Okada');




=head1 BUGS

Pre-alpha release, to gauge whether the perl community has any interest.

Code contributions, suggestions, and critiques are welcome.

Error handling is undeveloped.

By definition, a non-trivial program contains bugs.

For United States Patents (US) via the USPTO (us), the 'kind' is ignored in method provide_doc


=head1 SUPPORT

Email me at Wanda_B_Anon@yahoo.com with example scripts to dissect.

=head1 AUTHOR

	Wanda B. Anon
	Wanda_B_Anon@yahoo.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 ACKNOWLEDGEMENTS

To the users of WWW::Patent::Page

=head1 SEE ALSO

perl(1).

=head1 Subroutines

=head2 new

Construct an empty object with
appropriate variables as the keys referring to the
content retrieved by Page with its UserAgent helper.

=head2 get_parameter

Access parameters, including content, programmatically (politely).

=head2 set_parameter

a classic

=head2 message

the message

=head2 is_success

not failed

=cut

=head2 content

provides the content (pdf, htm, etc.) when available

=cut