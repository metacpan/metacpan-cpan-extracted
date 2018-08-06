requires "LWP::Protocol::https" => "0";
requires "List::Compare" => "0";
requires "Params::Validate" => "0";
requires "Try::Tiny" => "0";
requires "URI" => "0";
requires "URI::Heuristic" => "0";
requires "URI::ParseSearchString" => "0";
requires "URI::QueryParam" => "0";
requires "WWW::Mechanize::Cached" => "0";
requires "base" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Config::General" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
  requires "Test::RequiresInternet" => "0";
  requires "Test::WWW::Mechanize" => "0";
  requires "perl" => "5.010";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::More" => "0.96";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
  requires "Test::Synopsis" => "0";
};

on 'develop' => sub {
  recommends "Dist::Zilla::PluginBundle::Git::VersionManager" => "0.007";
};
