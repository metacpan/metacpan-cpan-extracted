package Text::Livedoor::Wiki::Plugin::Inline::URL;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);
use Text::Livedoor::Wiki::Utils;

__PACKAGE__->regex( q{((?:http|https|ftp):\/\/[-_.!~*'()a-zA-Z0-9;/?:@&=+$,%#]+)});
__PACKAGE__->n_args(2);

sub process {
    my ( $class, $inline, $url ) = @_;
    return qq|<a href="$url"><img src="$url" border="0"/></a>| if Text::Livedoor::Wiki::Utils::is_image_url( $url );
    my $label = $class->_cut( $url );
    return qq{<a href="$url" class=\"outlink\">$label</a>};

}

sub _cut {
    my $class= shift;
    my $url  = shift;
    if ( length $url > 50 ) {
        return substr($url , 0 , 50 ) . '...';
    }
    return $url;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::URL - URL Inline Plugin

=head1 DESCRIPTION

make URL linkable.

=head1 SYNOPSIS

 http://wiki.livedoor.com

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
