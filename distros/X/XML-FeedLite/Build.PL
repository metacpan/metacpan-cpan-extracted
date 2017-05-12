use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
				 module_name         => 'XML::FeedLite',
				 dist_author         => 'Roger M Pettett <rpettett@cpan.org>',
				 version_from        => 'XML/FeedLite.pm',
				 dist_abstract       => q[XML::FeedLite - A simple RSS & Atom feed processor],
				 license             => 'perl',
				 requires            => {
							 'WWW::Curl::Simple' => '0.100181',
							 'HTTP::Request'            => '1.40',
							 'HTTP::Headers'            => '1.64',
							 'HTML::Entities'           => '1.35',
							 'MIME::Base64'             => '3.07_01',
							 'Readonly'                 => '1.03',
							},
				 recommends          => {
							},
				 build_requires      => {
							 'Test::Distribution'  => '0',
							 'Test::Perl::Critic'  => '0',
							 'Test::More'          => '0.8',
							},
				 build_recommends    => {
							 'Test::Distribution' => '0',
							 'Test::Perl::Critic' => '0',
							},
				 create_makefile_pl  => 'passthrough',
				);

$builder->create_build_script();
