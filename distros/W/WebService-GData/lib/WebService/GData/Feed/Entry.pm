package WebService::GData::Feed::Entry;
use base 'WebService::GData::Node::Atom::EntryEntity';
use WebService::GData::Serialize;

our $VERSION = 0.01_04;

sub __init {
    my ($this,$params,$request) = @_;	
    $this->SUPER::__init($params);
    $this->{_request}=$request;
    $this->{_serializer}= 'xml';

}

sub serialize_as {
    my ($this,$serializer)=@_;
    $this->{_serializer}= $serializer if($serializer);
    $this->{_serializer};
}

sub serialize {
    my ($this,@args) = @_;
    my $serialize = $this->{_serializer};
    return WebService::GData::Serialize->$serialize($this->_entity,$this->_entity,@args);
}

sub content_type {
    my $this = shift;
    $this->{_content}->type;
}

sub content_source {
    my $this = shift;
    $this->{_content}->src;
}


"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::Feed::Entry - Base class wrapping json atom feed entry tags for google data API v2.

=head1 SYNOPSIS

    use WebService::GData::Feed::Entry;

    my $feed = new WebService::GData::Feed::Entry($jsonfeed->{entry}->[0]);

    $feed->title;
    $feed->author;
    $feed->summary;
    $feed->published;
    $feed->content


=head1 DESCRIPTION

I<inherits from L<WebService::GData::Feed>>

This package wraps the entry tag from a query for a feed using the json format of the Google Data API v2 
(no other format is supported!).
It gives you access to some of the entry tag data via wrapper methods.
Unless you implement a service, you should never instantiate this class directly.


=head3 CONSTRUCTOR

=head3 new

=over

Accept the content of the entry tag from a feed that has been perlified (from_json($json_string)) 
and an optional request object,L<WebService::GData::Base>.

The request object is not use in this class.

=head2 INHERITED METHODS

This package inherits from  L<WebService::GData::Feed>,therefore, you get access to the same methods.
These inherited methods will return the corresponding entry data, not the feed data.

=head3 id

=head3 title

=head3 updated

=head3 category

=head3 link

=head3 author

=head3 etag


I<See L<WebService::GData::Feed> for further information about these methods.>

=head2 GET METHODS

=head3 content

get the content of the entry.

B<Parameters>

=over 4

=item C<none> 


=back

B<Returns>

=over 4

=item C<WebService::GData::Node::Content> 

=back

Example:

    use WebService::GData::Feed::Entry;
    
    my $entry = new WebService::GData::Feed::Entry($entry);
    
    $entry->content->src();#http://www.youtube.com/v/qWAY3...
    
    $entry->content->type();#application/x-shockwave-flash

=back



=head3 content_type

=over

Get the content type of the entry. Shortcut for $entry->content->type.

=head3 content_source

=over

Get the content source of the entry.Shortcut for $entry->content->src.

=head3 published

=over

Get the publication date of the entry.

B<Parameters>

=over 4

=item C<none> - getter

=back

B<Returns>

=over 4

=item C<published:Scalar>

=back

Example:

    use WebService::GData::Feed::Entry;
    
    my $feed = new WebService::GData::Feed::Entry($jsonentry);
    
    $feed->published();#"2010-09-20T13:49:20.028Z"
   

=back


=head2 SET/GET METHODS

All the following methods work as both setter and getters.

=head3 summary

=over

set/get the summary (description) of the entry. Beware that not all services implement this tag.

B<Parameters>

=over 4

=item C<none> - as a getter

=item C<summary:Scalar> as a setter

=back
        
B<Returns>

=over 4

=item C<none> - as a setter

=item C<summary:Scalar> as a getter

=back

Example:

    use WebService::GData::Feed::Entry;
    
    my $entry = new WebService::GData::Feed::Entry();
    
    $entry->summary("This video is about...");
    
    $entry->summary();#This video is about...

=back


=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
