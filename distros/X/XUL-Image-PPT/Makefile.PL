use strict;
use inc::Module::Install;

name            ('XUL-Image-PPT');
all_from        ('lib/XUL/Image.pm');
license         ('perl');
install_script  ('script/xul2img.pl');
install_script  ('script/img2ppt.pl');

build_requires  ('Test::More');
build_requires  ('Test::Exception');

requires  ('Win32::GuiTest');
requires  ('Clipboard');
requires  ('Image::Magick');
requires  ('Moose');
requires  ('File::Spec');
requires  ('Time::HiRes');

&WriteAll;
