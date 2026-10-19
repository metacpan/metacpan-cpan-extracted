use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;
use Text::Fab;

use_ok('Text::Fab');

subtest 'Parser: #prepend and #pop directives' => sub {
    my $fab = Text::Fab->new(config => {
        'Fab/list_keys' => { test_list => 1 },
    });
    $fab->cfg__set('test_list', ['c']);

    $fab->process_string("#prepend test_list a b");
    is_deeply($fab->cfg__get('test_list'), ['a', 'b', 'c'], '#prepend prepends elements in order');

    $fab->process_string("#pop test_list 1");
    is_deeply($fab->cfg__get('test_list'), ['a', 'b'], '#pop removes element via directive');
};

subtest 'Parser: #create_section, #target_section stack and #end_section' => sub {
    my $fab = Text::Fab->new();
    $fab->process_string(<<'END');
#target_section outer in Base
Outer Start
#target_section inner in Sub
Inner Content
#end_section
Outer End
END

    is($fab->assemble('Sub:inner'), "Inner Content", 'inner section created');
    is($fab->assemble('Base:outer'), "Outer Start\nOuter End", '#end_section restored previous target section');

    $fab->process_string("#create_section cleared in Base\n#create_section cleared in Base");
    is_deeply($fab->{sections}{Base}{cleared}, [], '#create_section creates empty section');
};

subtest 'Parser: qualified names in #emb' => sub {
    my $fab = Text::Fab->new();
    $fab->out__create_section('title', 'ChapterLayout');
    push @{$fab->{sections}{ChapterLayout}{title}}, ['text', 'Chapter Title'];

    $fab->out__create_section('main', 'Book');
    $fab->out__target_section('main', 'Book');
    $fab->process_string("#emb ChapterLayout:title");

    is($fab->assemble('Book:main'), 'Chapter Title', '#emb with qualified NS:Basename syntax resolves');
};

subtest 'Call stack prefix lifecycle' => sub {
    my $fab = Text::Fab->new();

    $fab->call_stack__push('Fab/sub_filter/', 'my_filter');
    is($fab->{config}{'Fab/call_stack_prefixes'}[-1], 'Fab/sub_filter/', 'prefix pushed');
    is($fab->{config}{'Fab/call_stack_filter_name'}[-1], 'my_filter', 'filter name pushed');

    $fab->cfg__set_prefixed('scoped_var', 'filter_val');
    is($fab->cfg__get('Fab/sub_filter/scoped_var'), 'filter_val',
       'cfg__set_prefixed writes under the active pushed prefix');

    my $popped = $fab->call_stack__pop();
    is($popped, 'Fab/sub_filter/', 'prefix popped');
    is(scalar @{$fab->{config}{'Fab/call_stack_prefixes'}}, 1, 'returned to root prefix');

    throws_ok { $fab->call_stack__pop() } qr/E_UPLEVEL_TOO_DEEP/,
        'popping base prefix dies with E_UPLEVEL_TOO_DEEP';
};

subtest 'Inclusion stack introspection' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'inc.fab');
    open my $fh, '>', $file or die $!;
    print $fh "#set inside_inc=1\n";
    close $fh;

    my $fab = Text::Fab->new();
    $fab->process_string("#include $file");

    is($fab->cfg__get('inside_inc'), 1, '#include persists config changes (no rollback)');
    is_deeply($fab->cfg__get('opened_includes'), [], 'opened_includes cleared after EOF');
};

subtest 'Parser error standardization (E_SYNTAX_ERROR)' => sub {
    my $fab = Text::Fab->new();
    throws_ok { $fab->process_string("#invalid_directive foo") } qr/E_SYNTAX_ERROR/,
        'unknown directive dies with E_SYNTAX_ERROR';
    throws_ok { $fab->process_string("# malformed directive") } qr/E_SYNTAX_ERROR/,
        'malformed directive line dies with E_SYNTAX_ERROR';
};

done_testing();
