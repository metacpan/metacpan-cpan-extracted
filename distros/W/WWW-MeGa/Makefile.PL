use strict;
use inc::Module::Install;

name		'WWW-MeGa';
all_from	'lib/WWW/MeGa.pm';
requires	'Carp' => 0;
requires	'FindBin' => 0;
requires	'Scalar::Util' => 0;
requires	'CGI::Application' => 0;
requires	'CGI::Application::Plugin::HTCompiled' => 0;
requires	'CGI::Application::Plugin::Config::Simple' => 0;
requires	'CGI::Application::Plugin::Stream' => 0;
requires	'File::Spec' => 0;
requires	'File::Basename' => 0;
requires	'File::Path' => 0;
requires	'MIME::Types' => 0;
requires	'Image::ExifTool' => 0;
requires	'Image::Magick' => 0;
requires	'File::ShareDir' => 0;

install_share;

WriteAll;
