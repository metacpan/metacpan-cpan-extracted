package WWW::Webrobot::HtmlAnalyzer;
use strict;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

use HTML::TokeParser;

=head1 NAME

WWW::Webrobot::HtmlAnalyzer - analyze HTML files for links/images/frames

=head1 SYNOPSIS

 WWW::Webrobot::HtmlAnalyzer -> get_links($scheme, $input)

=head1 DESCRIPTION

Analyze an HTML file.
Returns a list of images, a list of frames and a list of links.

=head1 METHODS

=over

=item WWW::Webrobot::HtmlAnalyzer -> get_links($scheme, $input)

Extract all links found in an HTML page

Parameters:

 $scheme    uri of the content
 $in        content, same form as in HTML::TokeParser->new($in)

 return (\@img, \@frame, \@a);
 \@img      list of images
 \@frame    list of frames
 \@a        list of plain links

=back

=cut

sub get_links  { # static method
    my ($self, $scheme, $in) = @_;
    #print $scheme, " ", $$in;
    my $p = HTML::TokeParser -> new($in);
    my @img = ();
    my @frame = ();
    my @a = ();
    my $refresh = undef;
    while (my $token = $p -> get_tag(qw(img frame a meta))) {
	my ($tag, $attr, $attrseq, $text) = @$token;
	SWITCH: {
	    ($tag eq "img") && do {
		my $href = $attr -> {'src'};
		my $link = URI -> new($href) -> abs($scheme);
		push(@img, $link->as_string()) if $href;
		last SWITCH;
	    };
	    ($tag eq "frame") && do {
		my $href = $attr -> {'src'};
		my $link = URI -> new($href) -> abs($scheme);
		push(@frame, $link->as_string()) if $href;
		last SWITCH;
	    };
	    ($tag eq "a") && do {
		my $href = $attr -> {'href'};
		my $link = URI -> new($href) -> abs($scheme);
		push(@a, $link->as_string()) if $href;
		last SWITCH;
	    };
	    ($tag eq "meta" && ($attr -> {"http-equiv"} || "") eq "refresh") && do {
		my $refresh = $attr -> {'content'} || "-";
		my ($time, $href) = ($refresh =~ /^\s*(\d+);\s+URL\s*=\s*(.*)$/);
		my $link = URI -> new($href) -> abs($scheme);
		$refresh = $link->as_string() if $href;
		last SWITCH;
	    };
	}
    }
    return (\@img, \@frame, \@a, $refresh);
}

1;
