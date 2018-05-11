requires "App::cpm" => "0.974";
requires "App::cpm::CLI" => "0";
requires "Getopt::Long" => "0";
requires "Module::Loaded" => "0";
requires "local::lib" => "2.000024";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Capture::Tiny" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Path::Iterator::Rule" => "0";
  requires "Path::Tiny" => "0";
  requires "Test::More" => "0";
  requires "Test::RequiresInternet" => "0";
  requires "Test::TempDir::Tiny" => "0";
  requires "local::lib" => "2.000024";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "Perl::Tidy" => "20170521";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::More" => "0.96";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
};

on 'develop' => sub {
  recommends "Dist::Zilla::PluginBundle::Git::VersionManager" => "0.007";
};
