package Module::Install::PRIVATE::Make_Parsers;

use strict;
use warnings;

use vars qw( @ISA $VERSION );

use Module::Install::Base;
@ISA = qw( Module::Install::Base );

$VERSION = sprintf "%d.%02d%02d", q/0.1.0/ =~ /(\d+)/g;

# ---------------------------------------------------------------------------

sub make_parsers
{
  my ($self, $yapp) = @_;

  die qq{No "yapp" available to create the parsers\n} unless defined $yapp;

  print "Running yapp to create the parsers\n";

  system("$yapp -m 'yagg::NonterminalParser' -o 'lib/yagg/NonterminalParser.pm' etc/nonterminal_parser_grammar.yp") == 0
    or die "Could not run yapp to create the NonterminalParser.pm file: $!";
  system("$yapp -m 'yagg::TerminalParser' -o 'lib/yagg/TerminalParser.pm' etc/terminal_parser_grammar.yp") == 0
    or die "Could not run yapp to create the TerminalParser.pm file: $!";
}

1;
