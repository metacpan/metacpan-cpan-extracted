use 5.008001; use strict; use warnings;

my $sc = q<https://github.com/ap/XML-Builder>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Builder>;

our %META = (
	name        => 'XML-Builder',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2015 },
	license     => 'perl_5',
	resources   => {
		license    => [ q<https://dev.perl.org/licenses/> ],
		repository => { type => 'git', url => "$sc.git", web => $sc },
		bugtracker => { web => $bt },
	},
	dynamic_config => 0,
	prereqs => {
		runtime => {
			requires => {qw(
				perl 5.008001
				overload 0
				Scalar::Util 0
				Object::Tiny::Lvalue 0
				Encode 0
				Carp::Clan 0
			)},
		},
		test => {
			requires => {qw(
				Test::More 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
