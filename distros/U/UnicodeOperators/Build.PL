use Module::Build;

my $b = Module::Build->new
 (module_name   => 'UnicodeOperators',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Unicode Versions of Some Perl Operators',
  perl          => '5.16.0',
  license       => 'perl',
  requires      => {Filter::Util::Call=>0, Carp=>0, Test::More=>0},
  create_readme =>  0,
  configure_requires => {'Module::Build'=>0.42},
 );

$b->create_build_script();
