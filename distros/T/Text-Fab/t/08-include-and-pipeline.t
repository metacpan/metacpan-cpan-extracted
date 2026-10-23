use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;
use Text::Fab;

use_ok('Text::Fab');

my $bracket_preprocessor = sub {
    my ($fab, $chunk) = @_;
    return "[$chunk]";
};

my $fab_comment = Text::Fab->new(config => {
    'Fab/callbacks' => {
        %{Text::Fab->new->cfg__get('Fab/callbacks')},
        chunk_preprocessor => $bracket_preprocessor,
    }
});

$fab_comment->out__create_section('body', '_main');
$fab_comment->out__target_section('body', '_main');
$fab_comment->process_string("Part1\n#set dummy=1\nPart2");
is($fab_comment->assemble('_main:body'), "[Part1\n][Part2]",
   'standard directives separate text chunks, preserving line endings');

my $fab_fuse = Text::Fab->new(config => {
    'Fab/callbacks' => {
        %{Text::Fab->new->cfg__get('Fab/callbacks')},
        chunk_preprocessor => $bracket_preprocessor,
    }
});
$fab_fuse->out__create_section('body', '_main');
$fab_fuse->out__target_section('body', '_main');
$fab_fuse->process_string("Part1\n## this is a comment\nPart2");
is($fab_fuse->assemble('_main:body'), "[Part1\nPart2]",
   'comment directives fuse preceding and succeeding chunks across comment boundary');

my $fab_inc = Text::Fab->new();
$fab_inc->include__text('string', "#set inc_var=included_ok\nIncluded Text");
is($fab_inc->cfg__get('inc_var'), 'included_ok', 'include__text processes string directives');

my $dir = tempdir(CLEANUP => 1);
my $file_a = File::Spec->catfile($dir, 'file_a.fab');
my $file_b = File::Spec->catfile($dir, 'file_b.fab');

open my $fh_b, '>', $file_b or die $!;
print $fh_b "#set in_b=yes\nContent B\n";
close $fh_b;

open my $fh_a, '>', $file_a or die $!;
print $fh_a "#include $file_b\nContent A\n";
close $fh_a;

my $fab_file = Text::Fab->new();
$fab_file->include__text('filename', $file_a);
is($fab_file->cfg__get('in_b'), 'yes', 'nested #include via filename sets config');

my $missing = File::Spec->catfile($dir, 'missing_file.fab');
throws_ok { $fab_file->include__text('filename', $missing) } qr/E_FILE_READ_ERROR/,
    'including nonexistent file dies with E_FILE_READ_ERROR';

my $file_cycle1 = File::Spec->catfile($dir, 'cycle1.fab');
my $file_cycle2 = File::Spec->catfile($dir, 'cycle2.fab');

open my $c1, '>', $file_cycle1 or die $!;
print $c1 "#include $file_cycle2\n";
close $c1;

open my $c2, '>', $file_cycle2 or die $!;
print $c2 "#include $file_cycle1\n";
close $c2;

throws_ok { $fab_file->include__text('filename', $file_cycle1) } qr/E_CYCLIC_INCLUDE/,
    'circular include chain dies with E_CYCLIC_INCLUDE';

my $file_scoped = File::Spec->catfile($dir, 'scoped.fab');
open my $fs, '>', $file_scoped or die $!;
print $fs "#set scoped_var=temporary\n";
close $fs;

my $fab_scoped = Text::Fab->new();
$fab_scoped->cfg__set('scoped_var', 'original');
$fab_scoped->process_string("#include_scoped $file_scoped temp_scope");
is($fab_scoped->cfg__get('scoped_var'), 'original',
   '#include_scoped rolls back configuration changes made within the included file');

throws_ok { $fab_scoped->process_string("#include_scoped only_one_arg") } qr/E_SYNTAX_ERROR/,
   '#include_scoped with insufficient arguments dies with E_SYNTAX_ERROR';

subtest 'Strict arity and container modes for #include' => sub {
    my $fab_c = Text::Fab->new(config => {
        'Fab/list_keys' => { 'joiners/comma' => 1, 'my_list' => 1 },
    });
    $fab_c->cfg__set('joiners/comma', [', ']);
    $fab_c->cfg__set('my_list', ['alpha', 'beta', 'gamma']);

    $fab_c->out__create_section('src_sec', '_main');
    push @{$fab_c->{sections}{_main}{src_sec}}, ['text', 'SecLine1'], ['text', 'SecLine2'];

    $fab_c->out__create_section('dest_sec', '_main');
    $fab_c->out__target_section('dest_sec', '_main');

    $fab_c->process_string("#include configkey joiners/comma my_list");
    $fab_c->process_string("#include section joiners/comma _main:src_sec");

    my $joined_out = $fab_c->assemble('_main:dest_sec');
    like($joined_out, qr/alpha, beta, gamma/, 'included configkey with cyclic joiner');
    like($joined_out, qr/SecLine1, SecLine2/, 'included section with cyclic joiner');

    throws_ok { $fab_c->process_string("#include section missing_arg") } qr/E_SYNTAX_ERROR/,
        '#include section with missing arguments dies with E_SYNTAX_ERROR';

    throws_ok { $fab_c->process_string("#include filename a b c") } qr/E_SYNTAX_ERROR/,
        '#include filename with excess arguments dies with E_SYNTAX_ERROR';

    throws_ok { $fab_c->include__text('filename', 'f1', 'f2') } qr/E_TYPE_MISMATCH/,
        'include__text filename with excess arguments dies with E_TYPE_MISMATCH';

    throws_ok { $fab_c->include__text('section', 'only_one') } qr/E_TYPE_MISMATCH/,
        'include__text section with missing arguments dies with E_TYPE_MISMATCH';
};

done_testing();
