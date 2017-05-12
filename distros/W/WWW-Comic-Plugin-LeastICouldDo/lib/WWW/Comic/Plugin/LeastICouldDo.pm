package WWW::Comic::Plugin::LeastICouldDo;

use warnings;
use strict;
use Carp;
use XML::Simple;

use vars qw($VERSION @ISA %COMICS);
our $VERSION = '0.01';
@ISA = qw(WWW::Comic::Plugin);
%COMICS = (leasticoulddo => 'LeastICouldDo');

# $Id: LeastICouldDo.pm 388 2008-06-26 14:56:37Z davidp $

=head1 NAME

WWW::Comic::Plugin::LeastICouldDo - WWW::Comic plugin to fetch LeastICouldDo comic


=head1 SYNOPSIS

See L<WWW::Comic> for full details, but here's a brief example:

 use WWW::Comic;
 my $wc = new WWW::Comic;
 my $latest_candh_strip_url 
    = WWW::Comic->strip_url(comic => 'LeastICouldDo');
 

=head1 DESCRIPTION

A plugin for L<WWW::Comic> to fetch the LeastICouldDo comic from
http://www.leasticoulddo.com/

See L<WWW::Comic> and L<WWW::Comic::Plugin> for information on the WWW::Comic
interface.


=head1 FUNCTIONS

=over 4

=item new

Constructor - see L<WWW::Comic> for usage

=cut


sub new {
    my $class = shift;
    my $self = { homepage => 'http://www.leasticoulddo.com/' };
    bless $self, $class;
    return $self;
}

=item strip_url

Returns the URL to the current strip image (or, if given the 'id' param,
the URL to that particular strip)

=cut

sub strip_url {
    my $self = shift;
    my %param = @_;
    
    my $stripstub = 'http://archive.leasticoulddo.com/strips';

    if ($param{id}) {
        # we know what the URL will be
        # TODO: maybe fetch it to make sure it's actually valid?
        return "$stripstub/$param{id}.gif";
    }

    # the latest comic will be found at /strips/comic.gif - but that's not
    # much good for anything that expects each strip to have a different
    # URL.  So, instead, we'll need to parse the RSS feed and return the
    # first comic from the feed (which will have the proper URL).
    my $feedurl = 'http://feeds.feedburner.com/LICD';
    my $response = $self->_new_agent->get($feedurl);
    if ($response->is_success) {
        my $rss = XML::Simple::XMLin($response->content);

        if (!$rss) {
            carp "Failed to parse RSS feed";
            return;
        }

        item:
        for my $item (@{ $rss->{channel}->{item} }) {
            next item if $item->{category} ne 'Comic';

            if (my($id) = $item->{guid}->{content} =~ m{comic/([0-9]+)$})
            {
                # bingo, found the first comic listed in the feed:
                return "$stripstub/$id.gif";
            }
        }
            
        # we should not get here in normal operation:
        carp "Failed to find comics in RSS feed";
        return;
        
    } else {
        carp "Failed to fetch $feedurl - " . $response->status_line;
        return;
    }
    
}


=back

=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-www-comic-plugin-LeastICouldDo at rt.cpan.org>,
or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Comic-Plugin-LeastICouldDo>.
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Comic::Plugin::LeastICouldDo


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Comic-Plugin-LeastICouldDo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Comic-Plugin-LeastICouldDo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Comic-Plugin-LeastICouldDo>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Comic-Plugin-LeastICouldDo>

=back


=head1 ACKNOWLEDGEMENTS

To Nicola Worthington (NICOLAW) for writing WWW::Comic

=head1 COPYRIGHT & LICENSE

Copyright 2008 David Precious, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::Comic::Plugin::LeastICouldDo
