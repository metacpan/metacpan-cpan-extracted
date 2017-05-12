package Text::Livedoor::Wiki::Plugin::Block::CopyAndPaste;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Block);
use Text::Livedoor::Wiki::Utils;

__PACKAGE__->trigger({ start=> '^=\|([a-z0-9A-Z\-_]*)(?:\(([^\)\|]+)\))?\|$' , end  => '^\|\|=$' , escape => 1 });

sub check {
    my $class        = shift;
    my $line        = shift;
    my $args        = shift;
    my $on_next     = $args->{on_next};
    my $id          = $args->{id};
    my $scratchpad  = $Text::Livedoor::Wiki::scratchpad;
    my $row;
    my $option_str;
    my $processing = $scratchpad->{block}{$id}{processing};



    # header
    if (( ( $row, $option_str ) = $line =~ /^=\|([a-z0-9A-Z\-_]*)(?:\(([^\)\|]+)\))?\|$/) && !$processing  && !$on_next ){
        my $res = { id => $id };
        $row ||= 'PLAIN-BOX';
        $res->{class_name} = $row;

        #XXX
        $Text::Livedoor::Wiki::scratchpad->{skip_ajust_block_break} = '1';
        
        my $box = 'pre';
        if ($option_str) {
            my @params = split( ';', $option_str );

            for my $param (@params) {
                my ( $k, $v ) = split( '=', $param );
                if ( $k eq 'box' ) {
                    if ( $v eq 'div' ) {
                        $box = 'div';
                    }
                    elsif( $v eq 'textarea' ) {
                        $box = 'textarea';
                    }
                }
            }
        }
        $res->{box} = $box;
        $scratchpad->{block}{$id}{processing} = 1;
        return $res;
    }
    # end box
    elsif( $line =~ /^\|\|=$/ && $processing && !$on_next ) {
        $scratchpad->{block}{$id}{processing} = 0;
        return { line => '' } ;
    }
    # finalize
    elsif( $on_next && !$processing ) {
        return ;
    }
    # processing
    elsif( $processing ) {
        return { line => $line  };
    }

    # not much
    return;
}

sub get {
    my $class = shift;
    my $block = shift;
    my $inline = shift;
    my $items = shift;
    my $meta = shift @{$items};
    my $box = $meta->{box};
    my $class_name = $meta->{class_name};
    my $id         = $meta->{id};
    my $on_prettyprint = "";
    my @syntax = qw/C CC CPP CS CYC JAVA BSH CSH SH CV PY PERL PL PM RB JS HTML XHTML XML XSL/;
    for my $sh ( @syntax ) {
        if ( $class_name eq $sh ) {
            $on_prettyprint = "prettyprint ";
            last;
        }
    }
    my $data = '';
    $data .= $_->{line} . "\n" for @$items;
    $data =~ s/\n$//;

    $data = Text::Livedoor::Wiki::Utils::escape_more( $data );

    return qq|<$box id="$id" class="$on_prettyprint$class_name">\n| . $data . "</$box>\n";;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block::CopyAndPaste - Copy & Page Block Plugin

=head1 DESCRIPTION

You can escape Wiki format. Just copy and paste!

=head1 SYNOPSIS

 =||
    %%hi mom%%
 ||=

 =|class_name|
  %%hi mom with class name%%
 ||=

 =|HTML|
 <html>
   <title>prettify js class name support.</title>
 </html>
 ||=

=head1 FUNCTION

=head2 check

=head2 get 

=head1 AUTHOR

polocky

=cut
