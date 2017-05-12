package WWW::GoDaddy::REST::Collection;

use Moose;

extends 'WWW::GoDaddy::REST::Resource';

sub items {
    my $self = shift;
    return @{ $self->f_as_resources('data') };
}

1;

=head1 NAME

WWW::GoDaddy::REST::Collection - collection specific resource class

=head1 SYNOPSIS

  $collection = $client->query('myschema',{ 'f' => 'v' });

  # every method from WWW::GoDaddy::REST::Resource is
  # available.  Here are the differences.
  
  @items = $collection->items();

=head1 DESCRIPTION

This is used to represent 'collections' which are very common in the Go Daddy(r)
API specification.

It is a sub class of L<WWW::GoDaddy::REST::Resoure>.

=head1 ATTRIBUTES

See L<WWW::GoDaddy::REST::Resource>.

=head1 METHODS

See L<WWW::GoDaddy::REST::Resource> for more.

=over 4

=item items

Returns the list of resources in the collection.

This overrides the C<items> method in L<WWW::GoDaddy::REST::Resource>.

=back

=head1 CLASS METHODS

See L<WWW::GoDaddy::REST::Resource> for more.

=head1 AUTHOR

David Bartle, C<< <davidb@mediatemple.net> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014 Go Daddy Operating Company, LLC

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.

=cut

