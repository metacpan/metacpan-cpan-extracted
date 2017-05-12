use Test::More qw/no_plan/;
use lib 't/lib';
use warnings;
use strict;
use Text::Livedoor::Wiki;


#  set name.
{
    my $w = Text::Livedoor::Wiki->new();
    like $w->parse("*hoge", { name => 'polocky' } ) , qr/polocky_block_1-body/ , 'setting name test' ;
}

# set custom plugin
{
    my $w = Text::Livedoor::Wiki->new( { 
        inline_plugins => [qw/Text::Livedoor::Wiki::Plugin::Inline::Bold/], 
        block_plugins => [qw/Text::Livedoor::Wiki::Plugin::Block::H3/], 
        function_plugins => [qw/Text::Livedoor::Wiki::Plugin::Function::AName/] 
    });


    is( $w->{block}->blocks->[0] , 'Text::Livedoor::Wiki::Plugin::Block::H3' , 'block');
    is( $w->{inline}->{elements}[0]{regex} , q|''([^']*)''| , 'inline');
    ok( $w->{inline}{function}{function}{aname} , 'function' );

}


# set option
{
    my $w = Text::Livedoor::Wiki->new( { inline_plugins => [qw/MyPlugin::Inline::Test/], opts => { ping => 1 } } );
    like( $w->parse('#####hoge#####' ), qr{<INLINE_2>hoge-1</INLINE_2>} , 'default opts' );

}


