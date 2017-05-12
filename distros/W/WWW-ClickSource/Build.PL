use Module::Build;
# See perldoc Module::Build for details of how this works

my $mb = Module::Build->new( 
      module_name     => 'WWW::ClickSource',
      license         => 'perl',
      dist_author     => 'Horea <horea@cpan.org>',
      configure_requires => { 'Module::Build' => 0.38 },
      requires        => {
	      'Module::Build' => 0.38,
          'URI'       => 0,
          'perl'      => '5.010000',
      },
      build_requires => {
          'Test::More' => 0,
          'URI'        => 0,
          'perl'      => '5.010000',
      },
      dist_abstract   => 'Determine the source of a visit on your website : organic, adwords, facebook, referer site',
      meta_merge     => {
          resources => {
              repository  => 'https://github.com/gliganh/WWW-ClickSource',
          }
      },
);

$mb->create_build_script;