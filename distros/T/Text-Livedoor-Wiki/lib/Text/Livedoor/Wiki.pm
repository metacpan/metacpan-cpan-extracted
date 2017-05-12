package Text::Livedoor::Wiki;

use warnings;
use strict;
use Scalar::Util;
use Text::Livedoor::Wiki::Block;
use Text::Livedoor::Wiki::CatalogKeeper;
use Text::Livedoor::Wiki::Function;
use Text::Livedoor::Wiki::IDKeeper;
use Text::Livedoor::Wiki::Inline;
use Text::Livedoor::Wiki::Plugin;

our $VERSION ='0.02';

# Everybody can not be happy but I am happy.
sub new {
    my $class = shift;
    my $self  = shift || {};
    # * god bless you
    $self = bless $self, $class;

    # * initialize  args
    my $block_plugins   = $self->{block_plugins} ?  $self->{block_plugins} : Text::Livedoor::Wiki::Plugin->block_plugins;
    my $inline_plugins  = $self->{inline_plugins}  ? $self->{inline_plugins} :  Text::Livedoor::Wiki::Plugin->inline_plugins;
    my $function_plugins= $self->{function_plugins} ? $self->{function_plugins} : Text::Livedoor::Wiki::Plugin->function_plugins;
    my $on_mobile       = $self->{on_mobile}        || 0;

    # * creating parser objects
    my $function        = Text::Livedoor::Wiki::Function->new( { plugins => $function_plugins , on_mobile => $on_mobile } );

    $self->{inline} 
        = Text::Livedoor::Wiki::Inline->new({ 
            plugins     => $inline_plugins, 
            function    => $function,
            on_mobile   => $on_mobile 
        });

    # nobody likes memory leak.
    Scalar::Util::weaken($self->{inline});

    $self->{block}
        = Text::Livedoor::Wiki::Block->new({ 
            block_plugins => $block_plugins , 
            inline        => $self->{inline} , 
            on_mobile     => $on_mobile 
        });


    # default options
    $self->{opts} ||= {};
    return $self;
}

sub opts { $Text::Livedoor::Wiki::opts }

sub parse {
    my $self = shift;
    my $text = shift;
    my $opts = shift || {};
    %$opts = ( %{$self->{opts}}, %$opts );

    my $want_pos = delete $opts->{want_pos} ;
    # * creating scrathpad and options which scorpe is only for this parse() , so that this module can be as a Singleton.
    $opts->{name} = $opts->{name} || 'content';
    my $id_keeper = Text::Livedoor::Wiki::IDKeeper->new({ name => $opts->{name} } );
    my $catalog_keeper   = Text::Livedoor::Wiki::CatalogKeeper->new();
    local $Text::Livedoor::Wiki::scratchpad = {};
    local $Text::Livedoor::Wiki::opts      = { id_keeper => $id_keeper , catalog_keeper => $catalog_keeper , %$opts };
    $Text::Livedoor::Wiki::scratchpad->{core}{block_uid} = 0;
    $Text::Livedoor::Wiki::scratchpad->{core}{inline_uid} = 0;
    $Text::Livedoor::Wiki::scratchpad->{core}{block_trigger} = $self->{block}->trigger ;
    $Text::Livedoor::Wiki::scratchpad->{core}{current_pos} = 0;

    $self->_init_text( \$text );
    my $html = $self->{block}->parse( $text );
    $html .= $self->{block}->footer_section();

    if( $want_pos ) { 
        return $Text::Livedoor::Wiki::scratchpad->{core}{h3pos};
    }
    else {
        return $self->_build( $html );
    }
}

sub _init_text() {
    my $self = shift;
    my $text = shift;
    $$text =~ s/\r//g;
    $$text =~ s/\n$//;
}
sub _build {
    my $self     = shift;
    my $sections = shift;
    my $opts     = $self->opts;

    $sections =~ s/<br \/>\n$/\n/;
    # TODO customize class name
    # * build sections
    my $html = qq|<div class="user-area">\n|;
    $html .= $sections;
    $html .=  qq|</div>\n|;

    # * build contents
    if( !$self->{on_mobile} ) {
        my $catalog_keeper = $opts->{catalog_keeper};
        my $contents = $catalog_keeper->contents();
        $html =~ s/\n#contents/\n$contents\n/g;
    } 
    else {
        $html =~ s/\n#contents<br \/>\n/\n/g;
    }

    return $html;

}


1;

=head1 NAME

Text::Livedoor::Wiki - Perl extension for formatting text with livedoor Wiki Style. 

=head1 SYNOPSIS

 use Text::Livedoor::Wiki;
 my $parser = Text::Livedoor::Wiki->new( { opts => { storage => 'http://static.wiki.livedoor.jp/formatter-storage' } } );

 my $data = "* ''polocky''";
 $html = $parser->parse( $data );

=head1 DESCRIPTION

This is livedoor Wiki Style Parser.  you can download CSS and images from http://static.wiki.livedoor.jp/download/livedoor-wiki.0.02.tar.gz

=head1 METHOD

=head2 new

constructor. you can set arguments as hash ref.

=over 4

=item block_plugins

set list of block plugins you want to load. default is Text::Livedoor::Wiki::Plugin->block_plugins

=item inline_plugins

set list of inline plugins you want to load. default is Text::Livedoor::Wiki::Plugin->inline_plugins

=item function_plugins

set list of function plugins you want to load. default is Text::Livedoor::Wiki::Plugin->function_plugins

=item on_mobile

set 1 for mobile mode.

=back

=head2 parse

parse Wiki to HTML.

 $parser->parse( $wiki, { your_options => 'hoge' } );

=head2 opts

get options

=head1 AUTHOR

Polocky

=head1 SEE ALSO

http://wiki.livedoor.com (Japanese)
http://wiki.livedoor.jp/wiki_text/ (Japanese)

=cut
