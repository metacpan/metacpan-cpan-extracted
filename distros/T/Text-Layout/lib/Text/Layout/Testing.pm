#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Text::Layout::Testing;

use parent 'Text::Layout';

use Text::Layout::FontConfig;

my $fc = Text::Layout::FontConfig->new( corefonts => 1 );

#### API
sub new {
    my ( $pkg, @data ) = @_;
    my $self = $pkg->SUPER::new;
    $self->set_font_description( $fc->from_string("Times 10") );
    $self;
}

#### API
sub render {
    my ( $self ) = @_;
    my $res = "Testing 1 2 3";
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

# For testing.
sub _debug_text {
    my $c = $_[0]->{_content};
    for my $f ( @$c ) {
	$f->{font} = $f->{font}->{loader_data} . "(" .
	  join(",", $f->{font}->{family},
	       $f->{font}->{style},
	       $f->{font}->{weight},
	       $f->{font}->{size} // $f->{size}) . ")";
	for ( keys %$f ) {
	    next if defined($f->{$_})
	      && ! ( !$f->{$_} || /col/ && $f->{$_} eq 'black' );
	    delete $f->{$_};
	}
    }
    return $c;
}

1;
