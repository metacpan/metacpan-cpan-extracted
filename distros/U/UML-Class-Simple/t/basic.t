use strict;
use warnings;

use Test::More tests => 39;
use Config;
use lib 'lib';
use UML::Class::Simple;
#use Data::Dumper::Simple;

my (@classes, $painter);

@classes = classes_from_runtime;
ok @classes > 5, 'a lot of classes found';

my @classes2 = grep_by_paths(\@classes, 'blib/lib', 'lib');
is join('', @classes2), 'UML::Class::Simple', 'only this module\'s packages remain';

@classes2 = exclude_by_paths(\@classes, $Config{installsitelib});
ok @classes2 < @classes, 'only this module\'s packages remain';
#warn "@classes2";

# [rt.cpan.org #22811] Yanick Champoux
@classes = classes_from_runtime( 'PPI' );
ok @classes, 'calling classes_from_runtime with one argument';

@classes = classes_from_runtime("PPI", qr/^PPI::/);
ok @classes > 5, 'a lot of PPI classes found';

@classes = classes_from_runtime(["PPI"], qr/^PPI::/);
ok @classes > 5, 'a lot of PPI classes found';

$painter = UML::Class::Simple->new(\@classes);
ok $painter, 'painter obj created';
isa_ok $painter, 'UML::Class::Simple';

is $painter->node_color, '#f1e1f4', "node_color's default value ok";

#warn Dumper($painter->as_dom);

my $imgfile = 't/ppi.png';
unlink $imgfile if -f $imgfile;
$painter->as_png($imgfile);
ok -f $imgfile, "image '$imgfile' generated";
ok((-s $imgfile) > 1000, 'image is not empty');

@classes = classes_from_runtime("PPI", qr/^PPI::Document$/);
is scalar(@classes), 1, 'PPI Document found (1)';
is $classes[0], 'PPI::Document', 'PPI Document found (2)';

# produce a class diagram for your CPAN module on the disk

@classes = classes_from_files(['lib/UML/Class/Simple.pm', 'lib/UML/Class/Simple.pm']);
is join(' ', @classes), 'UML::Class::Simple UML::Class::Simple', 'classes found';

@classes = classes_from_files(['lib/UML/Class/Simple.pm']);
is join(' ', @classes), 'UML::Class::Simple', 'classes found';

@classes = classes_from_files('lib/UML/Class/Simple.pm');
is join(' ', @classes), 'UML::Class::Simple', 'classes found';

$painter = UML::Class::Simple->new(\@classes);

# we can explicitly specify the image size
ok $painter->size(5, 3.6), 'setting size ok'; # in inches
my ($w, $h) = $painter->size;
is $w, 5, 'width ok';
is $h, '3.6', 'height ok';

warn "(Please ignore the warning in the following line.)\n";
ok ! $painter->size('foo', 'bar'), 'setting size with invalid values';
is $w, 5, 'width not changed';
is $h, '3.6', 'height not changed either';

# ...and change the default title background color:
$painter->node_color('#ffeeff'); # defaults to '#f1e1f4'
is $painter->node_color, '#ffeeff', "node_color's default value changed";

my $dom = $painter->as_dom;
ok $dom, '$dom ok';
ok ref $dom, '$dom is a ref';
is_deeply $dom, {
    classes => [
        { name       => 'UML::Class::Simple',
          methods    => [qw(
                _as_image _build_dom _gen_paths _load_file
                _normalize_path _property _runtime_packages
		_xmi_add_element _xmi_create_inheritance
		_xmi_get_new_id _xmi_init_xml _xmi_load_model
		_xmi_set_default_attribute _xmi_set_id
		_xmi_write_class _xmi_write_method
                any as_dom as_dot as_gif as_png as_svg as_xmi
                can_run carp
                classes_from_files classes_from_runtime
                confess display_inheritance display_methods dot_prog
                exclude_by_paths grep_by_paths
                inherited_methods moose_roles
                new node_color public_only
                run3 set_dom set_dot size
                        )],
          properties => [],
          subclasses => [],
        }
    ],
}, '$dom structure ok';

# only show public methods and properties
ok ! $painter->public_only, 'public_only defaults to false';
$painter->public_only(1);
ok $painter->public_only, 'public_only changed to true';

$dom = $painter->as_dom;
is_deeply $dom, {
    classes => [
        { name       => 'UML::Class::Simple',
          methods    => [qw(
                any as_dom as_dot as_gif as_png as_svg as_xmi
                can_run carp
                classes_from_files classes_from_runtime
                confess display_inheritance display_methods dot_prog
                exclude_by_paths grep_by_paths
                inherited_methods moose_roles
                new node_color public_only
                run3 set_dom set_dot size
                        )],
          properties => [],
          subclasses => [],
        }
    ],
}, '$dom structure ok';

my $dot = $painter->as_dot;
like $dot, qr/^digraph uml_class_diagram \{/, 'dot looks ok';
like $dot, qr/size="5,3.6";/, 'size set ok';
like $dot, qr/="\#ffeeff"/, 'color set ok';

my $dotfile = 't/me.dot';
unlink $dotfile if -f $dotfile;
$painter->as_dot($dotfile);
ok -f $dotfile, "dot file '$dotfile' generated";
ok -s $dotfile, "dot file '$dotfile' is not empty";

my $bin = $painter->as_png;
ok length($bin) > 1000, 'binary PNG data returned';

undef $bin;
eval { $bin = $painter->as_gif; };
#$@ = 'Renderer type: "gif" not recognized.';
SKIP: {
    skip "gif not supported in your graphviz install", 1
        if $@ && $@ =~ /not recognized/;

    ok length($bin) > 1000, 'binary GIF data returned';
};

# ignore inherited methods and properties
ok $painter->inherited_methods, 'inherited_methods defaults to true';
$painter->inherited_methods(0);
ok ! $painter->inherited_methods, 'inherited_methods changed to false';

$dom = $painter->as_dom;
is_deeply $dom, {
    classes => [
        { name       => 'UML::Class::Simple',
          methods    => [qw(
                as_dom as_dot as_gif as_png as_svg as_xmi
                can_run
                classes_from_files classes_from_runtime
                display_inheritance display_methods dot_prog
                exclude_by_paths grep_by_paths
                inherited_methods moose_roles
                new node_color public_only
                set_dom set_dot size
                        )],
          properties => [],
          subclasses => [],
        }
    ],
}, '$dom structure ok';


