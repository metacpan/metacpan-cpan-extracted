package Text::Livedoor::Wiki::Utils;
use warnings;
use strict;

sub escape {
    my $str = shift;

    #$str =~ s/&/&amp;/g; allow user to use html escape.
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/"/&quot;/g;

    return $str;

}

sub escape_more {
    my $str = shift;
    $str =~ s/&/&amp;/g; 
    $str =~ s/#/&#35;/g; # for #contents
    return escape( $str );
}

sub sanitize_uri {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $str
        =~ s/([^A-Za-z0-9;\/\?\:\@\&\=\+\$,\[\]\-\_\.\!\~\*\'\(\)%\#])/'%'.unpack('H2', $1)/eg;
    return $str;
}

sub is_image_url {
    my $url = shift;
    return unless &is_url( $url );
    # bmp >_<
    return $url =~ /\.(jpg|jpeg|png|gif|bmp)(\?.*|#.*)?$/i ? 1 : 0; 
}
sub is_url {
    my $url = shift;
    return $url =~ /^(?:http|https|ftp):\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+$/ ? 1 : 0;
}

sub get_width_height {
    my $value= shift;
    my $default = shift;

    my $width  = $default->{width};
    my $height = $default->{height};

    if ($value =~  m/(\d+),(\d+)/ ) {
        ($width , $height ) = $value =~ m/(\d+),(\d+)/;
    }
    elsif($value =~  m/,(\d+)/ ) {
        ( $height ) = $value =~ m/,(\d+)/;
    }
    elsif($value =~ m/(\d+)/ ) {
        ( $width ) = $value =~ m/(\d+)/;
    }

    return ( $width , $height );
}
1;

=head1 NAME

Text::Livedoor::Wiki::Utils - utilities

=head1 DESCRIPTION

utilities

=head1 FUNCTION

=head2 escape

escape HTML 

=head2 escape_more

escape more HTML 

=head2 get_width_height

getting width and height

=head2 is_image_url

check its image URL or not

=head2 is_url

check its URL or not

=head2 sanitize_uri

sanitize URL 

=head1 AUTHOR

polocky

=cut
