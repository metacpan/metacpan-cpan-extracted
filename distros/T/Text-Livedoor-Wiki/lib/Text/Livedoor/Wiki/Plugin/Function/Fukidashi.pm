package Text::Livedoor::Wiki::Plugin::Function::Fukidashi;
use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Function);
use Text::Livedoor::Wiki::Utils;

__PACKAGE__->function_name('fukidashi');

sub prepare_args {
    my $class= shift;
    my $args = shift;
    my $image_url = '';
    my $location  = 'left';

    my $icon = scalar @$args ? $args->[0] : '' ;
    my $type = '';
    # livedoor icon
    if( $icon =~ /^[a-zA-Z0-9_]+$/ ) {
        $type = 'livedoor_id';
    # image 
    }elsif( Text::Livedoor::Wiki::Utils::is_image_url( $icon ) ){
        $type = 'image';
    # default
    }else {
        $type = 'image';
        $icon = $class->default_icon;
    }

    # potision
    if( scalar @$args == 2 ) {
        my $loc = $args->[1] ;
        $location = $loc if $loc eq 'right';
    }

    # return result
    return { type => $type, icon => $icon , location => $location }

}

sub process {
    my ( $class, $inline , $data ) = @_;
    my $value    = $inline->parse($data->{value} );
    my $icon     = $data->{args}{icon};
    my $location = $data->{args}{location};
    my $type     = $data->{args}{type};

    if( $type eq 'livedoor_id' ) {
        $icon = qq|<a target="_blank" title="$icon" href="http://profile.livedoor.com/$icon/"><img src="http://image.profile.livedoor.jp/icon/${icon}_60.gif" /></a>|;
    }else {
        $icon = qq|<img src="$icon" />|;
    }

    return qq|<div class="BOX-balloon BOX-balloon-$location">\n<div class="BOX-balloon-image">$icon</div><div class="BOX-balloon-text"><div class="balloon-top"><div class="balloon-top-inner"></div></div><div class="balloon-body"><div class="balloon-body-inner"><div class="balloon-body-inner2">$value</div></div></div>\n<div class="balloon-bottom"><div class="balloon-bottom-inner"></div></div>\n</div><!-- /BOX-balloon-text -->\n</div><!-- /BOX-balloon -->\n|;
}

sub default_icon {
    my $class =  shift;
    my $default_icon_url = $class->opts->{storage} . '/images/function/fukidashi/icon_guest.gif';
    return $default_icon_url;
}

sub process_mobile {
    my ( $class, $inline , $data ) = @_;
    my $value    = $inline->parse($data->{value} );
    my $icon     = $data->{args}{icon};
    my $location = $data->{args}{location};
    my $type     = $data->{args}{type};

    if( $type eq 'livedoor_id' ) {
        $icon = qq|<a target="_blank" title="$icon" href="http://profile.livedoor.com/$icon/"><img src="http://image.profile.livedoor.jp/icon/${icon}_16.gif" /></a>|;
    }
    else {
        $icon = qq|<img width="16" height="16"src="$icon">|;
    }

    return $icon . $value ;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::Fukidashi - Fukidashi Function Plugin

=head1 DESCRIPTION

Everybody likes a good looking Fukidashi.

=head1 SYNOPSIS 

 &fukidashi(polocky){i am polocky}
 &fukidashi(polocky,right){i am polocky}
 &fukidashi(polocky,left){i am polocky}
 &fukidashi(,right){i am polocky}
 &fukidashi(){i am polocky}
 &fukidashi(http://image.livedoor.com/img/top/10/logo.gif){i am polocky}

=head1 CSS

DOCUMENT ME

=head1 FUNCTION

=head2 prepare_args

=head2 process

=head2 default_icon

=head2 process_mobile

=head1 AUTHOR

polocky

=cut
