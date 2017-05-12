package Text::Livedoor::Wiki::Plugin::Function::Jimakuin;
use warnings;
use strict;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
use Text::Livedoor::Wiki::Utils;
__PACKAGE__->function_name('jimakuin');

sub prepare_args {
    my $class= shift;
    my $args = shift;
    die 'no arg' unless scalar @$args ;
    my $url = $args->[0];
    die 'url is not invalid' unless  $url =~ m{^http://(?:[a-zA-Z0-9\-]+\.)?jimaku\.in/w/([a-zA-Z0-9\_][^/]+)/([a-zA-Z0-9\_][^/]+)}i;
    my ( $code1 , $code2 ) = $url =~ m{^http://(?:[a-zA-Z0-9\-]+\.)?jimaku\.in/w/([a-zA-Z0-9\_][^/]+)/([a-zA-Z0-9\_][^/]+)};
    return { url => $url , code1 => $code1 , code2 => $code2 };
}
sub prepare_value {
    my $class = shift;
    my $value = shift || '';
    my $width = 425;
    my $height= 380;

    ($width , $height ) 
        = Text::Livedoor::Wiki::Utils::get_width_height( $value ,  { width => $width , height => $height }) ;
    return { width => $width , height => $height };
}

sub process {
    my ( $class, $inline, $data ) = @_;
    my $url  = $data->{args}{url};
    my $code1= $data->{args}{code1};
    my $code2= $data->{args}{code2};
    my $width = $data->{value}{width};
    my $height= $data->{value}{height};

my $html = <<"END_JIMAKUIN_TMPL";
<div class="link_jimakuin">
<object width="$width" height="$height">
<param name="movie" value="http://swf.jimaku.in/v/$code1/$code2">
</param>
<param name="wmode" value="transparent"></param>
<embed src="http://swf.jimaku.in/v/$code1/$code2" 
type="application/x-shockwave-flash" wmode="transparent" 
width="$width" height="$height"></embed></object>
</div>
END_JIMAKUIN_TMPL

$html =~ s/\n$//;

return $html ;

}

sub process_mobile { '' }

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::Jimakuin - jimaku.in Function Plugin

=head1 DESCRIPTION

lets watch and read!

=head1 SYNOPSIS

 &jimakuin(http://jimaku.in/w/kdtdRNTdNb8/oTkZXUNFw_B)
 &jimakuin(http://jimaku.in/w/kdtdRNTdNb8/oTkZXUNFw_B){100,200}
 &jimakuin(http://jimaku.in/w/kdtdRNTdNb8/oTkZXUNFw_B){100}
 &jimakuin(http://jimaku.in/w/kdtdRNTdNb8/oTkZXUNFw_B){,200}

=head1 FUNCTION

=head2 prepare_args

=head2 prepare_value

=head2 process

=head2 process_mobile

=head1 AUTHOR

polocky

=cut
