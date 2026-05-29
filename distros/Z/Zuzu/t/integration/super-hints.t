use Test2::V0;

use Zuzu::Parser;

my $parser = Zuzu::Parser->new;

my $source = <<'SRC';
class Parent {
	method label () {
		return "parent";
	}
	static method static_label () {
		return "parent-static";
	}
}
class Child extends Parent {
	method plain () {
		return "plain";
	}
	method label () {
		return super() _ ":child";
	}
	static method static_label () {
		return super() _ ":child-static";
	}
}
SRC

my $ast = $parser->parse($source, 'super-hints.zzs');

my $child_class = $ast->statements->[1];
is $child_class->methods->[0]->uses_super, 0,
	'method without super is not marked';
is $child_class->methods->[1]->uses_super, 1,
	'instance method with super is marked';
is $child_class->static_methods->[0]->uses_super, 1,
	'static method with super is marked';

my $unanalysed_ast = Zuzu::Parser->new(
	disabled_visitors => ['SuperHints'],
)->parse($source, 'super-hints-disabled.zzs');
my $unanalysed_child_class = $unanalysed_ast->statements->[1];
is $unanalysed_child_class->methods->[0]->uses_super, undef,
	'method without SuperHints keeps unknown super state';
is $unanalysed_child_class->methods->[1]->uses_super, undef,
	'instance method with disabled SuperHints keeps unknown super state';
is $unanalysed_child_class->static_methods->[0]->uses_super, undef,
	'static method with disabled SuperHints keeps unknown super state';

done_testing;
