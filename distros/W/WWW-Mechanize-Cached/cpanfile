requires "Cache::FileCache" => "0";
requires "Carp" => "0";
requires "Data::Dump" => "0";
requires "Module::Runtime" => "0";
requires "Moo" => "1.004005";
requires "MooX::Types::MooseLike::Base" => "0";
requires "Storable" => "2.21";
requires "WWW::Mechanize" => "0";
requires "namespace::clean" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";
recommends "CHI" => "0";

on 'test' => sub {
  requires "CHI" => "0";
  requires "Cache::FileCache" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Find::Lib" => "0";
  requires "HTTP::Request" => "0";
  requires "Path::Class" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0";
  requires "Test::Requires" => "0";
  requires "Test::RequiresInternet" => "0";
  requires "constant" => "0";
  requires "lib" => "0";
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
  suggests "Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional" => "0.004";
  suggests "Dist::Zilla::Plugin::CopyFilesFromRelease" => "0";
  suggests "Dist::Zilla::Plugin::Git::Commit" => "2.020";
  suggests "Dist::Zilla::Plugin::Git::Tag" => "0";
  suggests "Dist::Zilla::Plugin::NextRelease" => "5.033";
  suggests "Dist::Zilla::Plugin::RewriteVersion::Transitional" => "0.004";
};
