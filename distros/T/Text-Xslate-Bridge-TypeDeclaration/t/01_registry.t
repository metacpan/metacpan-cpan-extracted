use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More;

use Text::Xslate::Bridge::TypeDeclaration::Registry;

my $registry = Text::Xslate::Bridge::TypeDeclaration::Registry->new;

{
    package TopLevelName;
    sub new { bless +{}, $_[0] }
}
{
    package t::Model::PP;
    sub new { bless +{}, $_[0] }
}
{
    package t::WithTypeTiny;
    use Type::Library -base, -declare => qw(Drink);
    use Type::Utils qw(enum);

    enum Drink => [qw(coffee black_tea cocoa green_tea)];
}
{
    package t::WithMouseX;
    use MouseX::Types -declare => [qw(Url)];
    use MouseX::Types::Mouse 'Str';

    subtype Url,
        as Str,
        where { $_ =~ m|\Ahttps?://.+| };
}

subtest 'lookup Standard' => sub {
    my $type = $registry->lookup('ArrayRef[Int]');
    ok  $type->check([1, 2, 3]);
    ok !$type->check([qw(one two three)]);
};

subtest 'treat as class type' => sub {
    my $toplevel = $registry->lookup('TopLevelName');
    ok  $toplevel->check(TopLevelName->new);
    ok !$toplevel->check(t::Model::PP->new);

    my $instance = $registry->lookup('t::Model::PP');
    ok  $instance->check(t::Model::PP->new);
    ok !$instance->check(TopLevelName->new);

    my $parameterized = $registry->lookup(
        'Dict[a => TopLevelName, b => t::Model::PP]'
    );
    ok  $parameterized->check({ a => TopLevelName->new, b => t::Model::PP->new });
    ok !$parameterized->check([ a => TopLevelName->new, b => t::Model::PP->new ]);
};

subtest 'package with TypeTiny' => sub {
    my $drink = $registry->lookup('t::WithTypeTiny::Drink');
    ok  $drink->check('coffee');
    ok !$drink->check('gasoline');

    my $parameterized = $registry->lookup('ArrayRef[t::WithTypeTiny::Drink]');
    ok  $parameterized->check(['cocoa', 'green_tea']);
    ok !$parameterized->check(['cocoa', 'cappuccino', 'black_tea']);
};

subtest 'package with MouseX' => sub {
    my $url = $registry->lookup('t::WithMouseX::Url');
    ok  $url->check('http://example.com');
    ok !$url->check('not url');

    my $parameterized = $registry->lookup('Tuple[t::WithMouseX::Url, Int]');
    ok  $parameterized->check(['https://example.com', 3]);
    ok !$parameterized->check(['file:///home/example', 3]);
};

subtest 'cache generated class_type' => sub {
    my $reg = Text::Xslate::Bridge::TypeDeclaration::Registry->new;
    is $reg->{'TopLevelName'}, undef;
    is $reg->{'t::Model::PP'}, undef;

    $reg->lookup('Dict[a => TopLevelName, b => t::Model::PP]');
    ok $reg->{'TopLevelName'}->isa('Type::Tiny::Class');
    ok $reg->{'t::Model::PP'}->isa('Type::Tiny::Class');
};

done_testing;
