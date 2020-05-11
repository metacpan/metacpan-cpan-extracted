use Test2::V0 -no_srand => 1;
use Config;

eval { require 'Test/More.pm' };

# This .t file is generated.
# make changes instead to dist.ini

my %modules;
my $post_diag;

$modules{$_} = $_ for qw(
  Alien::wasmtime
  Capture::Tiny
  Devel::GlobalDestruction
  ExtUtils::MakeMaker
  FFI::C
  FFI::C::StructDef
  FFI::C::Util
  FFI::CheckLib
  FFI::Platypus
  FFI::Platypus::Buffer
  FFI::Platypus::Record
  FFI::Platypus::Type::PtrObject
  Path::Tiny
  Ref::Util
  Sub::Install
  Test2::API
  Test2::Mock
  Test2::V0
  Test::Alien::Diag
  YAML
);

$post_diag = sub {
  eval { require Test::Alien::Diag; require Alien::wasmtime; Test::Alien::Diag::alien_diag('Alien::wasmtime'); };
  if($@) {
    eval {
      require Wasm::Wasmtime::FFI;
      diag "Wasm::Wasmtime::FFI->_lib = $_" for Wasm::Wasmtime::FFI->_lib;
    };
    diag "error requiring Wasm::Wasmtime::FFI: $@" if $@;
  };
};

my @modules = sort keys %modules;

sub spacer ()
{
  diag '';
  diag '';
  diag '';
}

pass 'okay';

my $max = 1;
$max = $_ > $max ? $_ : $max for map { length $_ } @modules;
our $format = "%-${max}s %s";

spacer;

my @keys = sort grep /(MOJO|PERL|\A(LC|HARNESS)_|\A(SHELL|LANG)\Z)/i, keys %ENV;

if(@keys > 0)
{
  diag "$_=$ENV{$_}" for @keys;

  if($ENV{PERL5LIB})
  {
    spacer;
    diag "PERL5LIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERL5LIB};

  }
  elsif($ENV{PERLLIB})
  {
    spacer;
    diag "PERLLIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERLLIB};
  }

  spacer;
}

diag sprintf $format, 'perl ', $];

foreach my $module (sort @modules)
{
  my $pm = "$module.pm";
  $pm =~ s{::}{/}g;
  if(eval { require $pm; 1 })
  {
    my $ver = eval { $module->VERSION };
    $ver = 'undef' unless defined $ver;
    diag sprintf $format, $module, $ver;
  }
  else
  {
    diag sprintf $format, $module, '-';
  }
}

if($post_diag)
{
  spacer;
  $post_diag->();
}

spacer;

done_testing;

