use Module::Build;

my $b = Module::Build->new
 (module_name   => 'UnicodeOperators',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Unicode Versions of Some Perl Operators',
  license       => 'perl',
  requires      => {Filter::Util::Call=>0},
  create_readme =>  1,
 );

$b->create_build_script();
