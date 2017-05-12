require 5.009005;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

write_config( 'config.h' );

my $oe = $Config{obj_ext};
my @obj = map { $_ . $oe } qw(
 regcomp regenc regerror regexec regext reggnu regparse regposerr
 regposix regsyntax regtrav regversion st
);

WriteMakefile(
  NAME         => 'onig',
  AUTHOR       => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM => '../lib/re/engine/Oniguruma.pm',
  LICENSE      => 'perl',
  DEFINE       => '-DHAVE_CONFIG_H',
  clean        => { FILES => "*.o *.lo *$oe" },
  OBJECT       => join( ' ', @obj ),
  PM           => {},
  XS           => {},
  linkext      => { LINKTYPE => 'static' }
);

sub MY::static {
  return entab( <<'EOM');
static :: $(FIRST_MAKEFILE) $(OBJECT)
 $(NOECHO) $(NOOP)
EOM
}

sub entab {
  my $str = shift;
  $str =~ s{^\s+}{\t}msg;
  return $str;
}

sub write_config {
  my $file = shift;

  my %conf_map = (
    HAVE_DLFCN_H     => 'i_dlfcn',
    HAVE_INTTYPES_H  => 'i_inttypes',
    HAVE_PROTOTYPES  => 'prototype',
    HAVE_STDLIB_H    => 'i_stdlib',
    HAVE_STRING_H    => 'i_string',
    HAVE_SYS_STAT_H  => 'i_sysstat',
    HAVE_SYS_TIMES_H => 'i_systimes',
    HAVE_SYS_TIME_H  => 'i_systime',
    HAVE_SYS_TYPES_H => 'i_systypes',

    SIZEOF_INT   => ['intsize'],
    SIZEOF_LONG  => ['longsize'],
    SIZEOF_SHORT => ['shortsize'],

    PACKAGE           => sub { 'onig' },
    PACKAGE_BUGREPORT => sub { 'andy@hexten.net' },
    PACKAGE_NAME      => sub { 'onig' },
    PACKAGE_STRING    => sub { 'onig 5.9.0' },
    PACKAGE_TARNAME   => sub { 'onig' },
    PACKAGE_VERSION   => sub { '5.9.0' },
    VERSION           => sub { '5.9.0' },

    USE_COMBINATION_EXPLOSION_CHECK => 0,
    USE_CRNL_AS_LINE_TERMINATOR     => 0,

    STDC_HEADERS       => 1,
    TIME_WITH_SYS_TIME => 1,
    CRAY_STACKSEG_END  => 0,
    # C_ALLOCA               => 0,
    HAVE_ALLOCA            => 1,
    HAVE_ALLOCA_H          => 1,
    HAVE_STDARG_PROTOTYPES => (
      ( $Config{i_varhdr} eq 'stdarg.h' )
      ? 1
      : 0
    ),
  );

  open my $cfg, '>', $file or die "Can't write $file ($!)\n";

  print $cfg <<EOT;
#ifdef VERSION
#undef VERSION
#endif
EOT

  for my $def ( sort keys %conf_map ) {
    my $val = $conf_map{$def};
    if ( 'CODE' eq ref $val ) {
      print $cfg qq{#define $def "}, $val->(), qq{"\n};
    }
    elsif ( 'ARRAY' eq ref $val ) {
      print $cfg qq{#define $def }, $Config{ $val->[0] }, qq{\n};
    }
    elsif ( $val !~ /^\d+$/ ) {
      if ( $Config{$val} ) {
        print $cfg qq{#define $def 1\n};
      }
      else {
        print $cfg qq{/* #undef $def */\n};
      }
    }
    else {
      print $cfg qq{#define $def $val\n};
    }
  }
}
