use 5.008008;
use strict;
use ExtUtils::MakeMaker;
use Text::ParseWords qw(shellwords);
use ExtUtils::Constant qw(WriteConstants);

my $cflags = `icu-config --cppflags`
  or die "OS unsupported: No icu-config --cppflags found\n";
my $libs = `icu-config --ldflags`
  or die "OS unsupported: No icu-config libraries\n";
chomp $cflags;
chomp $libs;

# cppflags includes both defines and -I options, separate them out
my @define;
my @inc;
for my $flag (shellwords $cflags) {
  if ($flag =~ /^-I/) {
    push @inc, $flag;
  }
  else {
    push @define, $flag;
  }
}

@define = requote(@define);
@inc = requote(@inc);

my %opts = 
  (
   NAME => 'Unicode::ICU::Collator',
   VERSION_FROM => 'lib/Unicode/ICU/Collator.pm',
   OBJECT => 'Collator.o',
   DEFINE => "@define",
   INC => "@inc",
   LIBS => $libs,
   PREREQ_PM =>
   {
    'Test::More' => '0.47',
    XSLoader => 0,
   },
  );
my $eu_mmv = eval $ExtUtils::MakeMaker::VERSION;
if ($eu_mmv > 6.06) {
  $opts{AUTHOR} = 'Tony Cook <tonyc@cpan.org>';
  $opts{ABSTRACT} = 'Wrapper around ICU collation services';
}
if ($eu_mmv > 6.30) {
  $opts{LICENSE} = 'perl';
}

WriteMakefile(%opts);

WriteConstants
  (
   NAME => "Unicode::ICU::Collator",
   NAMES => 
   [
    map
    +{
      name => $_,
      macro => 1
     },
    qw(ULOC_ACTUAL_LOCALE ULOC_VALID_LOCALE),
    qw(UCOL_FRENCH_COLLATION UCOL_ALTERNATE_HANDLING UCOL_CASE_FIRST
       UCOL_CASE_LEVEL UCOL_NORMALIZATION_MODE UCOL_DECOMPOSITION_MODE
       UCOL_STRENGTH UCOL_HIRAGANA_QUATERNARY_MODE UCOL_NUMERIC_COLLATION),
    qw(UCOL_DEFAULT UCOL_PRIMARY UCOL_SECONDARY UCOL_TERTIARY
       UCOL_DEFAULT_STRENGTH UCOL_CE_STRENGTH_LIMIT UCOL_QUATERNARY
       UCOL_IDENTICAL UCOL_STRENGTH_LIMIT UCOL_OFF UCOL_ON UCOL_SHIFTED
       UCOL_NON_IGNORABLE UCOL_LOWER_FIRST UCOL_UPPER_FIRST),
    qw(UCOL_TAILORING_ONLY UCOL_FULL_RULES)
   ],
  );

sub requote {
  return map { / / ? qq("$_") : $_ } @_;
}
