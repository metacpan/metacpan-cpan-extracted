use strict;
use warnings;
use 5.008001;

my %META = (
  name => 'namespace-clean',
  license => 'perl_5',

  abstract => 'Keep imports and functions out of your namespace',
  author => [
    'Robert \'phaylon\' Sedlacek <rs@474.at>',
    'Florian Ragwitz <rafl@debian.org>',
    'Jesse Luehrs <doy@tozt.net>',
    'Peter Rabbitson <ribasushi@cpan.org>',
    'Father Chrysostomos <sprout@cpan.org>',
  ],

  prereqs => {
    configure => {
      requires => {
        'ExtUtils::MakeMaker'   => 0,
      }
    },
    runtime => {
      requires => {
        'Package::Stash' => '0.23',
        'B::Hooks::EndOfScope' => '0.12',
        'perl' => '5.008001',
      },
    },
    test => {
      requires => {
        'Test::More' => '0.47',
      }
    },
  },

  resources => {
    x_IRC => 'irc://irc.perl.org/#toolchain',
    homepage => 'http://search.cpan.org/dist/namespace-clean',
    repository => {
      type => 'git',
      url => 'git://git.shadowcat.co.uk/p5sagit/namespace-clean.git',
      web => 'https://github.com/p5sagit/namespace-clean',
    },
    bugtracker => {
      mailto => 'bug-namespace-clean@rt.cpan.org',
      web => 'http://rt.cpan.org/Public/Dist/Display.html?Name=namespace-clean',
    },
  },
);

my %MM_ARGS = ( (
  # a sub-namer is needed if using the debugger on some perls
  do {
    # sigh... so much unmitigated stupidity on #p5p these days...
    local @INC = ('lib', @INC);
    require namespace::clean::_Util;
  }
    and
  namespace::clean::_Util::DEBUGGER_NEEDS_CV_RENAME()
    and
  namespace::clean::_Util::_namer_load_error()
    and
  usable_compiler_present()
)
  # when changing version, also change $sn_ver in namespace/clean/_Util.pm
  ? ( PREREQ_PM => { 'Sub::Name' => '0.04' } )
  : ()
);

## XS-checking BOILERPLATE ###################################################
sub usable_compiler_present {
  return 0 if parse_args()->{PUREPERL_ONLY};

  my $ucp;

  local $@;
  eval {
    # poor man's inc::latest
    my $euhc_fn = 'ExtUtils/HasCompiler.pm';
    my $euhc_found_in_INC_dir;

    ( ($euhc_found_in_INC_dir) = grep {
      not length ref $_
        and
      -f "$_/$euhc_fn"
        and
      -r "$_/$euhc_fn"
    } @INC )
      and
    (
      MM->parse_version("$euhc_found_in_INC_dir/$euhc_fn")
        >
      MM->parse_version("inc/$euhc_fn")
    )
      and
    eval { require ExtUtils::HasCompiler };

    unless ( $INC{'ExtUtils/HasCompiler.pm'} ) {
      local @INC = ( "inc", @INC );
      require ExtUtils::HasCompiler;
    }

    $ucp = ExtUtils::HasCompiler::can_compile_loadable_object(quiet => 1)
      ? 1
      : 0
    ;

    1;
  };

  if( my $used_fn = $INC{'ExtUtils/HasCompiler.pm'} ) {
    printf
      "ExtUtils::HasCompiler::can_compile_loadable_object() v%s (loaded from %s) returned: %s\n",
      ExtUtils::HasCompiler->VERSION,
      $used_fn,
      ( defined($ucp) ? $ucp : "UNKNOWN" ),
    ;
  }
  else {
    print "Something went wrong when trying to load/use ExtUtils::HasCompiler:\n$@\n\n";
  }

  $ucp;
}


# FIXME - this has been cargo-culted from
# https://metacpan.org/source/HAARG/strictures-2.000002/Makefile.PL
# There likely will be better ways to handle %ENV and @ARGV directly within
# EU::HC in the future
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
## END XS-checking BOILERPLATE ###############################################


## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;

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
