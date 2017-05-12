package Text::Livedoor::Wiki::Plugin::Function::GoogleVideo;
use warnings;
use strict;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
use Text::Livedoor::Wiki::Utils;
__PACKAGE__->function_name('googlevideo');
__PACKAGE__->operation_regexp(q{(docid=\d+|^\d+$)});

# what's is difference between google video and youtube.
sub prepare_args {
    my $class= shift;
    my $args = shift;

    # no argument
    die 'no arg' unless scalar @$args;

    my ( $docid ) = $args->[0] =~ /(docid=-?\d+|^-?\d+$)/;
    # no doc id
    die 'no docid' unless $docid;

    # do not need it
    $docid =~ s/docid=//;

    # ok
    return { docid => $docid } ;
}
sub prepare_value {
    my $class = shift;
    my $value = shift;
    my $width  = 340;
    my $height = 280;

    # do not need space
    $value ||= '';
    $value =~ s/\s//g;
    ($width , $height ) 
        = Text::Livedoor::Wiki::Utils::get_width_height( $value ,  { width => $width , height => $height }) ;

    return { width => $width , height => $height };
}

sub process {
    my ( $class, $inline , $data ) = @_; 
    my $docid = $data->{args}{docid};
    my $width = $data->{value}{width};
    my $height= $data->{value}{height};

    my $html = <<"END_GOOGLEVIDEO_TMPL";
<div class="link_googlevideo">
<object width="$width" height="$height">
<param name="movie" value="http://video.google.com/googleplayer.swf?docId=$docid">
</param><param name="wmode" value="transparent"></param>
<embed src="http://video.google.com/googleplayer.swf?docId=$docid" 
type="application/x-shockwave-flash" 
style="width:${width}px; height:${height}dpx;" id="VideoPlayback" flashvars="" wmode="opaque">
<param name="wmode" value="opaque" />
</embed></object>
</div>
END_GOOGLEVIDEO_TMPL

    $html =~ s/\n$//;
    return $html;
}

sub process_mobile { '' }

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::GoogleVideo - Google Video Function Plugin

=head1 DESCRIPTION

let's watch google video.

=head1 SYNOPSIS

 &googlevideo(http://video.google.co.jp/videoplay?docid=-694264032177935779&ei=sh8VSsrpFpTewgP-sb1x&q=livedoor+viedo.google)
 &googlevideo(-694264032177935779)
 &googlevideo(-694264032177935779){99,88}
 &googlevideo(-694264032177935779){,99}
 &googlevideo(-694264032177935779){99}
 &googlevideo(-694264032177935779){99,}

=head1 FUNCTION

=head2 prepare_args

=head2 prepare_value

=head2 process

=head2 process_mobile

=head1 AUTHOR

polocky

=cut
