## XML::Generator::RSS10::egms
## An extension to Dave Rolsky's XML::Generator::RSS10 to handle the UK Government eGMS category metadata
## Written by Andrew Green, Article Seven, http://www.article7.co.uk/
## Sponsored by Woking Borough Council, http://www.woking.gov.uk/
## Last updated: Tuesday, 02 May 2006

package XML::Generator::RSS10::egms;

$VERSION = '0.02';

use strict;
use Carp;

use XML::Generator::RSS10::gcl;
use XML::Generator::RSS10::lgcl;
use XML::Generator::RSS10::ipsv;

use base 'XML::Generator::RSS10::Module';

1;

####

sub NamespaceURI {

   'http://www.esd.org.uk/standards/egms/3.0/egms-schema#'

}

####

sub contents {

   my $self = shift;
   my $rss = shift;
   my $p = shift;
   
   foreach my $elt ( sort keys %{$p} ) {
      if ($elt eq 'SubjectCategory') {
         $rss->_start_element('egms','SubjectCategory');
         $rss->_newline_if_pretty;
         if ((ref($p->{$elt}) eq 'ARRAY') && (scalar(@{$p->{$elt}}) == 1)) {
            $self->_category_data($rss,${$p->{$elt}}[0]);
         } elsif (ref($p->{$elt}) eq 'ARRAY') {
            $rss->_start_element('rdf','Bag');
            $rss->_newline_if_pretty;
            foreach my $category (@{$p->{$elt}}) {
               $rss->_start_element('rdf','li');
               $rss->_newline_if_pretty;
               $self->_category_data($rss,$category);
               $rss->_end_element('rdf','li');
               $rss->_newline_if_pretty;
            }
            $rss->_end_element('rdf', 'Bag');
            $rss->_newline_if_pretty;
         } elsif (ref($p->{$elt}) eq 'SCALAR') {
            $self->_generic_category_data($rss,$p->{$elt});
         } else {
            croak "SubjectCategory data must be an array of arrays or a single scalar\n";
         }
         $rss->_end_element('egms','SubjectCategory');
      } else {
         # this is where we should really handle the optional eGMS elements formally...
         $rss->_element_with_data('egms',$elt,$p->{$elt});
      }
      $rss->_newline_if_pretty;
   }
}

####

sub _category_data {

   my ($self,$rss,$category) = @_;
   
   if (lc($category->[0]) eq 'ipsv') {
      croak "Can't add IPSV category data without 'ipsv' in your list of modules\n" unless ($rss->{'modules'}{'ipsv'});
      XML::Generator::RSS10::ipsv->category($rss,$category->[1]);
   } elsif (lc($category->[0]) eq 'gcl') {
      croak "Can't add GCL category data without 'gcl' in your list of modules\n" unless ($rss->{'modules'}{'gcl'});
      XML::Generator::RSS10::gcl->category($rss,$category->[1]);
   } elsif (lc($category->[0]) eq 'lgcl') {
      croak "Can't add LGCL category data without 'lgcl' in your list of modules\n" unless ($rss->{'modules'}{'lgcl'});
      XML::Generator::RSS10::lgcl->category($rss,$category->[1]);
   } else {
      $self->_generic_category_data($rss,$category->[1]);
   }

}

####

sub _generic_category_data {

   my ($self,$rss,$category_value) = @_;
   
   $rss->_start_element('egms','SubjectCategoryClass');
   $rss->_newline_if_pretty;
   $rss->_element_with_data('rdf','value',$category_value);
   $rss->_newline_if_pretty;
   $rss->_end_element('egms','SubjectCategoryClass');
   $rss->_newline_if_pretty;

}

####

__END__

=head1 NAME

XML::Generator::RSS10::egms - Support for the UK e-Government Metadata Standard (egms) RSS 1.0 specfication

=head1 SYNOPSIS

    use XML::Generator::RSS10;
    
    my $rss = XML::Generator::RSS10->new( Handler => $sax_handler, modules => [ qw(dc egms gcl lgcl) ] );
    
    $rss->item(
                title => '2006 Council By-Election Results',
                link  => 'http://www.example.gov.uk/news/elections.html',
                description => 'Results for the 2004 Council by-elections',
                dc => {
                   date    => '2006-05-04',
                   creator => 'J. Random Reporter, Example Borough Council, j.r.reporter@example.gov.uk',
                },
                egms => {
                   SubjectCategory => [
                                         ['GCL','Local government'],
                                         ['LGCL','Elections'],
                                         ['LGCL','News announcements'],
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
                                            ['GCL','Local government'],
                                            ['LGCL','News announcements'],
	                                         ['IPSV','Public relations']
                                         ]
                   }
                 );

=head1 DESCRIPTION

This module extends Dave Rolsky's L<XML::Generator::RSS10> to provide support for the UK e-Government Metadata Standard (egms) RSS 1.0 specfication.

For UK government RSS feeds, much of the mandatory eGMS metadata is provided through the standard Dublin Core module.  However, the subject category metadata is mandatory, and uses rather more complicated RDF XML notation than regular Dublin Core, principally because you're encouraged to pass more than one category for each item.

I've taken the specification for using eGMS metadata in RSS feeds from the I<LAWS Syndication Guidelines>, at L<http://www.esd-toolkit.org/laws/>.

eGMS category metadata is mandated at both the C<item> and C<channel> levels.

For the C<SubjectCategory> element, this module expects to receive an array of categories, where each category is itself an array comprising the name of the controlled list from which the category was taken, and then the category value.

You may pass as many categories as you wish.  For each, the module will assess whether the category is taken from the GCL or LGCL lists and build the RSS code appropriately.  If your category is taken from a different list, such as the APLAWS list, the module will treat the category in a generic way, as per the guidelines.

    $rss->item(
                # title, link, description, dc, etc...
                egms => {
                   SubjectCategory => [
                                         ['APLAWS','Council and democracy']
                                      ]
                }
              );

    $rss->item(
                # title, link, description, dc, etc...
                egms => {
                   SubjectCategory => [
                                         [undef,'Pants']
                                      ]
                }
              );

Alternatively, you may choose to pass a scalar C<SubjectCategory>, which will be handled as a single, generic category.

    $rss->item(
                # title, link, description, dc, etc...
                egms => {
                   SubjectCategory => 'news'
                }
              );

=head1 CAVEAT

If your category metadata is taken from the GCL, the LGCL, or IPSV, you must remember to pass the relevant modules to the C<XML::Generator::RSS10> constructor, like so:

    my $rss = XML::Generator::RSS10->new( Handler => $sax_handler, modules => [ qw(dc egms gcl lgcl ipsv) ] );

This is because the specification demands that references to categories in the GCL or LGCL must use the correct XML namespace.

=head1 CHANGES

B<Version 0.01>: Initial release.

B<Version 0.02>: Added support for the Integrated Public Sector Vocabulary (IPSV).

=head1 TO DO

The syndication guidelines also note the I<optional> eGMS elements and their refinements that aren't expressed in Dublin Core.  Nothing is yet done in this module to specifically support those elements.

=head1 SEE ALSO

L<XML::Generator::RSS10>

=head1 AUTHOR

Andrew Green, C<< <andrew@article7.co.uk> >>.

Sponsored by Woking Borough Council, L<http://www.woking.gov.uk/>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
