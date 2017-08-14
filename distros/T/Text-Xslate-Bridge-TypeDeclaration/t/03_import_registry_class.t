use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More;

use Text::Xslate;

{
    package t::My::Registry;
    use Type::Registry;
    use Type::Utils qw(class_type enum);

    my $reg = Type::Registry->for_me;
    $reg->add_type(enum([qw(Beef Pork Chicken)]), 'Meat');
    $reg->add_type(class_type({ class => 't::SomeModel' }), 'My::Registry::SomeModel');
}

my $default = Text::Xslate->new(
    type      => 'text' ,
    path      => path,
    cache_dir => cache_dir,
    module => [
        'Text::Xslate::Bridge::TypeDeclaration',
    ],
);

my $specified = Text::Xslate->new(
    type      => 'text' ,
    path      => path,
    cache_dir => cache_dir,
    module => [
        'Text::Xslate::Bridge::TypeDeclaration' => [
            registry_class => 't::My::Registry',
        ],
    ],
);

subtest 'Int' => sub {
    my @arg = ('int.tx', { value => 123 });
    unlike $default->render(@arg),   qr/Declaration mismatch for `value`/, 'Int from Types::Standard';
    like   $specified->render(@arg), qr/Declaration mismatch for `value`/, 'Not imported';
    like   $specified->render(@arg), qr/\Q"Int" is not a known type\E/;
};

subtest 'Meat' => sub {
    my @arg = ('meat.tx', { value => 'Beef' });
    like   $default->render(@arg),   qr/Declaration mismatch for `value`/, 'Not defined';
    like   $default->render(@arg), qr/\Q"Beef" did not pass type constraint (not isa Meat)\E/;
    unlike $specified->render(@arg), qr/Declaration mismatch for `value`/, 'From t::My::Registry';
};

subtest 'Enum' => sub {
    my @arg = ('enum.tx', { value => 'Beef' });
    unlike $default->render(@arg),   qr/Declaration mismatch for `value`/, 'Enum from Types::Standard';
    like   $specified->render(@arg), qr/Declaration mismatch for `value`/, 'Not imported';
    like   $specified->render(@arg), qr/\Q"Enum[\"Beef\", \"Pork\", \"Chicken\"]" is not a known type\E/;
};

subtest 't::SomeModel' => sub {
    my @arg = ('somemodel.tx', { value => t::SomeModel->new });
    unlike $default->render(@arg),   qr/Declaration mismatch for `value`/, 't::SomeModel generated';
    like   $specified->render(@arg), qr/Declaration mismatch for `value`/, 'Not generate';
    like   $specified->render(@arg), qr/\Q"t::SomeModel" is not a known type\E/;
};

subtest 'My::Registry::SomeModel' => sub {
    my @arg = ('aliased_somemodel.tx', { value => t::SomeModel->new });
    like   $default->render(@arg),   qr/Declaration mismatch for `value`/, 'Not aliased';
    like   $default->render(@arg),   qr/\QReference bless( {}, 't::SomeModel' ) did not pass type constraint (not isa My::Registry::SomeModel)\E/;
    unlike $specified->render(@arg), qr/Declaration mismatch for `value`/, 'From t::My::Registry';
};

subtest 'Parameterized' => sub {
    my @arg = ('parameterized.tx', { value => [t::OneModel->new, t::OneModel->new] });
    unlike $default->render(@arg),   qr/Declaration mismatch for `value`/, 't::OneModel generated in a ArrayRef';
    like   $specified->render(@arg), qr/Declaration mismatch for `value`/, 'Not generate';
    like   $specified->render(@arg), qr/\Q"ArrayRef[t::OneModel]" is not a known type\E/;
};

subtest 'Hash structured' => sub {
    my @arg = ('hash_structure.tx', { value => { m => t::AnotherModel->new } });
    unlike $default->render(@arg),   qr/Declaration mismatch for `value`/, 't::AnotherModel generated';
    like   $specified->render(@arg), qr/Declaration mismatch for `value`/, 'Not generate';
    like   $specified->render(@arg), qr/\Qdid not pass type constraint "Dict[m=>"t::AnotherModel",slurpy Any]"\E/;
};

subtest 'invalid type' => sub {
    my @arg = ('invalid_type.tx', { value => '' });
    like $default->render(@arg),   qr/Declaration mismatch for `value`/, 'Not aliased';
    like $default->render(@arg),   qr/\Q"" is not a known type\E/;
    like $specified->render(@arg), qr/Declaration mismatch for `value`/, 'From t::My::Registry';
    like $specified->render(@arg),   qr/\Q"" is not a known type\E/;
};

done_testing;

__DATA__
@@ int.tx
<: declare(value => 'Int'):><: $value :>

@@ meat.tx
<: declare(value => 'Meat'):><: $value :>

@@ enum.tx
<: declare(value => 'Enum["Beef", "Pork", "Chicken"]'):><: $value :>

@@ somemodel.tx
<: declare(value => 't::SomeModel'):><: $value :>

@@ aliased_somemodel.tx
<: declare(value => 'My::Registry::SomeModel'):><: $value :>

@@ parameterized.tx
<: declare(value => 'ArrayRef[t::OneModel]'):><: $value[0] :>

@@ hash_structure.tx
<: declare(value => { m => 't::AnotherModel' }):><: $value["m"] :>

@@ invalid_type.tx
<: declare(value => ''):><: $value :>
