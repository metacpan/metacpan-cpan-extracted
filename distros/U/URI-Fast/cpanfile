requires 'perl', '5.010';

requires 'Exporter';
requires 'Inline::C';
requires 'URI::Encode::XS', '0.07';

on test => sub {
  requires 'Importer'; # some weird smoker setup?
  requires 'Test2::Suite'    => '0.000049';
  requires 'Test::Pod'       => 1.41;
  requires 'URI::Split'      => 0;
  requires 'Test::LeakTrace' => '0.16';
};
