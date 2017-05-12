package WWW::Twitpic;
use Moose;
extends 'WWW::Twitpic::API';

=head1 NAME

WWW::Twitpic - Use the twitpic.com simple API from our favorite language.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module module is just an interface to the simple api described at L<http://twitpic.com/api.do>

Using this module, you'll easily post images to twitpic.com and to your twitter feed.


    use WWW::Twitpic;

    my $client = WWW::Twitpic->new( 
        username => 'your twitter username',
        password => 'your twitter password'
    );

    my $res = $client->post( '/path/to/image.jpg' => 'Message to post with the image on twitter' );
    
    # $res is a WWW::Twitpic::API::Response
    print $res->is_success ? $res->url : $res->error;


=head1 METHODS

At this moment, this is doing what L<WWW::Twitpic::API> does.

=head2 meta

    See L<Moose>.

=cut

=head1 AUTHOR

Diego Kuperman, C<< <diego at freekeylabs.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-twitpic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Twitpic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Twitpic


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Twitpic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Twitpic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Twitpic>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Twitpic>

=back


=head1 SEE ALSO

    L<WWW::Twitpic::API>
    L<WWW::Twitpic::API::Response>

    L<http://twitpic.com>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Diego Kuperman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
no Moose;
1;
