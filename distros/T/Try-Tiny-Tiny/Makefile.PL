use 5.006; use strict; use warnings;

my $sc = q<https://github.com/ap/Try-Tiny-Tiny>;
my $bt = q<https://rt.cpan.org/Public/Dist/Display.html?Name=Try-Tiny-Tiny>;

our %META = (
	name        => 'Try-Tiny-Tiny',
	author      => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	x_copyright => { holder => 'Aristotle Pagaltzis', year => 2017 },
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
				perl 5.006
				Try::Tiny 0
			)},
		},
	},
);

require './inc/WriteMakefile.pl';
