#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Text::Layout::Markdown;

use parent 'Text::Layout';

#### API
sub new {
    my ( $pkg, @data ) = @_;
    my $self = $pkg->SUPER::new;
    $self;
}

#### API
sub render {
    my ( $self ) = @_;
    my $res = "";
    foreach my $fragment ( @{ $self->{_content} } ) {
	next unless length($fragment->{text});
	my $f = $fragment->{font} || $self->{_currentfont};
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

#### API
sub bbox {
    my ( $self ) = @_;
    [ 0, -5, 10, 15 ];		# dummy
}

#### API
sub load_font {
    my ( $self, $description ) = @_;
    return $description;
}


1;
