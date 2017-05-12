## XML::Generator::RSS10::gcl
## An extension to Dave Rolsky's XML::Generator::RSS10 to handle categories in the UK Government Category List
## To be used in conjunction with XML::Generator::RSS10::egms
## Written by Andrew Green, Article Seven, http://www.article7.co.uk/
## Sponsored by Woking Borough Council, http://www.woking.gov.uk/
## Last updated: Wednesday, 8 September 2004

package XML::Generator::RSS10::gcl;

$VERSION = '0.01';

use strict;
use Carp;

use base 'XML::Generator::RSS10::Module';

1;

####

sub NamespaceURI {

   'http://www.esd.org.uk/standards/gcl/2.00/gcl-schema#'

}

####

sub category {

   my ($self,$rss,$category_value) = @_;
   
   my $camelcategory = $self->_camelcase($category_value);
   
   $rss->_start_element('gcl',$camelcategory);
   $rss->_newline_if_pretty;
   $rss->_element_with_data('rdf','value',$category_value);
   $rss->_newline_if_pretty;
   $rss->_end_element('gcl',$camelcategory);
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

XML::Generator::RSS10::gcl - Support for the UK Government Category List (gcl) specfication

=head1 SYNOPSIS

    use XML::Generator::RSS10;
    
    my $rss = XML::Generator::RSS10->new( Handler => $sax_handler, modules => [ qw(dc egms gcl lgcl) ] );
    
    $rss->item(
                title => '2004 Council By-Election Results',
                link  => 'http://www.example.gov.uk/news/elections.html',
                description => 'Results for the 2004 Council by-elections',
                dc => {
                   date    => '2004-05-01',
                   creator => 'J. Random Reporter, Example Borough Council, j.r.reporter@example.gov.uk',
                },
                egms => {
                   SubjectCategory => [
                                         ['GCL','Local government'],
                                         ['LGCL','Elections'],
                                         ['LGCL','News announcements']
                                      ]
                }
              );
    
    $rss->channel(
                   title => 'Example Borough Council News',
                   link  => 'http://www.example.gov.uk/news/',
                   description => 'News releases from Example Borough Council',
                   dc => {
                      date       => '2004-05-01',
                      creator    => 'J. Random Administrator, Example Borough Council, j.r.administrator@example.gov.uk',
                      publisher  => 'Example Borough Council',
                      rights     => 'Copyright (c) Example Borough Council',
                      language   => 'en',
                      coverage   => 'Example, County, UK'
                   },
                   egms => {
                      SubjectCategory => [
                                            ['GCL','Local government'],
                                            ['LGCL','News announcements']
                                         ]
                   }
                 );

=head1 DESCRIPTION

This module extends Dave Rolsky's L<XML::Generator::RSS10> to provide support categories taken from the UK Government Category List (gcl), a controlled vocabulary for use in the UK e-Government Metadata Standard (egms).

The module is intended for use only with L<XML::Generator::RSS10::egms>.  Please see the documentation accompanying that module for further information.

=head1 CHANGES

B<Version 0.02>: Minor change to the way the XML local-name is created for tags in the GCL namespace, to account for category names with punctuation marks.

B<Version 0.01>: Initial release.

=head1 SEE ALSO

L<XML::Generator::RSS10>, L<XML::Generator::RSS10::egms>.

=head1 AUTHOR

Andrew Green, C<< <andrew@article7.co.uk> >>.

Sponsored by Woking Borough Council, L<http://www.woking.gov.uk/>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
