use 5.010_001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 're-engine-Hooks';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my %PREREQ_PM = (
 'Carp'       => 0,
 'DynaLoader' => 0,
);

my %BUILD_REQUIRES = (
 'ExtUtils::Depends'   => 0,
 'ExtUtils::MakeMaker' => 0,
 'File::Spec'          => 0,
 'POSIX'               => 0,
 'Test::More'          => 0,
 'blib'                => 0,
 %PREREQ_PM,
);

my %META = (
 configure_requires => {
  'ExtUtils::Depends'   => 0,
  'ExtUtils::MakeMaker' => 0,
  'File::Spec'          => 0,
 },
 build_requires => {
  %BUILD_REQUIRES,
 },
 dynamic_config => 1,
 resources => {
  bugtracker => "http://rt.cpan.org/Dist/Display.html?Name=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

my $latest_dev_rev = 21;

sub is_outdated_dev_perl {
 my ($rev) = "$]" =~ /^5\.([0-9]{2}[13579])/;

 return unless defined $rev;

 return $rev < $latest_dev_rev;
}

if (is_outdated_dev_perl) {
 print STDERR <<EOF;
     This version of perl ($]) is an outdated development release.
     re::engine::Hooks supports all stable releases since 5.10.1, and
     development releases after 5.$latest_dev_rev.0 only. Please consider upgrading
     your perl to a more recent release.
EOF
 exit 0;
}

sub versioned_file {
 my ($file) = @_;

 my $version = "$]";
 $version    =~ s/\.//g;
 my $len     = length $version;
 if ($len > 7) {
  die "Invalid perl version";
 } else {
  $version .= '0' x (7 - $len);
 }

 require File::Spec;
 my $versioned_file = File::Spec->catfile('src', $version, $file);

 return -e $versioned_file ? [ $file => $versioned_file ] : undef;
}

unless (defined versioned_file('regcomp.c')) {
 print STDERR <<EOF;
     This version of perl ($]) is not yet supported by this version of
     re::engine::Hooks. If your perl has been recently released, make
     sure there isn't a newer version of the module available on the CPAN.
EOF
 exit 0;
}

my @DEFINES = qw<-DPERL_EXT_RE_BUILD -DPERL_EXT>;
@DEFINES    = (DEFINE => join ' ', @DEFINES) if @DEFINES;

use ExtUtils::Depends;

my $ed = ExtUtils::Depends->new($name);
$ed->add_c('regcomp.c');
$ed->add_c('regexec.c');
$ed->add_xs('Hooks.xs');
$ed->add_pm($file => do { local $_ = $file; s/^lib/\$(INST_LIB)/; $_ });
$ed->install('re_engine_hooks.h');
$ed->save_config('Files.pm');

my %ed_vars = $ed->get_makefile_vars;
$ed_vars{clean}->{FILES} .= ' ' . join ' ', (
 "$dist-*",
 'Files.pm',
 qw<*.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt>,
 qw<regcomp.c regexec.c dquote_static.c inline_invlist.c>,
);

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <perl@profvince.com>',
 LICENSE          => 'perl',
 VERSION_FROM     => $file,
 ABSTRACT_FROM    => $file,
 PL_FILES         => {},
 BUILD_REQUIRES   => \%BUILD_REQUIRES,
 PREREQ_PM        => \%PREREQ_PM,
 MIN_PERL_VERSION => '5.010001',
 META_MERGE       => \%META,
 dist             => {
  PREOP    => "pod2text -u $file > \$(DISTVNAME)/README",
  COMPRESS => 'gzip -9f', SUFFIX => 'gz'
 },
 XSPROTOARG       => '-noprototypes',
 @DEFINES,
 FUNCLIST         => [ qw<
  boot_re__engine__Hooks
  reh_register
 > ],
 %ed_vars,
);

{
 my $args_dat = './args.dat';

 open my $fh, '>', $args_dat or die "open(>$args_dat): $!";
 for (@ARGV) {
  my $arg = $_;
  $arg =~ s{\s*(['"])\s*(.*)\s*\1\s*$}{$2}s;
  $arg =~ s{([^=/.a-zA-Z0-9-])}{sprintf "[%d]", ord $1}ge;
  print $fh "$arg\n";
 }
}

package MY;

sub postamble {
 my $regcomp_c        = main::versioned_file('regcomp.c');
 my $regexec_c        = main::versioned_file('regexec.c');
 my $dquote_static_c  = main::versioned_file('dquote_static.c');
 my $inline_invlist_c = main::versioned_file('inline_invlist.c');

 my @all_c          = ($regcomp_c, $regexec_c);
 my @regcomp_c_deps = ('regcomp.c');
 my @regexec_c_deps = ('regexec.c');

 for my $extra_c ($dquote_static_c, $inline_invlist_c) {
  next unless defined $extra_c;
  push @all_c,           $extra_c;
  push @regcomp_c_deps, $extra_c->[0];
 }

 my $rules;

 for my $file_c (@all_c) {
  my ($target_file, $versioned_file) = @$file_c;
  $rules .= <<"RULE";
$target_file : $versioned_file
	- \$(RM_F) $target_file
	\$(CP) $versioned_file $target_file

RULE
 }

 $rules .= <<"RULE";
regcomp\$(OBJ_EXT) : @regcomp_c_deps

regexec\$(OBJ_EXT) : @regexec_c_deps

RULE

 $rules .= <<'EOF';
configure_test.pl: args.dat

t/re-engine-Hooks-TestDist/Makefile: configure_test.pl
	$(FULLPERLRUN) configure_test.pl

all clean:: t/re-engine-Hooks-TestDist/Makefile
	cd t/re-engine-Hooks-TestDist && $(MAKE) $@

clean::
	$(RM_RF) args.dat

EOF

 return $rules;
}
