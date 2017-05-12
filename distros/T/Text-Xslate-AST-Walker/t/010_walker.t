use strict;
use warnings;
use Test::More;
use Text::Xslate;

require_ok 'Text::Xslate::AST::Walker';

my $kolon_template = <<EOS;
My name is <: \$last_name :>.
EOS

my $tx = Text::Xslate->new;
my $tx_parser = $tx->_compiler->parser;
my $nodes = $tx_parser->parse($kolon_template);
my $tw = Text::Xslate::AST::Walker->new(nodes => $nodes);

ok $tw;

my $matched = $tw->search_descendants(sub {
  my ($node) = @_;
  $node->arity eq 'variable';
});

is scalar(@$matched), 1;
is $matched->[0]->arity, 'variable';
is $matched->[0]->id, '$last_name';

done_testing;
