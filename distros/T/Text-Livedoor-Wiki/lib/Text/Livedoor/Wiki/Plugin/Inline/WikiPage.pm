package Text::Livedoor::Wiki::Plugin::Inline::WikiPage;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);
use Text::Livedoor::Wiki::Utils;

__PACKAGE__->regex(q{\[\[((?:[^>\]]+>{1,3})?)([^\]]+)\]\]});
__PACKAGE__->n_args(2);

sub process {
    my ( $class , $inline , $label , $pagename  ) = @_;
    if( $label ) {
        $label =~ s/>$//;
    }
    else {
        $label = $pagename;
    }
    $label = Text::Livedoor::Wiki::Utils::escape( $label );
    if ( $pagename =~ /^(http|https|ftp):\/\// ) {
        my $url = Text::Livedoor::Wiki::Utils::escape($pagename);
        return qq|<a href="$url" class="outlink">$label</a>|;
    }
    else {
        $pagename = Text::Livedoor::Wiki::Utils::sanitize_uri($pagename);
        my $base_url = $class->opts->{inline_wikipage_base_url} || '/';
        return qq|<a href="$base_url$pagename">$label</a>|;
    }
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::WikiPage - wikipage link Inline Plugin

=head1 DESCRIPTION

wikipage link. do start with http:// ;-p

=head1 SYNOPSIS

 [[PageName]]
 [[Page Name Label>PageName]]
 [[livedoor wiki>http://wiki.livedoor.com]]

=head1 opts

=head2 inline_wikipage_base_url 

you can set base URL

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
