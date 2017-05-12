###############################################################################
#
# This file copyright (c) 2006-2008 by Randy J. Ray, all rights reserved
#
# See "LICENSE" in the documentation for licensing and redistribution terms.
#
###############################################################################
#
#   $Id: REST.pm 49 2008-04-06 10:45:43Z  $
#
#   Description:    This is the protocol-implementation class for making
#                   requests via the REST interface. At present, this is the
#                   the only supported interface.
#
#   Functions:      parse_authors
#                   parse_books
#                   parse_categories
#                   parse_publishers
#                   parse_subjects
#                   request
#                   request_method
#                   request_uri
#
#   Libraries:      Class::Std
#                   Error
#                   XML::LibXML
#                   WebService::ISBNDB::Agent
#                   WebService::ISBNDB::Iterator
#
#   Global Consts:  $VERSION
#                   $BASEURL
#
###############################################################################

package WebService::ISBNDB::Agent::REST;

use 5.006;
use strict;
use warnings;
no warnings 'redefine';
use vars qw($VERSION $CAN_PARSE_DATES);
use base 'WebService::ISBNDB::Agent';

use Class::Std;
use Error;
use XML::LibXML;

use WebService::ISBNDB::Iterator;

$VERSION = "0.31";

BEGIN
{
    eval "use Date::Parse";
    $CAN_PARSE_DATES = ($@) ? 0 : 1;
}

my %baseurl    : ATTR(:name<baseurl>    :default<"http://isbndb.com">);
my %authors    : ATTR(:name<authors>    :default<"/api/authors.xml">);
my %books      : ATTR(:name<books>      :default<"/api/books.xml">);
my %categories : ATTR(:name<categories> :default<"/api/categories.xml">);
my %publishers : ATTR(:name<publishers> :default<"/api/publishers.xml">);
my %subjects   : ATTR(:name<subjects>   :default<"/api/subjects.xml">);

my %API_MAP = (
    API        => {},
    Authors    => \%authors,
    Books      => \%books,
    Categories => \%categories,
    Publishers => \%publishers,
    Subjects   => \%subjects,
);

my %parse_table = (
    Authors    => \&parse_authors,
    Books      => \&parse_books,
    Categories => \&parse_categories,
    Publishers => \&parse_publishers,
    Subjects   => \&parse_subjects,
);

###############################################################################
#
#   Sub Name:       new
#
#   Description:    Pass off to the super-class constructor, which handles
#                   the special cases for arguments.
#
###############################################################################
sub new
{
    shift->SUPER::new(@_);
}

###############################################################################
#
#   Sub Name:       protocol
#
#   Description:    Return the name of the protocol we implement; if an
#                   argument is passed in, test that the argument matches
#                   our protocol.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $test     in      scalar    If passed, test against our
#                                                 protocol
#
#   Returns:        Success:    string or 1
#                   Failure:    0 if we're testing and the protocol is no match
#
###############################################################################
sub protocol
{
    my ($self, $test) = @_;

    return $test ? $test =~ /^rest$/i : 'REST';
}

###############################################################################
#
#   Sub Name:       request_method
#
#   Description:    Return the HTTP method used for requests
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $obj      in      ref       Object from the API hierarchy
#                   $args     in      hashref   Arguments to the request
#
#   Returns:        'GET'
#
###############################################################################
sub request_method : RESTRICTED
{
    'GET';
}

###############################################################################
#
#   Sub Name:       request_uri
#
#   Description:    Return a URI object representing the target URL for the
#                   request.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $obj      in      ref       Object from the API hierarchy
#                   $args     in      hashref   Arguments to the request
#
#   Returns:        Success:    URI instance
#                   Failure:    throws Error::Simple
#
###############################################################################
sub request_uri : RESTRICTED
{
    my ($self, $obj, $args) = @_;

    my $id = ident $self;

    # $obj should already have been resolved, so the methods on it should work
    my $key = $obj->get_api_key;
    my $apiloc = $API_MAP{$obj->get_type}->{$id};
    my $argscopy = { %$args };

    # If $apiloc is null, we can't go on
    throw Error::Simple("No API URL for the type '" . $obj->get_type . "'")
        unless $apiloc;

    # Only add the "access_key" argument if it isn't already present. They may
    # have overridden it. It will have come from the enclosing object under
    # the label "api_key".
    $argscopy->{access_key} = $argscopy->{api_key} || $key;
    delete $argscopy->{api_key}; # Just in case, so to not confuse their API
    # Build the request parameters list
    my @args = ();
    for $key (sort keys %$argscopy)
    {
        if (ref $argscopy->{$key})
        {
            # Some params, like "results", can appear multiple times. This is
            # implemented as the value being an array reference.
            for (@{$argscopy->{$key}})
            {
                push(@args, "$key=$_");
            }
        }
        else
        {
            # Normal, one-shot argument
            push(@args, "$key=$argscopy->{$key}");
        }
    }

    URI->new("$baseurl{$id}$apiloc?" . join('&', @args));
}

###############################################################################
#
#   Sub Name:       request
#
#   Description:
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $obj      in      scalar    Object or type name or class
#                   $args     in      hashref   Hash reference of arguments to
#                                                 the raw request
#
#   Returns:        Success:    based on $single, a API-derived object or list
#                   Failure:    throws Error::Simple
#
###############################################################################
sub request : RESTRICTED
{
    my ($self, $obj, $args) = @_;
    $obj = $self->resolve_obj($obj);

    my $content = $self->raw_request($obj, $args);

    # First off, parse $content as XML
    my $parser = XML::LibXML->new();
    my $dom = eval { $parser->parse_string($$content); };
    throw Error::Simple("XML parse error: $@") if $@;

    my $top_elt = $dom->documentElement();
    throw Error::Simple("Service error: " . $self->_lr_trim($dom->textContent))
        if (($dom) = $top_elt->getElementsByTagName('ErrorMessage'));
    my ($value, $stats) = $parse_table{$obj->get_type}->($self, $top_elt);

    # Add two pieces to $stats that the iterator will need
    $stats->{contents} = $value;
    $stats->{request_args} = $args;

    WebService::ISBNDB::Iterator->new($stats);
}

###############################################################################
#
#   Sub Name:       parse_authors
#
#   Description:
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $root_elt in      ref       XML::LibXML::Node object
#
#   Returns:        Success:    listref
#                   Failure:    throws Error::Simple
#
###############################################################################
sub parse_authors : RESTRICTED
{
    my ($self, $root_elt) = @_;

    my ($total_results, $page_size, $page_number, $shown_results, $list_elt,
        @authorblocks, $authors, $one_author, $authorref, $tmp);
    # The class should already be loaded before we got to this point:
    my $class = WebService::ISBNDB::API->class_for_type('Authors');

    # For now, we aren't interested in the root element (the only useful piece
    # of information in it is the server-time of the request). So skip down a
    # level-- there should be exactly one AuthorList element.
    ($list_elt) = $root_elt->getElementsByTagName('AuthorList');
    throw Error::Simple("No <AuthorList> element found in response")
        unless (ref $list_elt);

    # These attributes live on the AuthorList element
    $total_results = $list_elt->getAttribute('total_results');
    $page_size     = $list_elt->getAttribute('page_size');
    $page_number   = $list_elt->getAttribute('page_number');
    $shown_results = $list_elt->getAttribute('shown_results');

    # Start with no categories in the list, and get the <CategoryData> nodes
    $authors = [];
    @authorblocks = $list_elt->getElementsByTagName('AuthorData');
    throw Error::Simple("Number of <AuthorData> blocks does not match " .
                        "'shown_results' value")
        unless ($shown_results == @authorblocks);
    for $one_author (@authorblocks)
    {
        # Clean slate
        $authorref = {};

        # ID is an attribute of AuthorData
        $authorref->{id} = $one_author->getAttribute('person_id');
        # Name is just text
        if (($tmp) = $one_author->getElementsByTagName('Name'))
        {
            $authorref->{name} = $self->_lr_trim($tmp->textContent);
        }
        # The <Details> element holds some data in attributes
        if (($tmp) = $one_author->getElementsByTagName('Details'))
        {
            $authorref->{first_name} =
                $self->_lr_trim($tmp->getAttribute('first_name'));
            $authorref->{last_name} =
                $self->_lr_trim($tmp->getAttribute('last_name'));
            $authorref->{dates} = $tmp->getAttribute('dates');
            $authorref->{has_books} = $tmp->getAttribute('has_books');
        }
        # Look for a list of categories and save the IDs
        if (($tmp) = $one_author->getElementsByTagName('Categories'))
        {
            my $categories = [];
            foreach ($tmp->getElementsByTagName('Category'))
            {
                push(@$categories, $_->getAttribute('category_id'));
            }

            $authorref->{categories} = $categories;
        }
        # Look for a list of subjects. We save those in a special format, here.
        if (($tmp) = $one_author->getElementsByTagName('Subjects'))
        {
            my $subjects = [];
            foreach ($tmp->getElementsByTagName('Subject'))
            {
                push(@$subjects, join(':',
                                      $_->getAttribute('subject_id'),
                                      $_->getAttribute('book_count')));
            }

            $authorref->{subjects} = $subjects;
        }

        push(@$authors, $class->new($authorref));
    }

    return ($authors, { total_results => $total_results,
                        page_size => $page_size,
                        page_number => $page_number,
                        shown_results => $shown_results });
}

###############################################################################
#
#   Sub Name:       parse_books
#
#   Description:    Parse the XML resulting from a call to the books API.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $root_elt in      ref       XML::LibXML::Node object
#
#   Returns:        Success:    listref
#                   Failure:    throws Error::Simple
#
###############################################################################
sub parse_books : RESTRICTED
{
    my ($self, $root_elt) = @_;

    my ($total_results, $page_size, $page_number, $shown_results, $list_elt,
        @bookblocks, $books, $one_book, $bookref, $tmp);
    # The class should already be loaded before we got to this point:
    my $class = WebService::ISBNDB::API->class_for_type('Books');

    # For now, we aren't interested in the root element (the only useful piece
    # of information in it is the server-time of the request). So skip down a
    # level-- there should be exactly one BookList element.
    ($list_elt) = $root_elt->getElementsByTagName('BookList');
    throw Error::Simple("No <BookList> element found in response")
        unless (ref $list_elt);

    # These attributes live on the BookList element
    $total_results = $list_elt->getAttribute('total_results');
    $page_size     = $list_elt->getAttribute('page_size');
    $page_number   = $list_elt->getAttribute('page_number');
    $shown_results = $list_elt->getAttribute('shown_results');

    # Start with no books in the list, and get the <BookData> nodes
    $books = [];
    @bookblocks = $list_elt->getElementsByTagName('BookData');
    throw Error::Simple("Number of <BookData> blocks does not match " .
                        "'shown_results' value")
        unless ($shown_results == @bookblocks);
    for $one_book (@bookblocks)
    {
        # Clean slate
        $bookref = {};

        # ID and ISBN are attributes of BookData
        $bookref->{id} = $one_book->getAttribute('book_id');
        $bookref->{isbn} = $one_book->getAttribute('isbn');
        # Title is just text
        if (($tmp) = $one_book->getElementsByTagName('Title'))
        {
            $bookref->{title} = $self->_lr_trim($tmp->textContent);
        }
        # TitleLong is just text
        if (($tmp) = $one_book->getElementsByTagName('TitleLong'))
        {
            $bookref->{longtitle} = $self->_lr_trim($tmp->textContent);
        }
        # AuthorsText is just text
        if (($tmp) = $one_book->getElementsByTagName('AuthorsText'))
        {
            $bookref->{authors_text} = $self->_lr_trim($tmp->textContent);
        }
        # PublisherText also identifies the publisher record by ID
        if (($tmp) = $one_book->getElementsByTagName('PublisherText'))
        {
            $bookref->{publisher} = $tmp->getAttribute('publisher_id');
            $bookref->{publisher_text} = $self->_lr_trim($tmp->textContent);
        }
        # Look for a list of subjects
        if (($tmp) = $one_book->getElementsByTagName('Subjects'))
        {
            my $subjects = [];
            foreach ($tmp->getElementsByTagName('Subject'))
            {
                push(@$subjects, $_->getAttribute('subject_id'));
            }

            $bookref->{subjects} = $subjects;
        }
        # Look for the list of author records, for their IDs
        if (($tmp) = $one_book->getElementsByTagName('Authors'))
        {
            my $authors = [];
            foreach ($tmp->getElementsByTagName('Person'))
            {
                push(@$authors, $_->getAttribute('person_id'));
            }

            $bookref->{authors} = $authors;
        }
        # Get the Details tag to extract data from the attributes
        if (($tmp) = $one_book->getElementsByTagName('Details'))
        {
            $bookref->{dewey_decimal} = $tmp->getAttribute('dewey_decimal');
            $bookref->{dewey_decimal_normalized} =
                $tmp->getAttribute('dewey_decimal_normalized');
            $bookref->{lcc_number} = $tmp->getAttribute('lcc_number');
            $bookref->{language} = $tmp->getAttribute('language');
            $bookref->{physical_description_text} =
                $tmp->getAttribute('physical_description_text');
            $bookref->{edition_info} = $tmp->getAttribute('edition_info');
            $bookref->{change_time} = $tmp->getAttribute('change_time');
            $bookref->{price_time} = $tmp->getAttribute('price_time');
            if ($CAN_PARSE_DATES)
            {
                $bookref->{change_time_sec} = str2time($bookref->{change_time});
                $bookref->{price_time_sec} = str2time($bookref->{price_time});
            }
        }
        # Look for summary text
        if (($tmp) = $one_book->getElementsByTagName('Summary'))
        {
            $bookref->{summary} = $self->_lr_trim($tmp->textContent);
        }
        # Look for notes text
        if (($tmp) = $one_book->getElementsByTagName('Notes'))
        {
            $bookref->{notes} = $self->_lr_trim($tmp->textContent);
        }
        # Look for URLs text
        if (($tmp) = $one_book->getElementsByTagName('UrlsText'))
        {
            $bookref->{urlstext} = $self->_lr_trim($tmp->textContent);
        }
        # Look for awards text
        if (($tmp) = $one_book->getElementsByTagName('AwardsText'))
        {
            $bookref->{awardstext} = $self->_lr_trim($tmp->textContent);
        }
        # MARC info block
        if (($tmp) = $one_book->getElementsByTagName('MARCRecords'))
        {
            my $marcs = [];
            foreach ($tmp->getElementsByTagName('MARC'))
            {
                push(@$marcs,
                     { library_name => $_->getAttribute('library_name'),
                       last_update  => $_->getAttribute('last_update'),
                       marc_url     => $_->getAttribute('marc_url') });
                if ($CAN_PARSE_DATES and $marcs->[$#$marcs]->{last_update})
                {
                    $marcs->[$#$marcs]->{last_update_sec} =
                        str2time($marcs->[$#$marcs]->{last_update});
                }
            }
            $bookref->{marc} = $marcs;
        }
        # Price info block
        if (($tmp) = $one_book->getElementsByTagName('Prices'))
        {
            my $prices = [];
            foreach ($tmp->getElementsByTagName('Price'))
            {
                push(@$prices,
                     { store_isbn    => $_->getAttribute('store_isbn'),
                       store_title   => $_->getAttribute('store_title'),
                       store_url     => $_->getAttribute('store_url'),
                       store_id      => $_->getAttribute('store_id'),
                       currency_code => $_->getAttribute('currency_code'),
                       is_in_stock   => $_->getAttribute('is_in_stock'),
                       is_historic   => $_->getAttribute('is_historic'),
                       is_new        => $_->getAttribute('is_new'),
                       currency_rate => $_->getAttribute('currency_rate'),
                       price         => $_->getAttribute('price'),
                       check_time    => $_->getAttribute('check_time') });
                if ($CAN_PARSE_DATES and $prices->[$#$prices]->{check_time})
                {
                    $prices->[$#$prices]->{check_time_sec} =
                        str2time($prices->[$#$prices]->{check_time});
                }
            }
            $bookref->{prices} = $prices;
        }

        push(@$books, $class->new($bookref));
    }

    return ($books, { total_results => $total_results, page_size => $page_size,
                      page_number => $page_number,
                      shown_results => $shown_results });
}

###############################################################################
#
#   Sub Name:       parse_categories
#
#   Description:
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $root_elt in      ref       XML::LibXML::Node object
#
#   Returns:        Success:    listref
#                   Failure:    throws Error::Simple
#
###############################################################################
sub parse_categories : RESTRICTED
{
    my ($self, $root_elt) = @_;

    my ($total_results, $page_size, $page_number, $shown_results, $list_elt,
        @catblocks, $cats, $one_cat, $catref, $tmp);
    # The class should already be loaded before we got to this point:
    my $class = WebService::ISBNDB::API->class_for_type('Categories');

    # For now, we aren't interested in the root element (the only useful piece
    # of information in it is the server-time of the request). So skip down a
    # level-- there should be exactly one CategoryList element.
    ($list_elt) = $root_elt->getElementsByTagName('CategoryList');
    throw Error::Simple("No <CategoryList> element found in response")
        unless (ref $list_elt);

    # These attributes live on the CategoryList element
    $total_results = $list_elt->getAttribute('total_results');
    $page_size     = $list_elt->getAttribute('page_size');
    $page_number   = $list_elt->getAttribute('page_number');
    $shown_results = $list_elt->getAttribute('shown_results');

    # Start with no categories in the list, and get the <CategoryData> nodes
    $cats = [];
    @catblocks = $list_elt->getElementsByTagName('CategoryData');
    throw Error::Simple("Number of <CategoryData> blocks does not match " .
                        "'shown_results' value")
        unless ($shown_results == @catblocks);
    for $one_cat (@catblocks)
    {
        # Clean slate
        $catref = {};

        # ID, book count, marc field, marc indicator 1 and marc indicator 2
        # are all attributes of SubjectData
        $catref->{id} = $one_cat->getAttribute('category_id');
        $catref->{parent} = $one_cat->getAttribute('parent_id');
        # Name is just text
        if (($tmp) = $one_cat->getElementsByTagName('Name'))
        {
            $catref->{name} = $self->_lr_trim($tmp->textContent);
        }
        # The <Details> element holds some data in attributes
        if (($tmp) = $one_cat->getElementsByTagName('Details'))
        {
            $catref->{summary} =
                $self->_lr_trim($tmp->getAttribute('summary'));
            $catref->{depth} = $tmp->getAttribute('depth');
            $catref->{element_count} = $tmp->getAttribute('element_count');
        }
        # Look for a list of sub-categories and save the IDs
        if (($tmp) = $one_cat->getElementsByTagName('SubCategories'))
        {
            my $sub_categories = [];
            foreach ($tmp->getElementsByTagName('SubCategory'))
            {
                push(@$sub_categories, $_->getAttribute('id'));
            }

            $catref->{sub_categories} = $sub_categories;
        }

        push(@$cats, $class->new($catref));
    }

    return ($cats, { total_results => $total_results, page_size => $page_size,
                     page_number => $page_number,
                     shown_results => $shown_results });
}

###############################################################################
#
#   Sub Name:       parse_publishers
#
#   Description:
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $root_elt in      ref       XML::LibXML::Node object
#
#   Returns:        Success:    listref
#                   Failure:    throws Error::Simple
#
###############################################################################
sub parse_publishers : RESTRICTED
{
    my ($self, $root_elt) = @_;

    my ($total_results, $page_size, $page_number, $shown_results, $list_elt,
        @pubblocks, $pubs, $one_pub, $pubref, $tmp);
    # The class should already be loaded before we got to this point:
    my $class = WebService::ISBNDB::API->class_for_type('Publishers');

    # For now, we aren't interested in the root element (the only useful piece
    # of information in it is the server-time of the request). So skip down a
    # level-- there should be exactly one PublisherList element.
    ($list_elt) = $root_elt->getElementsByTagName('PublisherList');
    throw Error::Simple("No <PublisherList> element found in response")
        unless (ref $list_elt);

    # These attributes live on the PublisherList element
    $total_results = $list_elt->getAttribute('total_results');
    $page_size     = $list_elt->getAttribute('page_size');
    $page_number   = $list_elt->getAttribute('page_number');
    $shown_results = $list_elt->getAttribute('shown_results');

    # Start with no publishers in the list, and get the <PublisherData> nodes
    $pubs = [];
    @pubblocks = $list_elt->getElementsByTagName('PublisherData');
    throw Error::Simple("Number of <PublisherData> blocks does not match " .
                        "'shown_results' value")
        unless ($shown_results == @pubblocks);
    for $one_pub (@pubblocks)
    {
        # Clean slate
        $pubref = {};

        # ID is an attribute of PublisherData
        $pubref->{id} = $one_pub->getAttribute('publisher_id');
        # Name is just text
        if (($tmp) = $one_pub->getElementsByTagName('Name'))
        {
            $pubref->{name} = $self->_lr_trim($tmp->textContent);
        }
        # Details gives the location in an attribute
        if (($tmp) = $one_pub->getElementsByTagName('Details'))
        {
            $pubref->{location} = $tmp->getAttribute('location');
        }
        # Look for a list of categories and save the IDs
        if (($tmp) = $one_pub->getElementsByTagName('Categories'))
        {
            my $categories = [];
            foreach ($tmp->getElementsByTagName('Category'))
            {
                push(@$categories, $_->getAttribute('category_id'));
            }

            $pubref->{categories} = $categories;
        }

        push(@$pubs, $class->new($pubref));
    }

    return ($pubs, { total_results => $total_results, page_size => $page_size,
                     page_number => $page_number,
                     shown_results => $shown_results });
}

###############################################################################
#
#   Sub Name:       parse_subjects
#
#   Description:
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $root_elt in      ref       XML::LibXML::Node object
#
#   Returns:        Success:    listref
#                   Failure:    throws Error::Simple
#
###############################################################################
sub parse_subjects : RESTRICTED
{
    my ($self, $root_elt) = @_;

    my ($total_results, $page_size, $page_number, $shown_results, $list_elt,
        @subjectblocks, $subjects, $one_subject, $subjectref, $tmp);
    # The class should already be loaded before we got to this point:
    my $class = WebService::ISBNDB::API->class_for_type('Subjects');

    # For now, we aren't interested in the root element (the only useful piece
    # of information in it is the server-time of the request). So skip down a
    # level-- there should be exactly one SubjectList element.
    ($list_elt) = $root_elt->getElementsByTagName('SubjectList');
    throw Error::Simple("No <SubjectList> element found in response")
        unless (ref $list_elt);

    # These attributes live on the SubjectList element
    $total_results = $list_elt->getAttribute('total_results');
    $page_size     = $list_elt->getAttribute('page_size');
    $page_number   = $list_elt->getAttribute('page_number');
    $shown_results = $list_elt->getAttribute('shown_results');

    # Start with no subjects in the list, and get the <SubjectData> nodes
    $subjects = [];
    @subjectblocks = $list_elt->getElementsByTagName('SubjectData');
    throw Error::Simple("Number of <SubjectData> blocks does not match " .
                        "'shown_results' value")
        unless ($shown_results == @subjectblocks);
    for $one_subject (@subjectblocks)
    {
        # Clean slate
        $subjectref = {};

        # ID, book count, marc field, marc indicator 1 and marc indicator 2
        # are all attributes of SubjectData
        $subjectref->{id} = $one_subject->getAttribute('subject_id');
        $subjectref->{book_count} = $one_subject->getAttribute('book_count');
        $subjectref->{marc_field} = $one_subject->getAttribute('marc_field');
        $subjectref->{marc_indicator_1} =
            $one_subject->getAttribute('marc_indicator_1');
        $subjectref->{marc_indicator_2} =
            $one_subject->getAttribute('marc_indicator_2');
        # Name is just text
        if (($tmp) = $one_subject->getElementsByTagName('Name'))
        {
            $subjectref->{name} = $self->_lr_trim($tmp->textContent);
        }
        # Look for a list of categories and save the IDs
        if (($tmp) = $one_subject->getElementsByTagName('Categories'))
        {
            my $categories = [];
            foreach ($tmp->getElementsByTagName('Category'))
            {
                push(@$categories, $_->getAttribute('category_id'));
            }

            $subjectref->{categories} = $categories;
        }

        push(@$subjects, $class->new($subjectref));
    }

    return ($subjects, { total_results => $total_results,
                         page_size => $page_size,
                         page_number => $page_number,
                         shown_results => $shown_results });
}

1;

=pod

=head1 NAME

WebService::ISBNDB::Agent::REST - Agent sub-class for the REST protocol

=head1 SYNOPSIS

This module should not be directly used by user applications.

=head1 DESCRIPTION

This module implements the REST-based communication protocol for getting data
from the B<isbndb.com> service. At present, this is the only protocol the
service supports.

=head1 METHODS

This class provides the following methods, most of which are restricted to
this class and any sub-classes of it that may be written:

=over 4

=item parse_authors($ROOT) (R)

=item parse_books($ROOT) (R)

=item parse_categories($ROOT) (R)

=item parse_publishers($ROOT) (R)

=item parse_subjects($ROOT) (R)

Each of these parses the XML response for the corresponding API call. The
C<$ROOT> parameter is a B<XML::LibXML::Node> object, obtained from parsing
the XML returned by the service.

Each of these returns a list-reference of objects, even when there is only
one result value. All of these methods are restricted to this class and
its decendants.

=item request($OBJ, $ARGS) (R)

Use the B<LWP::UserAgent> object to make a request on the remote service.
C<$OBJ> indicates what type of data request is being made, and C<$ARGS> is a
hash-reference of arguments to be passed in the request. The return value is
an object of the B<WebService::ISBNDB::Iterator> class.

This method is restricted to this class, and is the required overload of the
request() method from the parent class (L<WebService::ISBNDB::Agent>).

=item request_method($OBJ, $ARGS)

Returns the HTTP method (GET, POST, etc.) to use when making the request. The
C<$OBJ> and C<$ARGS> parameters may be used to determine the method (in the
case of this protocol, they are ignored since B<GET> is always the chosen
HTTP method).

=item request_uri($OBJ, $ARGS)

Returns the complete HTTP URI to use in making the request. C<$OBJ> is used
to derive the type of data being fetched, and thus the base URI to use. The
key/value pairs in the hash-reference provided by C<$ARGS> are used in the
REST protocol to set the query parameters that govern the request.

=item protocol([$TESTVAL])

With no arguments, returns the name of this protocol as a simple string. If
an argument is passed, it is tested against the protocol name to see if it
is a match, returning a true or false value as appropriate.

=back

The class also implements a constructor method, which is needed to co-operate
with the parent class under B<Class::Std> structure. You should generally not
have to call the constructor directly:

=over 4

=item new([$ARGS])

Calls into the parent constructor with any arguments passed in.

=back

=head1 CAVEATS

The data returned by this class is only as accurate as the data retrieved from
B<isbndb.com>.

The list of results from calling search() is currently limited to 10 items.
This limit will be removed in an upcoming release, when iterators are
implemented.

=head1 SEE ALSO

L<WebService::ISBNDB::Agent>, L<WebService::ISBNDB::Iterator>,
L<LWP::UserAgent>

=head1 AUTHOR

Randy J. Ray E<lt>rjray@blackperl.comE<gt>

=head1 LICENSE

This module and the code within are released under the terms of the Artistic
License 2.0 (http://www.opensource.org/licenses/artistic-license-2.0.php). This
code may be redistributed under either the Artistic License or the GNU
Lesser General Public License (LGPL) version 2.1
(http://www.opensource.org/licenses/lgpl-license.php).

=cut
