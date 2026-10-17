use strict;
use warnings;
use Test::More;
use Test::Exception;
use Text::Fab;

use_ok('Text::Fab');

my $fab_dag = Text::Fab->new();
$fab_dag->NS__set_parents('Child', 'Parent');
$fab_dag->NS__set_parents('Parent', 'GrandParent');

throws_ok { $fab_dag->NS__set_parents('Loop', 'Loop') } qr/E_CYCLIC_INHERITANCE/,
    'self-inheritance dies with E_CYCLIC_INHERITANCE';

throws_ok { $fab_dag->NS__set_parents('GrandParent', 'Child') } qr/E_CYCLIC_INHERITANCE/,
    'cyclic inheritance across multiple nodes dies with E_CYCLIC_INHERITANCE';

my $fab_multi = Text::Fab->new();
$fab_multi->out__target_section('header', 'LayoutA');
push @{$fab_multi->{sections}{LayoutA}{header}}, ['text', 'Header from A'];

$fab_multi->out__target_section('footer', 'LayoutB');
push @{$fab_multi->{sections}{LayoutB}{footer}}, ['text', 'Footer from B'];

$fab_multi->out__target_section('body', 'Page');
$fab_multi->out__embed('header', 'Page');
push @{$fab_multi->{sections}{Page}{body}}, ['text', ' | Body | '];
$fab_multi->out__embed('footer', 'Page');

$fab_multi->NS__set_parents('Page', 'LayoutA', 'LayoutB');
is($fab_multi->assemble('Page:body'), 'Header from A | Body | Footer from B',
   'resolves sections across multiple parents in DAG order');

my $fab_missing = Text::Fab->new();
$fab_missing->out__target_section('main', 'NS');
$fab_missing->out__embed('nonexistent', 'NS');
throws_ok { $fab_missing->assemble('NS:main') } qr/E_EMBED_NOT_FOUND/,
    'unresolvable embed placeholder dies with E_EMBED_NOT_FOUND';

my $fab_loop = Text::Fab->new();
$fab_loop->out__target_section('sec_a', 'NS');
$fab_loop->out__embed('sec_b', 'NS');

$fab_loop->out__target_section('sec_b', 'NS');
$fab_loop->out__embed('sec_a', 'NS');

throws_ok { $fab_loop->assemble('NS:sec_a') } qr/E_CIRCULAR_EMBED/,
    'circular embed chain dies with E_CIRCULAR_EMBED';

my $fab_asif = Text::Fab->new();
$fab_asif->out__target_section('sidebar', 'GrandParent');
push @{$fab_asif->{sections}{GrandParent}{sidebar}}, ['text', 'Default Sidebar'];

$fab_asif->out__target_section('sidebar', 'Parent');
push @{$fab_asif->{sections}{Parent}{sidebar}}, ['text', 'Custom Parent Sidebar'];

$fab_asif->NS__set_parents('Parent', 'GrandParent');
$fab_asif->NS__set_parents('Child', 'Parent');

$fab_asif->out__target_section('normal', 'Child');
$fab_asif->out__embed('sidebar', 'Child');
is($fab_asif->assemble('Child:normal'), 'Custom Parent Sidebar',
   'normal embed finds Child/Parent override');

$fab_asif->out__target_section('static', 'Child');
$fab_asif->out__embed('sidebar', 'Child', { asiffrom => 'GrandParent' });
is($fab_asif->assemble('Child:static'), 'Default Sidebar',
   'asiffrom embed resolves starting directly from specified context');

my $fab_blind = Text::Fab->new();
$fab_blind->out__target_section('widget', 'GrandParent');
push @{$fab_blind->{sections}{GrandParent}{widget}}, ['text', 'GrandParent Widget'];

$fab_blind->out__target_section('widget', 'Parent');
push @{$fab_blind->{sections}{Parent}{widget}}, ['text', 'Parent Widget'];

$fab_blind->NS__set_parents('Parent', 'GrandParent');
$fab_blind->NS__set_parents('Child', 'Parent');

$fab_blind->cfg__set('Fab/blinders/hide_parent', sub {
    my ($fab, $info) = @_;
    return ('Parent');
});

$fab_blind->out__target_section('body', 'Child');
$fab_blind->out__embed('widget', 'Child', { with_blinder => 'hide_parent' });

is($fab_blind->assemble('Child:body'), 'GrandParent Widget',
   'with_blinder dynamically obscures specified namespace branch in DAG');

my $fab_directive = Text::Fab->new();
$fab_directive->process_string("#set_parents NS1 NS2 NS3");
is_deeply($fab_directive->cfg__get('Fab/inheritance_graph/NS1/parents'), ['NS2', 'NS3'],
   '#set_parents directive sets inheritance graph');

my $fab_nest = Text::Fab->new();

$fab_nest->out__target_section('inner_leaf', 'RootNS');
push @{$fab_nest->{sections}{RootNS}{inner_leaf}}, ['text', 'Inner Content'];

$fab_nest->out__target_section('mid_layer', 'RootNS');
$fab_nest->out__embed('inner_leaf', 'RootNS', { with_blinder => 'inner_blinder' });

$fab_nest->out__target_section('top', 'RootNS');
$fab_nest->out__embed('mid_layer', 'RootNS', { with_blinder => 'outer_blinder' });

my @captured_stack;
$fab_nest->cfg__set('Fab/blinders/outer_blinder', sub {
    return ('DummyOuter');
});

$fab_nest->cfg__set('Fab/blinders/inner_blinder', sub {
    my ($fab, $info) = @_;
    @captured_stack = @{$info->{embed_stack}};
    return ();
});

$fab_nest->assemble('RootNS:top');

is(scalar @captured_stack, 1, 'inner blinder received 1 enclosing embed frame');
is_deeply($captured_stack[0]{blinder_output}, ['DummyOuter'],
   'inner blinder successfully saw enclosing blinder_output on the stack');

done_testing();
