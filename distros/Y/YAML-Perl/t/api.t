package YAML::Foo::Loader;
use YAML::Perl::Loader -base;
package YAML::Bar::Loader;
use YAML::Perl::Loader -base;
package YAML::Foo::Dumper;
use YAML::Perl::Dumper -base;
package YAML::Bar::Dumper;
use YAML::Perl::Dumper -base;
package YAML::Foo::Resolver;
use YAML::Perl::Resolver -base;
package YAML::Bar::Resolver;
use YAML::Perl::Resolver -base;

package main;
use t::TestYAMLPerl tests => 21;

use YAML::Perl;

my $class = 'YAML::Perl';

for my $type (qw(Loader Dumper Resolver)) {
    pass "$type tests ---------------------------------------------------------";

    my $method = lc($type);
    my $class_method = lc($type) . '_class';
    no strict 'refs';

    my $object_class = $class->$class_method;
    is $object_class, "$class\::$type",
        "Call to $class->$class_method method works";

    is ref($class->$method), "$class\::$type",
        "Call to $class->$method produces a $type object";

    is ref($class->new->$method), "$class\::$type",
        "Call to $class->new->$method produces a $type object";

    is ref($class->new->$class_method("YAML::Foo::$type")->$method), "YAML::Foo::$type",
        "Call to $class->new->$class_method(\"YAML::Foo::$type\")->$method produces a YAML::Foo::$type object";

    ${"YAML::${type}Class"} = "YAML::Foo::$type";
    is ref($class->$method), "YAML::Foo::$type",
        "$class->$method respects \$YAML::${type}Class";

    ${"YAML::Perl::${type}Class"} = "YAML::Bar::$type";
    is ref($class->$method), "YAML::Bar::$type",
        "$class->$method respects \$YAML::Perl::${type}Class";
}
