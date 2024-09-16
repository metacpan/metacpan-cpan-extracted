use strict;
use warnings;
use 5.008001;

my %META = (
  name => 'lib-with-preamble',
  license => [ 'perl_5' ],
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'   => 0,
    } },
    test => {
      requires => {
        'Test::More'  => '0.88',
      },
    },
    runtime => {
      requires => {
        'perl'                  => '5.008001',
        'PerlIO::via::dynamic'  => '0.02',
        'File::Spec'            => '0',
      },
    },
  },
  resources => {
    repository => {
      url => 'https://github.com/p5sagit/lib-with-preamble.git',
      web => 'https://github.com/p5sagit/lib-with-preamble',
      type => 'git',
    },
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=lib-with-preamble',
      mailto => 'bug-lib-with-preamble@rt.cpan.org',
    },
    license => [ 'https://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
  dynamic_config => 0,
);

my %MM_ARGS = (
  PM_FILTER => '$(ABSPERLRUN) my/filter',
);

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g
  if !$MM_ARGS{NAME};
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g
  if !$MM_ARGS{VERSION} && !$MM_ARGS{VERSION_FROM};
$MM_ARGS{ABSTRACT_FROM} ||= $MM_ARGS{VERSION_FROM}
  if !$MM_ARGS{ABSTRACT};
$MM_ARGS{AUTHOR} ||= $META{author}
  if $META{author};
$MM_ARGS{AUTHOR} = join ', ', @{$MM_ARGS{AUTHOR}}
  if $eumm_version < 6.5702 && $MM_ARGS{AUTHOR};
$MM_ARGS{LICENSE} = $META{license}[0]
  if $META{license} && $eumm_version >= 6.30;
$MM_ARGS{NO_MYMETA} = 1
  if $mymeta_broken;
$MM_ARGS{META_ADD} = { 'meta-spec' => { version => 2 }, %META }
  unless -f 'META.yml';
$MM_ARGS{PL_FILES} ||= {};
$MM_ARGS{NORECURS} = 1
  if not exists $MM_ARGS{NORECURS};

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
