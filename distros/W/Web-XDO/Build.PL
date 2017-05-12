use strict;
use Module::Build;
my ($build, $params);


$params = {
            'dist_abstract' => 'Web::XDO -- static web site tool',
            'dist_author' => 'Miko O\'Sullivan <miko@idocs.com>',
            'module_name' => 'Web::XDO',
            'requires' => {
                            'String::Util' => 0,
                            'HTML::Parser' => 0,
                            'URI::URL' => 0
                          },
            'dist_version_from' => 'lib/Web/XDO.pm',
            'license' => 'perl'
          };


$build = Module::Build->new(%$params);
$build->create_build_script();
