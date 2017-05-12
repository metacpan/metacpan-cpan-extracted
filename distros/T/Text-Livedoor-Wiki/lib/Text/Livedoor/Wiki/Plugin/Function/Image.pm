package Text::Livedoor::Wiki::Plugin::Function::Image;
use warnings;
use strict;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
use Text::Livedoor::Wiki::Utils;
__PACKAGE__->function_name('ref');

sub prepare_args {
    my $class= shift;
    my $args = shift;
    my $my_args = {};

    # no args
    die 'no args' unless scalar @$args;  

    # image url
    my $image_url = $args->[0];
    die 'not image url' unless Text::Livedoor::Wiki::Utils::is_image_url( $image_url );
    $my_args->{url} = $image_url;

    # width , heigth , align
    my $flg = 0;
    for(@$args) {
        if ( $_ =~ /^\d+$/ ) {
            if($flg ==0 ){
                $my_args->{width} = $_;
                $flg =1;
            }
            elsif( $flg == 1 ) {
                $my_args->{height} = $_;
                $flg++;
            }
        }
        elsif( $_ eq '' ) {
            $flg = 1 if $flg == 0;
        }
        elsif( $_ =~ /^left|right$/i ) {
            $my_args->{align} = lc $_;
        }
        elsif( $_ eq 'no_link' ) {
            $my_args->{no_link} = 1;
        }
    }
    return $my_args;
}
sub prepare_value {
    my $class= shift;
    my $value = shift || '';
    return Text::Livedoor::Wiki::Utils::escape( $value );
}

sub process {
    my ( $class, $inline, $data ) = @_;
    my $args  = $data->{args};
    my $value = $data->{value};

    # build attr
    my $width  = exists $args->{width}  ? ' width="' . $args->{width} . '"' : '';
    my $height = exists $args->{height} ? ' height="' . $args->{height} . '"' : '';
    my $alt    = length($value)         ? ' alt="' . $value . '"' : '';
    my $align  = exists $args->{align}  ? ' align="' . $args->{align} . '"' : '';
     
    # done
    if( $args->{no_link} ) {
        return sprintf( '<img src="%s" border="0"%s%s%s%s />' , $data->{args}{url} , $width,$height,$alt,$align );
    }
    else {
        return sprintf( '<a href="%s"><img src="%s" border="0"%s%s%s%s /></a>' , $data->{args}{url} ,$data->{args}{url} , $width,$height,$alt,$align );
    }

}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::Image - Image Function Plugin

=head1 DESCRIPTION

put your picture everywhere!

=head1 SYNOPSIS 

 &ref(http://image.profile.livedoor.jp/icon/polocky_60.gif)
 &ref(http://image.profile.livedoor.jp/icon/polocky_60.gif){hoge hoge"'><}
 &ref(http://image.profile.livedoor.jp/icon/polocky_60.gif,10,10,left)
 &ref(http://image.profile.livedoor.jp/icon/polocky_60.gif,left,10,10)
 &ref(http://image.profile.livedoor.jp/icon/polocky_60.gif,left,10)
 &ref(http://image.profile.livedoor.jp/icon/polocky_60.gif,10)

=head1 FUNCTION

=head2 prepare_args 

=head2 prepare_value

=head2 process

=head1 AUTHOR

polocky

=cut
