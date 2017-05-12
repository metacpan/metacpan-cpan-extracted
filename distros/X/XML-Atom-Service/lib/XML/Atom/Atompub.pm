package XML::Atom::Atompub;

use strict;
use warnings;

use XML::Atom::Entry;
use XML::Atom::Service;
use XML::Atom::Thing;

unless (XML::Atom::Entry->can('edited')) {
    *XML::Atom::Entry::edited = sub {
        my($self, $edited) = @_;
        my $ns_uri = $XML::Atom::Service::DefaultNamespace;
        my $app    = XML::Atom::Namespace->new(app => $ns_uri);
        if ($edited) {
            $self->set($app, 'edited', $edited);
        }
        else {
            $self->get($app, 'edited');
        }
    };
}

unless (XML::Atom::Entry->can('control')) {
    XML::Atom::Entry->mk_object_list_accessor('control' => 'XML::Atom::Control');

    package XML::Atom::Control;

    use base qw(XML::Atom::Base);

    __PACKAGE__->mk_elem_accessors(qw(draft));

    sub element_name { 'control' }

    sub element_ns { $XML::Atom::Service::DefaultNamespace }
}

unless (XML::Atom::Content->can('src')) {
    XML::Atom::Content->mk_attr_accessors(qw(src));
}

unless (XML::Atom::Thing->can('alternate_link')) {
    *XML::Atom::Thing::alternate_link = sub {
        my($atom, @args) = @_;
        my @hrefs;
        if (@args) {
            my @links1 = grep { $_->rel && $_->rel ne 'alternate'} $atom->links;
            my @links2 =  map { my $link = XML::Atom::Link->new;
                                $link->rel('alternate');
                                $link->href($_);
                                $link }
                              @args;
            $atom->link( @links1, @links2 );
            @hrefs = @_;
        }
        else {
            @hrefs = map { $_->href } grep { ! $_->rel || $_->rel eq 'alternate' } $atom->links;
        }
        wantarray ? @hrefs : $hrefs[0];
    };
}

for my $rel (qw(self edit edit-media related enclosure via first previous next last)) {
    no strict 'refs'; ## no critic

    my $method = join '_', $rel, 'link';
    $method =~ s/-/_/g;

    next if XML::Atom::Thing->can($method);

    *{"XML::Atom::Thing::$method"} = sub {
        my($atom, @args) = @_;
        my @hrefs;
        if (@args) {
            my @links1 = grep { ! $_->rel || $_->rel ne $rel } $atom->links;
            my @links2 =  map { my $link = XML::Atom::Link->new;
                                $link->rel( $rel );
                                $link->href($_);
                                $link }
                              @args;
            $atom->link( @links1, @links2 );
            @hrefs = @_;
        }
        else {
            @hrefs = map { $_->href } grep { $_->rel && $_->rel eq $rel } $atom->links;
        }
        wantarray ? @hrefs : $hrefs[0];
    };
}

1;
__END__

=head1 NAME

XML::Atom::Atompub 
- Extensions of XML::Atom for the Atom Publishing Protocol


=head1 SYNOPSIS

  use XML::Atom::Entry;
  use XML::Atom::Feed;
  use XML::Atom::Atompub;

  my $entry = XML::Atom::Entry->new;

  # <app:edited>2007-01-01T00:00:00Z</app:edited>
  $entry->edited('2007-01-01T00:00:00Z');

  # <app:control><app:draft>yes</app:draft></app:control>
  my $control = XML::Atom::Control->new;
  $control->draft('yes');
  $entry->control($control);

  # <content type="image/png" src="http://example.com/foo.png"/>
  my $content = XML::Atom::Content->new;
  $content->type('image/png');
  $content->src('http://example.com/foo.png');
  $entry->content($content);

  # <link rel="alternate" href="http://example.com/foo.html"/>
  $entry->alternate_link('http://example.com/foo.html');

  my $feed = XML::Atom::Feed->new;

  # <link rel="self" href="http://example.com"/>
  $feed->self_link('http://example.com');


=head1 METHODS of XML::Atom

Some elements are introduced by the Atom Publishing Protocol, which
are imported into L<XML::Atom> by this module.

=head2 $entry->control([ $control ])

Returns an L<XML::Atom::Control> object representing the control of the 
Entry, or C<undef> if there is no control.

If $control is supplied, it should be an L<XML::Atom::Control> object 
representing the control. For example:

    my $control = XML::Atom::Control->new;
    $control->draft('yes');
    $entry->control($control);

=head2 $entry->edited([ $edited ])

Returns an I<atom:edited> element.

If $edited is given, sets the I<atom:edited> element.


=head2 $content->src([ $src ])

Returns a value of I<src> attribute in I<atom:content> element.

If $src is given, the I<src> attribute is added.


=head2 $atom->alternate_link([ $href ])

Returns a value of I<href> attribute in I<atom:link> element with a link relation of I<alternate>.

If $href is given, an I<atom:link> element with a link relation of I<alternate> is added.


=head2 $atom->self_link([ $href ])

Returns a value of I<href> attribute in I<atom:link> element with a link relation of I<self>.

If $href is given, an I<atom:link> element with a link relation of I<self> is added.


=head2 $atom->edit_link([ $href ])

Returns a value of I<href> attribute in I<atom:link> element with a link relation of I<edit>.

If $href is given, an I<atom:link> element with a link relation of I<edit> is added.


=head2 $atom->edit_media_link([ $href ])

Returns a value of I<href> attribute in I<atom:link> element with a link relation of I<edit-media>.

If $href is given, an I<atom:link> element with a link relation of I<edit-media> is added.


=head2 $atom->related_link([ $href ])

Returns a value of I<href> attribute in I<atom:link> element with a link relation of I<related>.

If $href is given, an I<atom:link> element with a link relation of I<related> is added.


=head2 $atom->enclosure_link([ $href ])

Returns a value of I<href> attribute in I<atom:link> element with a link relation of I<enclosure>.

If $href is given, an I<atom:link> element with a link relation of I<enclosure> is added.


=head2 $atom->via_link([ $href ])

Returns a value of I<href> attribute in I<atom:link> element with a link relation of I<via>.

If $href is given, an I<atom:link> element with a link relation of I<via> is added.


=head2 $atom->first_link([ $href ])

Returns a value of I<href> attribute in I<atom:link> element with a link relation of I<first>.

If $href is given, an I<atom:link> element with a link relation of I<first> is added.


=head2 $atom->previous_link([ $href ])

Returns a value of I<href> attribute in I<atom:link> element with a link relation of I<previous>.

If $href is given, an I<atom:link> element with a link relation of I<previous> is added.


=head2 $atom->next_link([ $href ])

Returns a value of I<href> attribute in I<atom:link> element with a link relation of I<next>.

If $href is given, an I<atom:link> element with a link relation of I<next> is added.


=head2 $atom->last_link([ $href ])

Returns a value of I<href> attribute in I<atom:link> element with a link relation of I<last>.

If $href is given, an I<atom:link> element with a link relation of I<last> is added.


=head1 SEE ALSO

L<XML::Atom>
L<XML::Atom::Service>


=head1 AUTHOR

Takeru INOUE, E<lt>takeru.inoue _ gmail.comE<gt>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
