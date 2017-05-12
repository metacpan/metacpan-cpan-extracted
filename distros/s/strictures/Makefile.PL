use strict;
use warnings FATAL => 'all';
use 5.006;
use lib 'inc';
use ExtUtils::HasCompiler 'can_compile_loadable_object';

my $have_compiler
  = ! parse_args()->{PUREPERL_ONLY}
  && can_compile_loadable_object(quiet => 1);

my %extra_prereqs = (
  indirect => 0,
  multidimensional => 0,
  'bareword::filehandles' => 0,
);

my %META = (
  name => 'strictures',
  license => 'perl_5',
  prereqs => {
    configure => { requires => { } },
    build => { requires => { } },
    test => { requires => {
      'Test::More' => 0,
    } },
    runtime => {
      requires => {
        perl => '5.006',
      },
      suggests => {
        %extra_prereqs,
      },
    },
    develop => { requires => {
      'Test::Pod' => 0,
      'Test::Pod::Coverage' => 0,
      'Pod::Coverage::CountParents' => 0,
      %extra_prereqs,
    } },
  },
  resources => {
    # r/w: p5sagit@git.shadowcat.co.uk:strictures.git
    repository => {
      url => 'git://git.shadowcat.co.uk/p5sagit/strictures.git',
      web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/strictures.git',
      type => 'git',
    },
    bugtracker => {
      mailto => 'bug-strictures@rt.cpan.org',
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=strictures',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt', 'inc' ]
  },
);

my %MM_ARGS = (
  PREREQ_PM => {
    ($] >= 5.008004 && $have_compiler ? %extra_prereqs : () )
  },
);

sub parse_args {
  # copied from EUMM
  require ExtUtils::MakeMaker;
  require Text::ParseWords;
  ExtUtils::MakeMaker::parse_args(
    my $tmp = {},
    Text::ParseWords::shellwords($ENV{PERL_MM_OPT} || ''),
    @ARGV,
  );
  return $tmp->{ARGS} || {};
}

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g;
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g;
$META{license} = [ $META{license} ]
  if $META{license} && !ref $META{license};
$MM_ARGS{LICENSE} = $META{license}[0]
  if $META{license} && $eumm_version >= 6.30;
$MM_ARGS{NO_MYMETA} = 1
  if $mymeta_broken;
$MM_ARGS{META_ADD} = { 'meta-spec' => { version => 2 }, %META }
  unless -f 'META.yml';

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  my $r = $MM_ARGS{$key} = {
    %{$META{prereqs}{$_}{requires} || {}},
    %{delete $MM_ARGS{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

$MM_ARGS{MIN_PERL_VERSION} = delete $MM_ARGS{PREREQ_PM}{perl} || 0;

delete $MM_ARGS{MIN_PERL_VERSION}
  if $eumm_version < 6.47_01;
$MM_ARGS{BUILD_REQUIRES} = {%{$MM_ARGS{BUILD_REQUIRES}}, %{delete $MM_ARGS{TEST_REQUIRES}}}
  if $eumm_version < 6.63_03;
$MM_ARGS{PREREQ_PM} = {%{$MM_ARGS{PREREQ_PM}}, %{delete $MM_ARGS{BUILD_REQUIRES}}}
  if $eumm_version < 6.55_01;
delete $MM_ARGS{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

ExtUtils::MakeMaker::WriteMakefile(%MM_ARGS);
## END BOILERPLATE ###########################################################
