#!/usr/bin/perl

my $LENGTH = 6;

print "Building generator...\n";
system ("yagg -m -u user_code logical_expression.yg logical_expression.lg") == 0
  or die "Generation failed";

print "Building parser...\n";
system ("cd logical_expression_parser; make") == 0
  or die "Building failed";

print "Generating logical expressions...\n";

# grep to get just the expressions and not the "--" separators.
my @expressions = grep { /p/ } `./output/progs/generate $LENGTH`;

print "Generated " . scalar(@expressions) . " expressions...\n";

foreach my $expression (@expressions)
{
  open TEMP, '>temp_input_file.txt';
  print TEMP $expression;
  close TEMP;

  system("./logical_expression_parser/progs/logical_expression_parser temp_input_file.txt") == 0
    or die "Parsing check failed. See temp_input_file.txt";

  unlink 'temp_input_file.txt';
}
