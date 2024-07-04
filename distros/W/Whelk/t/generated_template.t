use Kelp::Base -strict;
use Test::More;
use Test::Harness 'execute_tests';
use File::Temp 'tempdir';
use Path::Tiny;
use Kelp::Generator;

################################################################################
# This tests the generation template 'whelk' of kelp-generator. It uses
# Kelp::Generator by hand to make it uses the templates_dir in this tested
# package. It manually spews all the files into a tempdir and runs the tests of
# the generated app.
################################################################################

my $templates_dir = path(__FILE__)
	->parent    # t
	->parent    # whelk root
	->child('lib')
	->child('Kelp')
	->child('templates');

my $generator = Kelp::Generator->new(templates_dir => $templates_dir);
my $files = $generator->get_template('whelk', 'Foo');

test_app($files);

sub test_app
{
	my ($files) = @_;

	my $dir = tempdir(CLEANUP => 1);
	foreach my $file_data (@$files) {
		my ($path, $content) = @$file_data;

		path("$dir/$path")->parent->mkpath;
		path("$dir/$path")->spew({binmode => ':encoding(UTF-8)'}, $content);
	}

	push @INC, "$dir/lib";
	my ($total, $failed) = execute_tests(tests => ["$dir/t/whelk_Foo.t", "$dir/t/whelk_openapi.t"]);
	ok($total->{bad} == 0 && $total->{max} > 0, "Generated app tests OK")
		or diag explain $failed;
}

done_testing;

