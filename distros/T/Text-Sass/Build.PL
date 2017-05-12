#########
# Author:        rmp
# Last Modified: $Date: 2011-11-05 22:04:35 +0000 (Sat, 05 Nov 2011) $
# Id:            $Id: Build.PL 62 2011-11-05 22:04:35Z zerojinx $
# Source:        $Source$
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/Build.PL $
#
use strict;
use warnings;
use Module::Build;
use lib qw(lib);

my $builder = Module::Build->new(
				 module_name         => 'Text-Sass',
				 dist_author         => 'Roger Pettett <rmp@psyphi.net>',
				 dist_version_from   => 'lib/Text/Sass.pm',
				 dist_abstract       => q[Text-Sass - Perl implementation of http://sass-lang.com/],
				 license             => 'perl',
				 requires            => {
							 'Carp'                    => '1.04',
							 'English'                 => '1.02',
							 'Readonly'                => '1.03',
							 'strict'                  => '1.03',
							 'warnings'                => '1.05',
							 'Convert::Color'          => '0.05',
							 'POSIX'                   => '1.09',
							},
				 recommends          => {
							 'Data::Dumper'            => '2.125',
							},
				 build_requires      => {
							 'Test::More'              => '0.8',
							 'Try::Tiny'               => '0.06',
							},
				 build_recommends    => {
							 'Test::Distribution'      => '2.00',
							 'Test::Perl::Critic'      => '1.01',
							},
				 'meta_merge' => {
							 'keywords' => [
								 'Sass',
								 'SCSS',
								 'CSS',
							 ],
							 'resources' => {
								 'repository' => 'https://github.com/rmp/libtext-sass-perl'
							 }
				 },
				 script_files        => qw(bin/sass2css.pl),
#				 sign                => 1,
				);

$builder->create_build_script();
