requires "List::Compare" => "0";
requires "Params::Validate" => "0";
requires "Test::WWW::Mechanize" => "1.44";
requires "Try::Tiny" => "0";
requires "URI" => "0";
requires "URI::Heuristic" => "0";
requires "URI::ParseSearchString" => "0";
requires "URI::QueryParam" => "0";
requires "WWW::Mechanize::Cached" => "0";
requires "base" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "Config::General" => "0";
  requires "Test::Most" => "0";
  requires "Test::RequiresInternet" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
};
