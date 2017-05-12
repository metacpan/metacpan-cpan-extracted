requires "Carp" => "0";
requires "HTTP::Message::PSGI" => "0";
requires "Test::WWW::Mechanize" => "0";
requires "Try::Tiny" => "0";
requires "base" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "CGI::Cookie" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Code::TidyAll" => "0.24";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.24";
  requires "Test::More" => "0.88";
};
