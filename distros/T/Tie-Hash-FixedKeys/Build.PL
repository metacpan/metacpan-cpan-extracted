use Module::Build;
my $build = Module::Build->new(
  module_name => 'Tie::Hash::FixedKeys',
  license => 'perl',
  requires => {
    perl           => '5.6.0',
  },
  create_makefile_pl => 'traditional',
  meta_merge => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
       type => 'git',
       url  => 'git://github.com/davorg/tie-hash-fixedkeys.git',
       web  => 'https://github.com/davorg/tie-hash-fixedkeys',
      },
      bugtracker => {
       web  => 'https://github.com/davorg/tie-hash-fixedkeys/issues',
      },
    },
  },
);
$build->create_build_script;

