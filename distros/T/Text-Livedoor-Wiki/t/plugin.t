use Test::Base qw/no_plan/;
use Text::Livedoor::Wiki::Plugin;

run {
    my $block = shift;
    my $inlines = Text::Livedoor::Wiki::Plugin->inline_plugins;
    @$inlines = sort(@$inlines);
    is_deeply( $inlines , $block->inlines , 'inlines' ); 

    my $blocks = Text::Livedoor::Wiki::Plugin->block_plugins;
    @$blocks= sort(@$blocks);
    is_deeply( $blocks, $block->blocks , 'blocks' ); 

    my $functions = Text::Livedoor::Wiki::Plugin->function_plugins;
    @$functions = sort(@$functions );
    is_deeply( $functions , $block->functions , 'functions' ); 

    my $custom 
        = Text::Livedoor::Wiki::Plugin->inline_plugins({ 
            addition => [qw/Hoge Hage/] , 
            except => [qw/Text::Livedoor::Wiki::Plugin::Inline::Del/ ] ,
            search_path => [qw/Text::Livedoor::Wiki::Plugin::Block/],
        });
    @$custom = sort(@$custom );
    is_deeply( $custom , $block->custom , 'custom' ); 
}

__END__
=== basic
--- custom eval 
 [
          'Hage',
          'Hoge',
          'Text::Livedoor::Wiki::Plugin::Block::Blockquote',
          'Text::Livedoor::Wiki::Plugin::Block::CommentOut',
          'Text::Livedoor::Wiki::Plugin::Block::CopyAndPaste',
          'Text::Livedoor::Wiki::Plugin::Block::DL',
          'Text::Livedoor::Wiki::Plugin::Block::H3',
          'Text::Livedoor::Wiki::Plugin::Block::H4',
          'Text::Livedoor::Wiki::Plugin::Block::H5',
          'Text::Livedoor::Wiki::Plugin::Block::Line',
          'Text::Livedoor::Wiki::Plugin::Block::OL',
          'Text::Livedoor::Wiki::Plugin::Block::Pre',
          'Text::Livedoor::Wiki::Plugin::Block::Table',
          'Text::Livedoor::Wiki::Plugin::Block::Toggle',
          'Text::Livedoor::Wiki::Plugin::Block::UL',
          'Text::Livedoor::Wiki::Plugin::Inline::Bold',
          'Text::Livedoor::Wiki::Plugin::Inline::Break',
          'Text::Livedoor::Wiki::Plugin::Inline::BreakClearAll',
          'Text::Livedoor::Wiki::Plugin::Inline::Email',
          'Text::Livedoor::Wiki::Plugin::Inline::Footnote',
          'Text::Livedoor::Wiki::Plugin::Inline::Function',
          'Text::Livedoor::Wiki::Plugin::Inline::Italic',
          'Text::Livedoor::Wiki::Plugin::Inline::Subscript',
          'Text::Livedoor::Wiki::Plugin::Inline::URL',
          'Text::Livedoor::Wiki::Plugin::Inline::Underbar',
          'Text::Livedoor::Wiki::Plugin::Inline::WikiPage'
        ];
--- inlines eval
[
          'Text::Livedoor::Wiki::Plugin::Inline::Bold',
          'Text::Livedoor::Wiki::Plugin::Inline::Break',
          'Text::Livedoor::Wiki::Plugin::Inline::BreakClearAll',
          'Text::Livedoor::Wiki::Plugin::Inline::Del',
          'Text::Livedoor::Wiki::Plugin::Inline::Email',
          'Text::Livedoor::Wiki::Plugin::Inline::Footnote',
          'Text::Livedoor::Wiki::Plugin::Inline::Function',
          'Text::Livedoor::Wiki::Plugin::Inline::Italic',
          'Text::Livedoor::Wiki::Plugin::Inline::Subscript',
          'Text::Livedoor::Wiki::Plugin::Inline::URL',
          'Text::Livedoor::Wiki::Plugin::Inline::Underbar',
          'Text::Livedoor::Wiki::Plugin::Inline::WikiPage'
        ];
--- blocks eval 
[
          'Text::Livedoor::Wiki::Plugin::Block::Blockquote',
          'Text::Livedoor::Wiki::Plugin::Block::CommentOut',
          'Text::Livedoor::Wiki::Plugin::Block::CopyAndPaste',
          'Text::Livedoor::Wiki::Plugin::Block::DL',
          'Text::Livedoor::Wiki::Plugin::Block::H3',
          'Text::Livedoor::Wiki::Plugin::Block::H4',
          'Text::Livedoor::Wiki::Plugin::Block::H5',
          'Text::Livedoor::Wiki::Plugin::Block::Line',
          'Text::Livedoor::Wiki::Plugin::Block::OL',
          'Text::Livedoor::Wiki::Plugin::Block::Pre',
          'Text::Livedoor::Wiki::Plugin::Block::Table',
          'Text::Livedoor::Wiki::Plugin::Block::Toggle',
          'Text::Livedoor::Wiki::Plugin::Block::UL'
        ];
--- functions eval
[
'Text::Livedoor::Wiki::Plugin::Function::AName',
    'Text::Livedoor::Wiki::Plugin::Function::Align',
    'Text::Livedoor::Wiki::Plugin::Function::Color',
    'Text::Livedoor::Wiki::Plugin::Function::Fukidashi',
    'Text::Livedoor::Wiki::Plugin::Function::GoogleVideo',
    'Text::Livedoor::Wiki::Plugin::Function::Image',
    'Text::Livedoor::Wiki::Plugin::Function::Jimakuin',
    'Text::Livedoor::Wiki::Plugin::Function::Lislog',
    'Text::Livedoor::Wiki::Plugin::Function::Pad',
    'Text::Livedoor::Wiki::Plugin::Function::Size',
    'Text::Livedoor::Wiki::Plugin::Function::Superscript',
    'Text::Livedoor::Wiki::Plugin::Function::Youtube'
    ];
