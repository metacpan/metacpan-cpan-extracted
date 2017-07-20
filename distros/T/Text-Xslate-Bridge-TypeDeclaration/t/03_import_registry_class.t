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
    path         => path,
    cache_dir    => cache_dir,
    module => [
        'Text::Xslate::Bridge::TypeDeclaration',
    ],
);

my $specified = Text::Xslate->new(
    path         => path,
    cache_dir    => cache_dir,
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
};

subtest 'Meat' => sub {
    my @arg = ('meat.tx', { value => 'Beef' });
    like   $default->render(@arg),   qr/Declaration mismatch for `value`/, 'Not defined';
    unlike $specified->render(@arg), qr/Declaration mismatch for `value`/, 'From t::My::Registry';
};

subtest 'Enum' => sub {
    my @arg = ('enum.tx', { value => 'Beef' });
    unlike $default->render(@arg),   qr/Declaration mismatch for `value`/, 'Enum from Types::Standard';
    like   $specified->render(@arg), qr/Declaration mismatch for `value`/, 'Not imported';
};

subtest 't::SomeModel' => sub {
    my @arg = ('somemodel.tx', { value => t::SomeModel->new });
    unlike $default->render(@arg),   qr/Declaration mismatch for `value`/, 't::SomeModel generated';
    like   $specified->render(@arg), qr/Declaration mismatch for `value`/, 'Not generate';
};

subtest 'My::Registry::SomeModel' => sub {
    my @arg = ('aliased_somemodel.tx', { value => t::SomeModel->new });
    like   $default->render(@arg),   qr/Declaration mismatch for `value`/, 'Not aliased';
    unlike $specified->render(@arg), qr/Declaration mismatch for `value`/, 'From t::My::Registry';
};

subtest 'invalid type' => sub {
    my @arg = ('invalid_type.tx', { value => '' });
    like $default->render(@arg),   qr/Declaration mismatch for `value`/, 'Not aliased';
    like $specified->render(@arg), qr/Declaration mismatch for `value`/, 'From t::My::Registry';
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

@@ invalid_type.tx
<: declare(value => ''):><: $value :>
