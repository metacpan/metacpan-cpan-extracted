requires "Carp" => "0";
requires "Moo" => "0";
requires "MooX::HandlesVia" => "0";
requires "MooX::StrictConstructor" => "0";
requires "Mozilla::CA" => "0";
requires "Type::Params" => "0";
requires "Types::Standard" => "0";
requires "Types::URI" => "0";
requires "URI" => "0";
requires "WWW::Mechanize" => "0";
requires "feature" => "0";
requires "perl" => "v5.10.0";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "DDP" => "0";
  requires "Plack::Handler::HTTP::Server::Simple" => "0.016";
  requires "Plack::Test::Agent" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::Most" => "0";
  requires "perl" => "v5.10.0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
  requires "perl" => "v5.10.0";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
  requires "Test::Synopsis" => "0";
};
