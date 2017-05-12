package Text::Livedoor::Wiki::Plugin::Function::Youtube;
use warnings;
use strict;
use Text::Livedoor::Wiki::Utils;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
__PACKAGE__->function_name('youtube');

sub prepare_args {
    my $class= shift;
    my $args = shift;
    # no args
    die 'no arg' unless scalar @$args ;

    # no code
    my $url = $args->[0];
    my ( $code ) = $url =~ /v=([^&]+)/;
    die 'no code found' unless $code ;

    return { code => $code };
}
sub prepare_value {
    my $class = shift;
    my $value = shift;
    my $width  = 340 ;
    my $height = 280 ;

    # do not need space
    $value ||= '';
    $value =~ s/\s//g;

    ($width , $height ) 
        = Text::Livedoor::Wiki::Utils::get_width_height( $value ,  { width => $width , height => $height }) ;

    return { width => $width , height => $height };
}
sub process {
    my ( $class, $inline, $data ) = @_;
    my $code = $data->{args}{code};
    my $width = $data->{value}{width};
    my $height= $data->{value}{height};

    my $html= <<"END_YOUTUBE_TMPL";
<div class="link_youtube">
<object width="$width" height="$height">
<param name="movie" value="http://www.youtube.com/v/$code">
</param><param name="wmode" value="transparent"></param>
<embed src="http://www.youtube.com/v/$code" 
type="application/x-shockwave-flash" wmode="transparent" 
width="$width" height="$height"></embed></object>
</div>
END_YOUTUBE_TMPL

    $html =~ s/\n$//;
    return $html;
}

# XXX only docomo wark the video.
sub process_mobile {
    my ( $class, $inline, $data ) = @_;
    my $code = $data->{args}{code};
    return qq|<a href="http://m.youtube.com/details?v=$code"><img border="0" src="http://img.youtube.com/vi/$code/2.jpg"></a>|;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::Youtube - Youtube Function Plugin

=head1 DESCRIPTION

do you want to see youtube?

=head1 SYNOPSIS

 &youtube(http://jp.youtube.com/watch?v=fEiL5yyNfco)
 &youtube(http://jp.youtube.com/watch?v=fEiL5yyNfco){100,50}

=head1 FUNCTION

=head2 prepare_args

=head2 prepare_value

=head2 process

=head2 process_mobile

=head1 AUTHOR

polocky

=cut
