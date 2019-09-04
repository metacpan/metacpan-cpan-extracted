#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Text::Layout::Markdown;

sub init {
    my ( $pkg, @args ) = @_;
    bless {} => $pkg;
}

sub render {
    my ( $ctx ) = @_;
    my $res = "";
    foreach my $fragment ( @{ $ctx->{_content} } ) {
	next unless length($fragment->{text});
	my $f = $fragment->{font} || $ctx->{_currentfont};
	my $open = "";
	my $close = "";
	if ( $f->{style} eq "italic" ) {
	    $open = $close = "_"
	}
	if ( $f->{weight} eq "bold" ) {
	    $open = "**$open";
	    $close = "$close**";
	}

	if ( $res =~ /(.*)\Q$close\E$/ ) {
	    $res = $1;
	    $open = "";
	}
	$res .= $open . $fragment->{text} . $close;
    }
    $res;
}

sub bbox {
    my ( $ctx ) = @_;
    [ 0, -5, 10, 15 ];		# dummy
}

sub load_font {
    my ( $ctx, $description ) = @_;
    if ( !$description->{font} && $description->{load} ) {
	$description->{cache}->{font} =
	$description->{font} = $description->{load};
    }
    return $description;
}


1;
