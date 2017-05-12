#!/usr/bin/perl

my $LENGTH = 6;

print "Building generator...\n";
system ("yagg -m ab_constrained_pointers.yg") == 0
  or die "Generation failed";

print "Building parser...\n";
system ("cd ab_parser; make") == 0
  or die "Building failed";

print "Generating strings...\n";

# grep to get just the expressions and not the "--" separators.
my @expressions = grep { /p/ } `./output/progs/generate $LENGTH`;

print "Generated " . scalar(@expressions) . " expressions...\n";

foreach my $expression (@expressions)
{
  open TEMP, '>temp_input_file.txt';
  print TEMP $expression;
  close TEMP;

  system("./ab_parser/progs/ab_parser temp_input_file.txt") == 0
    or die "Parsing check failed. See temp_input_file.txt";

  unlink 'temp_input_file.txt';
}
