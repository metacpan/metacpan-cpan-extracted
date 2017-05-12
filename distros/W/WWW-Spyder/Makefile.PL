use inc::Module::Install;

name "WWW-Spyder";
all_from "lib/WWW/Spyder.pm";

requires "Test::More" => 0;
requires  "HTML::Parser" => 3;
requires  "LWP::UserAgent" => 0;
requires  "HTTP::Cookies" => 0;
requires  "URI::URL" => 0;
requires  "HTML::Entities" => 0;
requires  "Digest::MD5" => 0;

auto_install;

WriteAll;

__END__
