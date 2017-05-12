use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');

sub ACTION_authortest
{
	my($self) = @_;

	$self->depends_on('build');
	$self->depends_on('manifest');
	$self->depends_on('distmeta');

	$self->test_files( qw< t xt/author > );
	$self->recursive_test_files(1);

	$self->depends_on('test');

	return;
}
EOF

$class -> new
(
	module_name    => 'XML::Tiny::Tree',
	license        => 'artistic_2',
	dist_abstract  => 'Convert XML::Tiny output into a Tree',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		'Test::More' => 1.001014,
#		'Test::Pod'  => 1.48, # Make it optional. See xt/author/pod.t
	},
	configure_requires =>
	{
		'Module::Build' => 0.4211,
	},
	requires =>
	{
		'File::Spec'      => 0,
		'Moo'             => 1.007000,
		'strict'          => 0,
		'Tree'            => 1.07,
		'Types::Standard' => 1.000005,
		'warnings'        => 0,
		'XML::Tiny'       => 2.06,
	},
	resources =>
	{
		bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Tiny-Tree',
		license    => 'http://opensource.org/licenses/Artistic-2.0',
		repository => 'https://github.com/ronsavage/XML-Tiny-Tree',
	},
) -> create_build_script();

