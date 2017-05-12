package XML::Spew::XHTML;

use strict;
use warnings;

use base 'XML::Spew';

our $VERSION = '0.01';

__PACKAGE__->_tags( 
                    qw(html
                       head
                       title
                       base
                       meta
                       link
                       style
                       script
                       noscript
                       body
                       div
                       p
                       h1
                       h2
                       h3
                       h4
                       h5
                       h6
                       ul
                       ol
                       li
                       dl
                       dt
                       dd
                       address
                       hr
                       pre
                       blockquote
                       ins
                       del
                       a
                       span
                       bdo
                       br
                       em
                       strong
                       dfn
                       code
                       samp
                       kbd
                       var
                       cite
                       abbr
                       acronym
                       q
                       sub
                       sup
                       tt
                       i
                       b
                       big
                       small
                       object
                       param
                       img
                       map
                       area
                       form
                       label
                       input
                       select
                       optgroup
                       option
                       textarea
                       fieldset
                       legend
                       button
                       table
                       caption
                       thead
                       tfoot
                       tbody
                       colgroup
                       col
                       tr
                       th
                       td )
                    );
                    

1;

__END__

=head1 NAME

XML::Spew::XHTML - XML::Spew subclass for all the XHMTL tags.

=head1 SYNOPSIS

    my $spew = XML::Spew::XHTML->_new;
    print $s->html( $s->head( $s->title("this is a title") ), 
                    $s->body( $s->div( { class => "foo" }, "this is some content." ) ) );

=head1 DESCRIPTION

This is a subclass of L<XML::Spew|XML::Spew> which impliments the full set of tags for
XHTML 1.0. See the documentation for XML::Spew to use this module.

=head1 AUTHOR

Mike Friedman, C<< <friedo@friedo.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-spew@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Spew>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Mike Friedman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
