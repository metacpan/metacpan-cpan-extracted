requires "Cache::FileCache" => "0";
requires "Carp" => "0";
requires "Class::Load" => "0";
requires "Data::Dump" => "0";
requires "Moo" => "1.004005";
requires "MooX::Types::MooseLike::Base" => "0";
requires "Storable" => "2.21";
requires "WWW::Mechanize" => "0";
requires "namespace::clean" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";
recommends "CHI" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "CHI" => "0";
  requires "Cache::FileCache" => "0";
  requires "File::Spec" => "0";
  requires "Find::Lib" => "0";
  requires "HTTP::Request" => "0";
  requires "LWP::ConsoleLogger::Easy" => "0";
  requires "Path::Class" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0";
  requires "Test::Requires" => "0";
  requires "Test::RequiresInternet" => "0";
  requires "constant" => "0";
  requires "lib" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Pod::Coverage" => "1.08";
};
