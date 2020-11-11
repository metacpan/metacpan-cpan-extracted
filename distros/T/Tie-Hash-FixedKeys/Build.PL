use Module::Build;
my $build = Module::Build->new(
  module_name => 'Tie::Hash::FixedKeys',
  dist_version => '1.13.1',
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
    },
  },
);
$build->create_build_script;

