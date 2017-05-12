use lib 'inc';
package TestWikiText;
use Test::Base -Base;

package TestWikiText::Filter;
use Test::Base::Filter -base;

sub parse_wikitext {
    eval "require $TestWikiText::parser_module; 1" or die;
    eval "require $TestWikiText::emitter_module; 1" or die;

    my $parser = $TestWikiText::parser_module->new(
        receiver => $TestWikiText::emitter_module->new,
    );
    $parser->parse(shift);
}
