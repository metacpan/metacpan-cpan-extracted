use Test::More qw(no_plan);
use lib 't/lib';
use Test::Exception;
use Text::Livedoor::Wiki;

{
    my $parser = Text::Livedoor::Wiki->new( { block_plugins => ['NoGetBlock'] } );
    dies_ok { $parser->parse('hoge'); } 'implement me';

}

{
    my $parser = Text::Livedoor::Wiki->new( { block_plugins => ['NoRuleBlock'] } );
    dies_ok { $parser->parse('hoge'); } 'implement me';

}

