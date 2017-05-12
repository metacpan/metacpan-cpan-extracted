package WebService::GData::Feed;
use WebService::GData 'private';
use base 'WebService::GData::Node::Atom::FeedEntity';

use WebService::GData::Node::OpenSearch::ItemsPerPage();
use WebService::GData::Node::OpenSearch::StartIndex();
use WebService::GData::Node::OpenSearch::TotalResults();

our $VERSION = 0.01_08;

sub __init {
	my ($this,$params,$request) = @_;
	
	$this->SUPER::__init($params);
	
    $this->{_items_per_page}=new WebService::GData::Node::OpenSearch::ItemsPerPage($this->{_feed}->{'openSearch$itemsPerPage'});
    $this->_entity->child($this->{_items_per_page});
    $this->{_start_index}=new WebService::GData::Node::OpenSearch::StartIndex($this->{_feed}->{'openSearch$startIndex'});
    $this->_entity->child($this->{_start_index});
    
    $this->{_total_results}=new WebService::GData::Node::OpenSearch::TotalResults($this->{_feed}->{'openSearch$totalResults'});
    $this->_entity->child($this->{_total_results});

    $this->{_request}= $request;

}

sub total_items {
    my $this = shift;
    return $this->total_results;
}

sub previous_link {
    my ($this) = @_;
    return $this->get_link('previous');
}

sub next_link {
    my ($this) = @_;
    return $this->get_link('next');
}

#ok, i need to cleanup this mess...
#entry works as a factory and loads the proper entry class
sub entry {
    my ( $this, $wanted_class ) = @_;

    my $entries = $this->{_feed}->{entry} || [];
    $entries = [$entries] if ( ref($entries) ne 'ARRAY' );

    #default to the base Entry class
    my $class = q[WebService::GData::Feed::Entry];

    if ($wanted_class) {
        $class = $wanted_class;
    }
    else {

        #from which service this request comes from...
        my $service = ref($this);

        #what kind of feed is this??
        my $feedType = $this->_get_feed_type;

        if ( $service =~ m/GData::(.*)::/ && $feedType ) {
            my ( $match, $ser ) = $service =~ m/GData::(.*)::/;
            $class = 'WebService::GData::' . $match . '::Feed::' . $feedType;
        }
    }
    {
        no strict 'refs';

        #all entries inherit from WebService::GData::Feed::Entry
        eval("use $class")
          if ( !@{ $class . '::ISA' } );
    }
    my @ret = ();
    foreach my $entry (@$entries) {
        push @ret, $class->new( $entry, $this->{_request} );
    }
    return \@ret;
}

private _get_feed_type => sub {
    my $this = shift;

    my $feedTypeString = '';

    if ( $this->{_category} || $this->{_feed}->{entry}->{category} ) {

        $feedTypeString = $this->{_category}->[0]->{term}
          || $this->{_feed}->{entry}->{category}->[0]->{term};
    }

    #the feed type is after the anchor http://gdata.youtube.com/schemas/2007#video
    my $feedType = ( split( '#', $feedTypeString ) )[1];
    $feedType = "\u$feedType";    #Uppercase to load the proper class
    return $feedType;
};

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::Feed - Base class wrapping json atom feed for google data API v2.

=head1 SYNOPSIS

    use WebService::GData::Feed;

    my $feed = new WebService::GData::Feed($jsonfeed);

    $feed->title;
    $feed->author;
    my @entries = $feed->entry();#send back WebService::GData::Feed::Entry or a service related Entry object 



=head1 DESCRIPTION

I<inherits from L<WebService::GData>>

This package wraps the result from a query using the json format of the Google Data API v2 (no other format is supported!).
It gives you access to some of the data via wrapper methods and works as a factory to get access to the entries for each service.
If you use a YouTube service, calling the entry() method will send you back YouTube::Feed::Entry's. 
If you use a Calendar service, calling the entry() method will send you back a Calendar::Feed::Entry.
By default, it returns a L<WebService::GData::Feed::Entry> which gives you only a read access to the data.
Unless you implement a service, you should not instantiate this class directly.

=head2 CONSTRUCTOR


=head3 new

=over

Create a L<WebService::GData::Feed> instance.

Accept a json feed entry that has been perlified (from_json($json_string)) and an optional request object (L<WebService::GData::Base>).
The request object is passed along each entry classes but the Feed class itself does not use it.

B<Parameters>

=over 4

=item C<json_feed:Object> - a json feed perlified

=item C<request:Object> - a request object L<WebService::GData::Base>

=back

B<Returns> 

=over 4

=item C<WebService::GData::Feed>

=back

=back

=head2 SET/GET METHODS

All the following methods work as both setter and getters.

=head3 title

=over

set/get the title of the feed.

B<Parameters>

=over 4

=item C<none> - as a getter

=item C<title:Scalar> as a setter

=back

B<Returns>

=over 4

=item C<none> - as a setter

=item C<title:Scalar> as a getter

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed();
    
    $feed->title("my Title");
    
    $feed->title();#my Title

=back

=head2 GET METHODS

All the following methods work as getters and do not accept parameters.

=head3 id

=over

Get the id of the feed.

B<Parameters>

=over 4

=item C<none> - getter

=back

B<Returns>

=over 4

=item C<id:Scalar>

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);
    
    $feed->id();#"tag:youtube.com,2008:video"
   

=back


=head3 updated

=over

Get the updated date of the feed.

B<Parameters>

=over 4

=item C<none> - getter

=back

B<Returns>

=over 4

=item C<updated:Scalar>

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);
    
    $feed->updated();#"2010-09-20T13:49:20.028Z"
   

=back


=head3 category

=over

Get the categories of the feed.
At the feed level, it is almost always one category that defines the kind of the feed (video feed, related feed,etc).
The C<entry()> uses this information to load the proper class, ie Video or Comment entries.

B<Parameters>

=over 4

=item C<none> - getter

=back

B<Returns>

=over 4

=item C<categories:Collection> - L<WebService::GData::Collection> containing L<WebService::GData::Node::Category>.

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);
    
    my $categories = $feed->category();
    foreach my $category (@$categories) {
        #$category->scheme,$category->term,$category->label
    }
    
    #search for a particular kind of category
    my $kind = $categories->scheme('kind')->[0];
    
    #json feed category is as below:
    "category": [
      {
       "scheme": "http://schemas.google.com/g/2005#kind",
       "term": "http://gdata.youtube.com/schemas/2007#video"
      }
    ]
      

=back

=head3 etag

=over

Get the etag of the feed. The etag is a unique identifier key to track updates to the document.


B<Parameters>

=over 4

=item C<none> - getter

=back

B<Returns>

=over 4

=item C<etag:Scalar> - the etag value

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);
    
   $feed->etag();#W/\"CkICQX45cCp7ImA9Wx5XGUQ.\"
   

See also L<http://code.google.com/intl/en/apis/gdata/docs/2.0/reference.html#ResourceVersioning> for further information about resource versioning.
      

=back

=head3 author

=over

Get the author of the feed.


B<Parameters>

=over 4

=item C<none> - getter

=back

B<Returns>

=over 4

=item C<author:Collection> - L<WebService::GData::Collection> containing L<WebService::GData::Node::AuthorEntity>.

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);
    
   my $authors=  $feed->author();
   
   foreach my $author (@$authors){
       #$author->name,$author->uri
   }
   
   #raw json feed:
   
   "author": [
     {
       "name": {
        "$t": "YouTube"
       },
       "uri": {
        "$t": "http://www.youtube.com/"
       }
      }
    ],
   
=back

=head2 PAGINATION RELATED METHODS

The following methods sent back information that can be useful to paginate the result.
You get access to the number of result, the number of item sent and the offset from which the result start.

=head3 total_items

=over

Get the total result of the feed.

B<Parameters>

=over 4

=item C<none> - getter

=back

B<Returns>

=over 4

=item C<total_items:Int> - the total number of items 

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);
    
    $feed->total_items();#1000000
    
=back
 

=head3 total_results

=over

Get the total result of the feed. Alias for total_items

B<Parameters>

=over 4

=item C<none> - getter

=back

B<Returns>

=over 4

=item C<total_results:Int> - the total number of items 

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);
    
    $feed->total_results();#1000000
    
=back

=head3 start_index

=over

Get the start number of the feed.

B<Parameters>

=over 4

=item C<none> - getter

=back

B<Returns>

=over 4

=item C<start_index:Int> - the start index of the feed  counting from 1.

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);
    
    $feed->start_index();#1
    
=back

=head3 items_per_page

=over

Get the the number of items sent per result.


B<Parameters>

=over 4

=item C<none> - getter

=back

B<Returns>

=over 4

=item C<items_per_page:Int> - the number of item in the result.

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);
    
    $feed->items_per_page();#25
    
=back

=head3 links

=over

Get the links of the feed in a array reference.	

B<Parameters>

=over 4

=item C<none> - getter

=back

B<Returns>

=over 4

=item C<links:Collection> - L<WebService::GData::Collection> containing L<WebService::GData::Node::Link> instances.
=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);
    
    my $links = $feed->links();
    foreach my $link (@$links){
        #link->rel,$link->type,$link->href
    }
    
    #raw json data:
    
      "link": [
       {
        "rel": "alternate",
        "type": "text/html",
        "href": "http://www.youtube.com"
       },
       {
        "rel": "http://schemas.google.com/g/2005#feed",
        "type": "application/atom+xml",
        "href": "http://gdata.youtube.com/feeds/api/videos"
       },
       {
        "rel": "http://schemas.google.com/g/2005#batch",
        "type": "application/atom+xml",
        "href": "http://gdata.youtube.com/feeds/api/videos/batch"
       }
      ]
    
=back

=head3 get_link

=over

Get a specific link entry by looking in the rel attribute of the link tag.

B<Parameters>

=over 4

=item C<link_type:Scalar> - set the type of link you are looking for.

=back

B<Returns>

=over 4

=item C<undef> - if the link is not found.

=item C<url:Scalar> - the contents in href if the link is found.

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);

    my $previous_url= $feed->get_link('previous');
    
    my $batch_url   = $feed->get_link('batch');


=head3 previous_link

=over

Get a the previous link if set or undef. Shortcut for $feed->get_link('previous');

=head3 next_link

=over

Get a the next link if set or undef. Shortcut for $feed->get_link('next');



=head3 entry

=over

This method return an array reference of Feed::* objects.

It works as a factory by instantiating the proper Feed::* class.

For example,if you read a video feed from a youtube service, it will instantiate the WebService::GData::Youtube::Feed::Video class and feed it the result.

It will look first at the category scheme set in the feed or at the entry category scheme that contains the base schema name of the feed.

If it does not guess properly,you can always specify the name of the package to load as its first argument.


B<Parameters>

=over 4

=item C<class_name::Scalar>* - (optional) Force a specific class to be loaded and do not let entry guess the feed type on its own.

=back

B<Returns>

=over 4

=item C<entries:ArrayRef> - By default it uses L<WebService::GData::Entry::Feed> but will return instances of the found package or of the specified one

=back

Example:

    use WebService::GData::Feed;
    
    my $feed = new WebService::GData::Feed($jsonfeed);
    
    my $entries = $feed->entry('WebService::GData::Feed::Entry');#force a particular class to be used
    my $entries = $feed->entry();#let entry figure it out by looking at the feed meta information.
    
    foreach my $entry (@$entries) {
        
        #$entry->title,$entry->id... all entry sub classes should inherit from WebService::GData::Feed::Entry
    }   

=back

=head2 JSON FEED EXAMPLE

Below is a raw json feed example from querying youtube videos. Only the relevant parts are listed.

The actual feed does contain more information but a possible switch to JSONC, freed of meta information, being possible,
this package only offers wrapper methods to what is relevant in the JSONC context.

    {
     "feed": {
      "gd$etag": "W/\"CkICQX45cCp7ImA9Wx5XGUQ.\"",
      "id": {
       "$t": "tag:youtube.com,2008:videos"
      },
      "updated": {
       "$t": "2010-09-20T13:49:20.028Z"
      },
      "category": [
       {
        "scheme": "http://schemas.google.com/g/2005#kind",
        "term": "http://gdata.youtube.com/schemas/2007#video"
       }
      ],
      "title": {
       "$t": "YouTube Videos"
      },
      "link": [
       {
        "rel": "alternate",
        "type": "text/html",
        "href": "http://www.youtube.com"
       },
       {
        "rel": "http://schemas.google.com/g/2005#feed",
        "type": "application/atom+xml",
        "href": "http://gdata.youtube.com/feeds/api/videos"
       },
       {
        "rel": "http://schemas.google.com/g/2005#batch",
        "type": "application/atom+xml",
        "href": "http://gdata.youtube.com/feeds/api/videos/batch"
       },
       {
        "rel": "self",
        "type": "application/atom+xml",
        "href": "http://gdata.youtube.com/feeds/api/videos?alt=json&start-index=1&max-results=25"
       },
       {
        "rel": "service",
        "type": "application/atomsvc+xml",
        "href": "http://gdata.youtube.com/feeds/api/videos?alt\u003datom-service"
       },
       {
        "rel": "next",
        "type": "application/atom+xml",
        "href": "http://gdata.youtube.com/feeds/api/videos?alt=json&start-index=3&max-results=25"
       }
      ],
      "author": [
       {
        "name": {
         "$t": "YouTube"
        },
        "uri": {
         "$t": "http://www.youtube.com/"
        }
       }
      ],
      "openSearch$totalResults": {
       "$t": 1000000
      },
      "openSearch$startIndex": {
       "$t": 1
      },
      "openSearch$itemsPerPage": {
       "$t": 25
      },
      "entry": [....]#erased as there are implemented in each sub classes
     }
    }



=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
