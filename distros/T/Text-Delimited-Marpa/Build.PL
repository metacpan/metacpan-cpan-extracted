use strict;
use warnings;

use Module::Build;

# -----------------------------------------------

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
	module_name    => 'Text::Delimited::Marpa',
	license        => 'artistic_2',
	dist_abstract  => 'Extract delimited text sequences from strings',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		'Test::More' => 1.001006,
# 	 	'Test::Pod'  => 1.45, # Make it optional. See xt/author/pod.t.
	},
	configure_requires =>
	{
		'Module::Build' => 0.4210,
	},
	meta_merge =>
	{
		resources =>
		{
			repository => 'https://github.com/ronsavage/Text-Delimited-Marpa',
		},
	},
	requires =>
	{
		'Const::Exporter' => 'v0.2.3',
		'Marpa::R2'       => 2.096000,
		'Moo'             => 1.006000,
		'open'            => 0,
		'strict'          => 0,
		'Tree'            => 1.06,
		'Try::Tiny'       => 0.09,
		'Types::Standard' => 1.000004,
		'utf8'            => 0,
		'warnings'        => 0,
	},
	resources =>
	{
		bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Delimited-Marpa',
		license    => 'http://opensource.org/licenses/Artistic-2.0',
	},
) -> create_build_script();
