requires 'Config::Identity' => 0;
requires 'Exporter' => 0;
requires 'Parse::CPAN::Meta' => 0;
requires 'PAUSE::Permissions' => "0.09";
requires 'Parse::LocalDistribution' => "0.08"; # for manifest(.skip) handling
requires 'Parse::PMFile' => "0.15"; # for correct package no_index
requires 'parent' => 0;
on test => sub {
  requires 'Test::More' => '0.88';
  requires 'Test::UseAllModules' => '0.10';
};
on configure => sub {
  requires 'ExtUtils::MakeMaker::CPANfile' => '0.04';
};
