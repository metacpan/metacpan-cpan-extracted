# This file is part of Parsito <http://github.com/ufal/parsito/>.
#
# Copyright 2015 Institute of Formal and Applied Linguistics, Faculty of
# Mathematics and Physics, Charles University in Prague, Czech Republic.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

use warnings;
use strict;
use open qw(:std :utf8);

use Ufal::Parsito;


@ARGV >= 1 or die "Usage: $0 parser_file\n";

print STDERR "Loading parser: ";
my $parser = Ufal::Parsito::Parser::load($ARGV[0]);
$parser or die "Cannot load parser from file '$ARGV[0]'\n";
print STDERR "done\n";
shift @ARGV;

my $conllu_input = Ufal::Parsito::TreeInputFormat::newInputFormat("conllu");
my $conllu_output = Ufal::Parsito::TreeOutputFormat::newOutputFormat("conllu");
my $tree = Ufal::Parsito::Tree->new();

for (my $not_eof = 1; $not_eof; ) {
  my $text = '';

  # Read block
  while (1) {
    my $line = <>;
    last unless ($not_eof = defined $line);
    $text .= $line;
    chomp($line);
    last unless length $line;
  }

  # Tag
  $conllu_input->setText($text);
  while ($conllu_input->nextTree($tree)) {
    $parser->parse($tree);

    my $output = $conllu_output->writeTree($tree, $conllu_input);
    print $output;
  }
  length($conllu_input->lastError()) and die "Cannot read input CoNLL-U: " . $conllu_input->lastError();
}
