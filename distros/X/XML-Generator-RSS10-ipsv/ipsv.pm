## XML::Generator::RSS10::ipsv
## An extension to Dave Rolsky's XML::Generator::RSS10 to handle categories in the UK Integrated Public Sector Vocabulary
## To be used in conjunction with XML::Generator::RSS10::egms
## Written by Andrew Green, Article Seven, http://www.article7.co.uk/
## Sponsored by Woking Borough Council, http://www.woking.gov.uk/
## Last updated: Tuesday, 02 May 2006

package XML::Generator::RSS10::ipsv;

$VERSION = '0.01';

use strict;
use Carp;

use base 'XML::Generator::RSS10::Module';

1;

####

sub NamespaceURI {

   'http://www.esd.org.uk/standards/ipsv/2.00/ipsv-schema#'

}

####

sub category {

   my ($self,$rss,$category_value) = @_;
   
   my $camelcategory = $self->_camelcase($category_value);
   
   $rss->_start_element('ipsv',$camelcategory);
   $rss->_newline_if_pretty;
   $rss->_element_with_data('rdf','value',$category_value);
   $rss->_newline_if_pretty;
   $rss->_end_element('ipsv',$camelcategory);
   $rss->_newline_if_pretty;
   
}

####

sub _camelcase {

   my ($self,$cat) = @_;
   $cat =~ s/\s*(\w+)\s*/\u\L$1/g;
   $cat =~ s/[^A-Za-z]//g;
   return $cat;

}

####

__END__

=head1 NAME

XML::Generator::RSS10::ipsv - Support for the UK Integrated Public Sector Vocabulary (ipsv) specfication

=head1 SYNOPSIS

    use XML::Generator::RSS10;
    
    my $rss = XML::Generator::RSS10->new( Handler => $sax_handler, modules => [ qw(dc egms ipsv) ] );
    
    $rss->item(
                title => '2006 Council By-Election Results',
                link  => 'http://www.example.gov.uk/news/elections.html',
                description => 'Results for the 2006 Council by-elections',
                dc => {
                   date    => '2006-05-04',
                   creator => 'J. Random Reporter, Example Borough Council, j.r.reporter@example.gov.uk',
                },
                egms => {
                   SubjectCategory => [
                                         ['IPSV','Local elections'],
                                         ['IPSV','Public relations']
                                      ]
                }
              );
    
    $rss->channel(
                   title => 'Example Borough Council News',
                   link  => 'http://www.example.gov.uk/news/',
                   description => 'News releases from Example Borough Council',
                   dc => {
                      date       => '2006-05-04',
                      creator    => 'J. Random Administrator, Example Borough Council, j.r.administrator@example.gov.uk',
                      publisher  => 'Example Borough Council',
                      rights     => 'Copyright (c) Example Borough Council',
                      language   => 'en',
                      coverage   => 'Example, County, UK'
                   },
                   egms => {
                      SubjectCategory => [
                                            ['IPSV','Public relations'],
                                            ['IPSV','Councils']
                                         ]
                   }
                 );

=head1 DESCRIPTION

This module extends Dave Rolsky's L<XML::Generator::RSS10> to provide support categories taken from the UK Integrated Public Sector Vocabulary (IPSV), a controlled vocabulary for use in the UK e-Government Metadata Standard (EGMS).

IPSV supercedes both the Local Government Category List (LGCL) and the Government Category List (GCL).

The module is intended for use only with L<XML::Generator::RSS10::egms>.  Please see the documentation accompanying that module for further information.

=head1 CHANGES

B<Version 0.01>: Initial release.

=head1 SEE ALSO

L<XML::Generator::RSS10>, L<XML::Generator::RSS10::egms>.

=head1 AUTHOR

Andrew Green, C<< <andrew@article7.co.uk> >>.

Sponsored by Woking Borough Council, L<http://www.woking.gov.uk/>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
