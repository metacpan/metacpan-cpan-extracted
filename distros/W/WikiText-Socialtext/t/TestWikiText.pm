package t::TestWikiText;
use Test::Base -Base;

package t::TestWikiText::Filter;
use Test::Base::Filter -base;

sub parse_wikitext {
    eval "require $t::TestWikiText::parser_module; 1" or die;
    eval "require $t::TestWikiText::emitter_module; 1" or die;

    my $parser = $t::TestWikiText::parser_module->new(
        receiver => $t::TestWikiText::emitter_module->new,
    );
    $parser->parse(shift);
}
