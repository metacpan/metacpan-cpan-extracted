use strict;
use inc::Module::Install;

name "XHTML-Util";
license 'perl';
all_from "lib/XHTML/Util.pm";

requires "Encode" => 2;
requires "HTML::Tagset" => 3;
requires "XML::LibXML" => 1.6;
requires "Scalar::Util" => undef;
requires "HTML::Tagset" => 3.02;
requires "HTML::Entities" => undef;
requires "CSS::Tiny" => undef;
requires "HTML::Selector::XPath" => undef;
requires "HTML::TokeParser::Simple" => undef;

build_requires "Test::More" => 0.5;
build_requires "File::Spec" => 3;

system( 'pod2text lib/XHTML/Util.pm > README' );

auto_install;
WriteAll;

__END__

