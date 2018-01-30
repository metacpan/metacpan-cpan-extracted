use ExtUtils::MakeMaker;

eval {require Win32;};

if($@) {
  warn "\nThis module works only on Win32\n";
  exit 0;
}

my ($major, $minor) = (Win32::GetOSVersion())[1, 2];


if($major < 5) {
  warn "Windows versions older than Windows 2000 are not supported";
  exit 0;
}

my %options = %{
{
  NAME => 'Win32::GenRandom',
  VERSION_FROM => 'GenRandom.pm',
  PREREQ_PM => {Test::Warn => '0.23'},
  LICENSE => 'perl',
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/win32-genrandom.git',
        web => 'https://github.com/sisyphus/win32-genrandom',
      },
    },
  },
}
};

if($major == 5 && $minor == 0) {
  $options{DEFINE} = '-DWIN2K';
}

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
