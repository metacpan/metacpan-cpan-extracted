package Text::Livedoor::Wiki::Plugin::Function::Pad;
use warnings;
use strict;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
use Text::Livedoor::Wiki::Utils;

use Data::Dumper;

__PACKAGE__->function_name('pad');

sub prepare_args {
    my $class = shift;
    my $args  = shift;
    die 'no arg' unless scalar @$args;
 
    my $pad_type = $args->[0];
    die 'invalid pad type.' unless $pad_type =~ /^(ps3)$/i; # you can add more pad types here such as DS, Xbox and PC

    return { pad_type => lc $pad_type };
}

sub process {
    my ( $class, $inline, $data ) = @_;
    my $pad_type  = $data->{args}{pad_type};
    my $input_str = $data->{value};

    my $parser  = '_' . $pad_type; # specifies parser function by pad type such as _ps3 for ps3
    my @inputs  = split /,/, $input_str;
    my $str;

    for my $input ( @inputs ) {
        $str .= $class->$parser( $input ) if $input;
    }

    my $fixed_str = '<div class="pad"><div class="pad-inner">' . $str . '</div></div>';
    return $fixed_str;
}

sub _ps3 {
    my ( $class, $input ) = @_;

    # for guys with bad typing 
    $input = 'maru'    if ( $input =~ /^(ma[lr]{1}u)$/ );
    $input = 'sankaku' if ( $input =~ /^(san[ck]{1}a[ck]{1}[u]?)$/ );
    $input = 'shikaku' if ( $input =~ /^(s[h]?ikak[u]?)$/ );
    $input = 'batsu'   if ( $input =~ /^(bat[s]?u)$/ );
    $input = 'select'  if ( $input =~ /^(se[lr]{1}ect)$/ );
    $input = 'stick_L' if ( $input =~ /^(stick_[lL]{1})$/ );
    $input = 'stick_R' if ( $input =~ /^(stick_[rR]{1})$/ );

    if ( $input =~ /^(maru|sankaku|shikaku|batsu|start|select|ps|key|stick_[LR]{1}|[lr]{1}[12]{1})$/ ) {
        return '<img src="' . $class->img_base . 'ps3/' . $input . '.gif" />';
    }else {
        # general actions or text
        return $class->_general_action( $input ) || Text::Livedoor::Wiki::Utils::escape( $input );
    }
}

sub _general_action {
    my ( $class, $input ) = @_;

    return $input =~ /^(and|or|plus|push|soft|hard|repeat|long|[1-46-9]{1})$/
        ? '<img src="' . $class->img_base . $input . '.gif" />'
        : 0;
}

sub img_base {
    my $class = shift;
    return $class->opts->{storage} . '/images/function/pad/';
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::Pad - Game Pad Function Plugin

=head1 DESCRIPTION

displays game pad

=head1 SYNOPSIS

 &pad(ps3){sankaku,shikaku}
 &pad(ps3){sankaku,and,shikaku,plus,here goes some text}

=head1 FUNCTION

=head2 prepare_args

determine the pad type.
to add more pad types, add the pad name to the script below
 $pad_type =~ /^(ps3)$/i;
such as 
 $pad_type =~ /^(ps3|Xbox|nintendo)/i;
and create functions _Xbox and _nintendo to deal with game pad oriented buttons.

=head2 process

parses the text into html.

=head2 _ps3

generates buttons that are only used by ps3 pad.

=head2 _general_action

generates actions that are commonly used by many game pads including "push hard", "push repeatedly", "push longer" and so on...

=head2 img_base

set the location of directory for images
general images are stored under storage_dir_name/images/function/pad/
and images for specific game pads arestored under storage_dir_name/images/function/pad/ps3/

=head1 THANKS

thank clouder for giving us this great plugin idea!

=head1 SEE ALSO

=head1 AUTHOR

oklahomer

=cut
