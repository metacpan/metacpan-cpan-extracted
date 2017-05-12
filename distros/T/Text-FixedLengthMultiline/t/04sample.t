#!perl
use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings;

# This is the sample from the POD manual


# ------8<------8<------8<------8<------8<------8<------8<------8<------
  use Text::FixedLengthMultiline;

  my $fmt = Text::FixedLengthMultiline->new(format => ['!name' => 10, 1, 'comment~' => 20, 1, 'age' => -2 ]);

  # Compute the RegExp that matches the first line
  my $first_line_re = $fmt->get_first_line_re();
  # Compute the RegExp that matches a continuation line
  my $continue_line_re = $fmt->get_continue_line_re();

#234567890 12345678901234567890 12
  my $text = <<EOT;
Alice      Pretty girl!
Bob        Good old uncle Bob,
           very old.            92
Charlie    Best known as Waldo  14
           or Wally. Where's
           he?
EOT

  # Low level parsing
  my @table;
  my $err;
  while ($text =~ /^([^\n]+)$/gm) {
      my $line = $1;
      push @table, {} if $line =~ $first_line_re;
      if (($err = $fmt->parse_line($line, $table[$#table])) > 0) {
          warn "Parse error at column $err";
      }
  }
  # High level parsing
  my @table2;
  eval {
      @table2 = $fmt->parse_table($text);
  };
# ------8<------8<------8<------8<------8<------8<------8<------8<------


#use Data::Dumper;
#print Data::Dumper->Dump([\@table], '@table');

my $expected_table = [
    {
        name => 'Alice',
        comment => 'Pretty girl!'
    },
    {
        name => 'Bob',
        comment => "Good old uncle Bob,\nvery old.",
        age => 92
    },
    {
        name => 'Charlie',
        comment => "Best known as Waldo\nor Wally. Where's\nhe?",
        age => 14
    }
];

is_deeply(\@table, $expected_table, 'Sample from the POD manual: custom parse loop');
is_deeply(\@table2, $expected_table, 'Sample from the POD manual: parse_data()');

