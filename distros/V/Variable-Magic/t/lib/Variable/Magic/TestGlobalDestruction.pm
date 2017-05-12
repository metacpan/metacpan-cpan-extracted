package Variable::Magic::TestGlobalDestruction;

use strict;
use warnings;

# Silence possible 'used only once' warnings from Test::Builder
our $TODO;
local $TODO;

sub _diag {
 require Test::More;
 Test::More::diag(@_);
}

my $is_debugging;

sub is_debugging_perl {
 return $is_debugging if defined $is_debugging;

 my $source;

 my $has_config_perl_v = do {
  local $@;
  eval { require Config::Perl::V; 1 };
 };

 if ($has_config_perl_v) {
  $is_debugging = do {
   local $@;
   eval { Config::Perl::V::myconfig()->{build}{options}{DEBUGGING} };
  };

  if (defined $is_debugging) {
   $source = "Config::Perl::V version $Config::Perl::V::VERSION";
  }
 }

 unless (defined $is_debugging) {
  $is_debugging = 0;
  $source       = "%Config";

  require Config;
  my @fields = qw<ccflags cppflags optimize>;

  for my $field (@fields) {
   my $content = $Config::Config{$field};

   while ($content =~ /(-DD?EBUGGING((?:=\S*)?))/g) {
    my $extra = $2 || '';
    if ($extra ne '=none') {
     $is_debugging = 1;
     $source       = "\$Config{$field} =~ /$1/";
    }
   }
  }
 }

 my $maybe_is = $is_debugging ? "is" : "is NOT";
 _diag("According to $source, this $maybe_is a debugging perl");

 return $is_debugging;
}

sub import {
 shift;
 my %args = @_;

 my $level = $args{level};
 $level    = 1 unless defined $level;

 if ("$]" < 5.013_004 and not $ENV{PERL_FORCE_TEST_THREADS}) {
  _diag("perl 5.13.4 required to safely test global destruction");
  return 0;
 }

 my $env_level = $ENV{PERL_DESTRUCT_LEVEL};
 if (defined $env_level) {
  no warnings 'numeric';
  $env_level = int $env_level;
 }

 my $is_debugging = is_debugging_perl();
 if ($is_debugging) {
  if (defined $env_level) {
   _diag("Global destruction level $env_level set by PERL_DESTRUCT_LEVEL (environment)");
   return ($env_level >= $level) ? 1 : 0;
  } else {
   $ENV{PERL_DESTRUCT_LEVEL} = $level;
   _diag("Global destruction level $level set by PERL_DESTRUCT_LEVEL (forced)");
   return 1;
  }
 } elsif (defined $env_level) {
  _diag("PERL_DESTRUCT_LEVEL is set to $env_level, but this perl doesn't seem to have debugging enabled, ignoring");
 }

 my $has_perl_destruct_level = do {
  local $@;
  eval {
   require Perl::Destruct::Level;
   Perl::Destruct::Level->import(level => $level);
   1;
  }
 };

 if ($has_perl_destruct_level) {
  _diag("Global destruction level $level set by Perl::Destruct::Level");
  return 1;
 }

 _diag("Not testing global destruction");
 return 0;
}

1;
