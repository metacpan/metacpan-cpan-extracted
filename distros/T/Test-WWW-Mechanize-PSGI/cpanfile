requires "Carp" => "0";
requires "HTTP::Message::PSGI" => "0";
requires "Test::WWW::Mechanize" => "0";
requires "Try::Tiny" => "0";
requires "base" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "CGI::Cookie" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Test::More" => "0";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.006";
};

on 'configure' => sub {
  suggests "JSON::PP" => "2.27300";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::More" => "0.88";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
  requires "Test::Synopsis" => "0";
};
