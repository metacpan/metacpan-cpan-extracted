use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'class-object-methods.zzs' );

	return $runtime->evaluate($ast);
}

is eval_src(<<'SRC'), 'Bluey', 'class/object smoke: instance method dispatch works';
class Animal {
	let name;
	method get_name () {
		return name;
	}
}
let dog := new Animal( name: "Bluey" );
dog.get_name();
SRC

is eval_src(<<'SRC'), 'parent-static:child-static', 'class/object smoke: static super dispatch works';
class Parent {
	static method label () {
		return "parent-static";
	}
}
class Child extends Parent {
	static method label () {
		return super() _ ":child-static";
	}
}
Child.label();
SRC

is eval_src(<<'SRC'), 'parent:child', 'class/object smoke: instance super dispatch works';
class Parent {
	method label () {
		return "parent";
	}
}
class Child extends Parent {
	method label () {
		return super() _ ":child";
	}
}
let child := new Child();
child.label();
SRC

like dies {
	eval_src(<<'SRC');
class Animal {
	method age_plus ( Number age ) {
		return age + 1;
	}
}
let pet := new Animal();
pet.age_plus("old");
SRC
}, qr/TypeException/,
	'class/object smoke: typed method mismatch throws TypeException';

like dies {
	$parser->parse(<<'SRC', 'method-param-const.zzs');
class Animal {
	method bump ( Number age ) {
		age++;
		return age;
	}
}
SRC
}, qr/Cannot assign to const 'age' \(compile-time\)/,
	'class/object parser-level negative for const method params remains';

done_testing;
