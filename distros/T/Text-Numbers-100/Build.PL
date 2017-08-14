use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Text::Numbers::100',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Translate the numbers from 0 to 100 into various languages',
  license       => 'perl',
  requires      => {Carp=>0, Test::More=>0},
  configure_requires => { 'Module::Build' => 0.42 },
  create_readme =>  0,
  perl          => '5.16.0',
 );

$b->create_build_script();
