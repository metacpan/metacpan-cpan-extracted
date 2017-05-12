package WWW::Page::Modified;

=head1 NAME

WWW::Page::Modified - reports when a page was last modified

=head1 SYNOPSIS

    use WWW::Page::Modified;
    my $dm = WWW::Page::Modified->new;
    print $dm->get_modified('http://www.apple.com/');

=head1 DESCRIPTION

The WWW::Page::Modified module attempts to determine when a web page was
last modified. It does this by examining the HTTP headers, HTML headers
and the body of the HTML document.

It will make use of L<Date::Manip> so it is not necessarily the quickest
of cats.

=cut


use 5.006;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use URI::URL;
use LWP::UserAgent;
use HTTP::Request::Common qw/GET HEAD/;
use HTTP::Date;
use Date::Manip;

use constant DEBUG => 0;
use vars qw/$AUTOLOAD/;
our ( $VERSION ) = '$Revision: 1.2 $ ' =~ /\$Revision:\s+([^\s]+)/;
our @ISA = qw//;

# ========================================================================
#                                                                  Methods

=head1 METHODS

=over 4

=item WWW::Page::Modified->new()

Creates a new date modified checking object.

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

=item $dm->get_modified($url)

Returns the date modified or 0. $url can either be an <HTTP::Response>
object, a URI object or just a string URL.

=cut

sub get_modified
{
    my ($self,$url) = (@_);

    return 0 unless defined $url;
    $url = $self->_get_url_head($url);
    return 0 unless defined $url and $url->is_success;
    my $date = $url->header('Last-Modified');
    if (defined $date)
    {
	$date = str2time($date);
	$date = &ParseDateString("epoch $date");
    }
    else
    {
	my $req = GET $url->base;
	my $resp = $self->_ua->request($req);
	warn Dumper($resp) if DEBUG > 2;
	my $body = $resp->content;
	unless (
	    ($date) = ($body =~ /
	    <meta\s+name="dc\.date\.?modified"\s+[^>]+?
	    \s+content="([^"]+)"[^>]*>
	    /xigsm)
	)
	{
	    unless (
		($date) = ($body =~ /
		last\s(?:modified|updated?).*?\s*(
		    (?:(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*)?
		    \s*\d[^<]*?\d{4})
		/xigsm)
	    )
	    {
		undef $date;
	    }
	}
	if (defined $date)
	{
	    $date = ParseDate($date);
	}
    }
    #warn $date||'[unknown]' if DEBUG;
    warn Dumper($url) if DEBUG > 1;
    
    warn "Returning: ".$url->base.": $date\n" if DEBUG > 0;
    return UnixDate($date => '%s');
}

=back

=cut

# ========================================================================
#                                                                  Private

=begin private

=head1 PRIVATE METHODS

=over 4

=item $dm->_get_url_head($url)

Returns an L<HTTP::Response> object with filled out headers.

=cut

sub _get_url_head
{
    my ($self,$url) = (@_);
    warn "Fetching $url\n" if DEBUG > 0;
    if (not ( ref $url and $url->isa('HTTP::Response') ) )
    {
	my $req = HEAD $url;
	$url = $self->_ua->request($req);
    }
    else
    {
	warn "Already a response object: ".ref($url)."\n" if DEBUG > 0;
    }
    warn Dumper($url) if DEBUG > 2;
    return $url;
}

=item $dm->_ua($ua)

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

    $Id: Modified.pm,v 1.2 2002/02/03 13:10:01 koschei Exp $

=head1 ACKNOWLEDGEMENTS

I would like to thank GRF for having me write this.

=head1 SEE ALSO

Um.


