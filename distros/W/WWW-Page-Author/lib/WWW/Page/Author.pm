package WWW::Page::Author;

=head1 NAME

WWW::Page::Author - locates the author of a web page

=head1 SYNOPSIS

    use WWW::Page::Author;
    my $pa = WWW::Page::Author->new;
    print $pa->get_author('http://www.apple.com/');

=head1 DESCRIPTION

The WWW::Page::Author module attempts to determine the author of a web
page. It does this by examining the HTTP headers, HTML headers and the
body of the HTML document.

=cut


use 5.006;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use URI::URL;
use LWP::UserAgent;
use HTTP::Request::Common qw/GET HEAD/;
use Email::Find;

use constant DEBUG => 0;
use vars qw/$AUTOLOAD/;
our ( $VERSION ) = '$Revision: 1.2 $ ' =~ /\$Revision:\s+([^\s]+)/;
our @ISA = qw//;

# ========================================================================
#                                                                  Methods

=head1 METHODS

=over 4

=item WWW::Page::Author->new()

Creates a new author seeking object.

=cut

sub new
{
    my $class = shift;
    $class = ref($class) || $class;

    my $self = {
	ua	=> undef,
    };

    bless $self, $class;
}

=item $pa->get_author($url)

Returns the author of the web page (or site) or undef. $url can either
be an HTTP::Response object, a URI object or just a string URL.

=cut

sub get_author
{
    my ($self,$url) = (@_);

    return 0 unless defined $url;
    $url = $self->_get_url_body($url);
    return '[error]' unless defined $url and $url->is_success;

    my $body = $url->content();
    my $emails = [];
    my $num_found = find_emails($body, sub {
	push @$emails, $_[1];
	return $_[1];
    });

    warn Dumper($emails, scalar @$emails) if DEBUG > 0;

    return undef unless $num_found;

    do {
	my @webs = grep /^webmaster\@/, @$emails;
	@$emails = @webs if @webs;
    };

    return $num_found ? $emails->[@$emails-1] : undef;
}

=back

=cut

# ========================================================================
#                                                                  Private

=begin private

=head1 PRIVATE METHODS

=over 4

=item $pa->_get_url_body($url)

Returns an L<HTTP::Response> object with filled out headers and content.
i.e. it fetches the page in question.

=cut

sub _get_url_body
{
    my ($self,$url) = (@_);
    warn "Fetching $url\n" if DEBUG > 0;
    if (not ( ref $url and $url->isa('HTTP::Response') ) )
    {
	my $req = GET $url;
	$url = $self->_ua->request($req);
    }
    else
    {
	warn "Already a response object: ".ref($url)."\n" if DEBUG > 0;
    }
    warn Dumper($url) if DEBUG > 2;
    return $url;
}

=item $pa->_ua($ua)

Returns the L<LWP::UserAgent> object the module is using. Sets the UA if
a parameter is given.

=cut

sub _ua
{
    my $self = shift;
    $self->{ua} = $_[0] if @_;
    unless (defined $self->{ua})
    {
	my $ua = LWP::UserAgent->new;
	my $name = ref($self);
	$ua->agent($name.'/'.$VERSION);
	$ua->env_proxy();
	$self->_ua($ua);
    }
    return $self->{ua};
}

=back

=end private

=cut

1;
__END__
#
# ========================================================================
#                                                Rest Of The Documentation

=head1 AUTHOR

Iain Truskett <spoon@cpan.org> L<http://eh.org/~koschei/>

Please report any bugs, or post any suggestions, to either the mailing
list at <perl-www@dellah.anu.edu.au> (email
<perl-www-subscribe@dellah.anu.edu.au> to subscribe) or directly to the
author at <spoon@cpan.org>

=head1 PLANS

It needs to cater for more weird and unusual ways of putting dates on
web pages.

=head1 COPYRIGHT

Copyright (c) 2001 Iain Truskett. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

    $Id: Author.pm,v 1.2 2002/02/03 13:35:41 koschei Exp $

=head1 ACKNOWLEDGEMENTS

I would like to thank GRF for having me write this.

=head1 SEE ALSO

Um.


