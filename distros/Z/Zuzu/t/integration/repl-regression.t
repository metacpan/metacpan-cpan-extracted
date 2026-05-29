use Test2::V0;

use File::Spec;
use Zuzu::CLI;

{
	package Local::ReplPromptEditor;

	sub new {
		return bless { prompts => [] }, shift;
	}

	sub readline {
		my ( $self, $prompt ) = @_;

		push @{ $self->{prompts} }, $prompt;
		return undef;
	}
}

my $repo_root = File::Spec->rel2abs(
	File::Spec->catdir( File::Spec->curdir )
);
my $zuzu_bin = File::Spec->catfile(
	$repo_root,
	'bin',
	'zuzu.pl',
);

ok -x $zuzu_bin, 'bin/zuzu.pl exists and is executable';

my $repl_cmd = join ' ',
	'printf',
	"'1\\n'",
	'|',
	"$^X",
	$zuzu_bin,
	'-R',
	'2>&1';
my $repl_output = qx{$repl_cmd};
my $repl_exit = $? >> 8;

is $repl_exit, 0, '-R exits cleanly after one-line input';
unlike $repl_output, qr/Redeclaration of 'BinaryString'/,
	'-R does not redeclare BinaryString when evaluating simple expressions';
like $repl_output, qr/\Q1\E/,
	'-R prints evaluated expression result';

my $editor = Local::ReplPromptEditor->new;
is Zuzu::CLI::_repl_read_line( $editor, 0, {} ), undef,
	'-R returns EOF from line editor';
is $editor->{prompts}[0], 'zuzu (^_^)> ',
	'-R gives line editor a prompt without literal ANSI reset text';
unlike $editor->{prompts}[0], qr/\e\[[0-9;]*m/,
	'-R line editor prompt does not include raw ANSI escapes';

done_testing;
