use 5.008008;
use strict;
use ExtUtils::MakeMaker 6.46;
use Text::ParseWords qw(shellwords);
use ExtUtils::Constant qw(WriteConstants);

my $cflags = `pkg-config --cflags icu-i18n`;
my $libs = `pkg-config --libs icu-i18n`;

unless ($cflags) {
  print "Pkg-config didn't find icu-i18n, falling back to icu-config\n";
  $cflags = `icu-config --cppflags`
    or die "OS unsupported: No icu-config --cppflags found\n";
  $libs = `icu-config --ldflags`
    or die "OS unsupported: No icu-config libraries\n";
}
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
   AUTHOR => 'Tony Cook <tonyc@cpan.org>',
   ABSTRACT => 'Wrapper around ICU collation services',
   LICENSE => 'perl_5',
   META_MERGE =>
   {
     'meta-spec' =>
     {
       version => "2",
       url => "https://metacpan.org/pod/CPAN::Meta::Spec",
     },
     resources =>
     {
       repository =>
       {
         url => "https://github.com/tonycoz/Unicode-ICU.git",
         web => "https://github.com/tonycoz/Unicode-ICU",
         type => "git",
       },
       bugtracker =>
       {
         web => "https://github.com/tonycoz/Unicode-ICU/issues",
       },
     },
     prereqs =>
     {
       configure =>
       {
         require =>
         {
           'ExtUtils::MakeMaker' => '6.46',
         },
       },
       test =>
       {
         require =>
         {
           'Test::More' => '0.47',
           XSLoader => 0,
         },
       },
       runtime =>
       {
         require =>
         {
           XSLoader => 0,
         },
       },
     },
   },
  );

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
