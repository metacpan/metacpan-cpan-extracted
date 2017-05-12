use Test::More tests => 5;
use utf8;

use Ufal::Parsito;

ok(my $parser = Ufal::Parsito::Parser::load('t/data/test.parser'));

my $conllu_input = Ufal::Parsito::TreeInputFormat::newInputFormat("conllu");
my $conllu_output = Ufal::Parsito::TreeOutputFormat::newOutputFormat("conllu");
my $tree = Ufal::Parsito::Tree->new();

$conllu_input->setText(<<EOF);
# Sentence Dobrý den z Prahy
1	Dobrý	_	ADJ	_	_	_	_	_	_
2	den	_	NOUN	_	_	_	_	_	_
3	z	_	ADP	_	_	_	_	_	_
4	Prahy	_	PROPN	_	_	_	_	_	_

EOF

ok($conllu_input->nextTree($tree));
ok(!$conllu_input->lastError());

$parser->parse($tree);

is($conllu_output->writeTree($tree, $conllu_input), <<EOF);
# Sentence Dobrý den z Prahy
1	Dobrý	_	ADJ	_	_	2	amon	_	_
2	den	_	NOUN	_	_	0	root	_	_
3	z	_	ADP	_	_	4	case	_	_
4	Prahy	_	PROPN	_	_	2	dep	_	_

EOF

ok(!$conllu_input->nextTree($tree));
