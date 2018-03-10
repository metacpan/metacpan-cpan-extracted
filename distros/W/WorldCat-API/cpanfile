requires "Carp" => "0";
requires "Data::Dumper" => "0";
requires "Digest::SHA" => "0";
requires "HTTP::Request" => "0";
requires "HTTP::Status" => "0";
requires "LWP::UserAgent" => "0";
requires "MARC::Record" => "0";
requires "Math::Random::Secure" => "0";
requires "Moo" => "0";
requires "Readonly" => "0";
requires "Time::Piece" => "0";
requires "XML::Simple" => "0";
requires "feature" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "Test::Deep" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0";
  requires "lib" => "0";
  requires "local::lib" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "Test::Perl::Critic" => "0";
  requires "Test::Pod" => "1.41";
  requires "perl" => "5.006";
};
