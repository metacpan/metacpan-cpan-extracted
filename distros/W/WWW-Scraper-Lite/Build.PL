# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2011-06-02 22:46:31 +0100 (Thu, 02 Jun 2011) $
# Id:            $Id: Build.PL 15 2011-06-02 21:46:31Z rmp $
# Source:        $Source$
# $HeadURL: svn+ssh://psyphi.net/repository/svn/www-scraper-lite/trunk/Build.PL $
#
use strict;
use warnings;
use Module::Build;
use lib qw(lib);

my $builder = Module::Build->new(
				 dist_name           => 'WWW-Scraper-Lite',
				 dist_version_from   => 'lib/WWW/Scraper/Lite.pm',
				 dist_author         => 'Roger Pettett <rmp@psyphi.net>',
				 dist_abstract       => q[Simple web scraper with XPath support],
				 license             => 'perl',
				 requires            => {
							 'English'                  => '1.01',
							 'Carp'                     => '1.02',
							 'Readonly'                 => '1.03',
							 'HTML::TreeBuilder::XPath' => '0.12',
                                                         'LWP::UserAgent'           => '6.02',
                                                         'strict'                   => '1.04',
                                                         'warnings'                 => '1.06',

							},
				 recommends          => {
                                                         'CAM::PDF'       => '1.54',
                                                         'CGI'            => '3.52',
                                                         'Data::Dumper'   => '2.130_02',
                                                         'Date::Parse'    => '2.30',
                                                         'DateTime'       => '0.70',
                                                         'DBI'            => '1.616',
                                                         'File::Temp'     => '0.22',
                                                         'Getopt::Long'   => '2.38',
                                                         'HTML::Entities' => '3.68',
                                                         'Module::Build'  => '0.38',
                                                         'Readonly'       => '1.03',
                                                         'Time::HiRes'    => '1.972101',
							},
				 build_requires      => {
							 'Test::More'              => '0.8',
							},
				 build_recommends    => {
							 'Test::Distribution'      => '2.00',
							 'Test::Perl::Critic'      => '1.01',
							},
				 sign                => 1,
				);

$builder->create_build_script();
