use strict;
use Test::More;
use Wiki::Toolkit::Formatter::UseMod;

eval { require Test::MockObject; };
if ( $@ ) {
    plan skip_all => "Can't find Test::MockObject";
}

plan tests => 2;

my $wikitext = <<WIKITEXT;

ExistingNode

NonExistentNode

WIKITEXT

my $wiki = Test::MockObject->new;
$wiki->mock( "node_exists",
             sub {
                 my ($self, $node) = @_;
                 return $node eq "ExistingNode" ? 1 : 0;
             } );

my $formatter = Wiki::Toolkit::Formatter::UseMod->new(
    node_prefix => "/wiki/",
    node_suffix => ".html",
    edit_prefix => "/wiki/edit/",
    edit_suffix => ".html",
);

my $html = $formatter->format( $wikitext, $wiki );

like( $html, qr|<a href="/wiki/ExistingNode.html">ExistingNode</a>|,
      "node_suffix works" );
like( $html, qr|<a href="/wiki/edit/NonExistentNode.html">|,
      "edit_suffix works" );
