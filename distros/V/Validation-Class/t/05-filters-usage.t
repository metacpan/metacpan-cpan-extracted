use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

{

    package TestClass::FiltersUsage;

    use Validation::Class;

    filter 'flatten' => sub {
        $_[0] =~ s/[\t\r\n]+/ /g;
        return $_[0];
    };

    field 'biography' => {
        filters => ['trim', 'strip', 'flatten'],
        alias   => ['bio']
    };

    1;

    package main;

    my $biography = <<'TEXT';
    1. In arcu mi, sagittis vel pretium sit amet, tempor ac risus.
    2. Integer facilisis, ante ac tincidunt euismod, metus tortor.
    3. Suscipit erat, nec porta arcu urna eu nisl.
TEXT

    my $self;
    my $class = "TestClass::FiltersUsage";

    $self  = $class->new(biography => $biography);

    ok $class eq ref $self, "$class instantiated";
    is_deeply $self->fields->biography->filters, ['trim', 'strip', 'flatten'],
        "$class has biography field with filters trim, strip and flatten";
    ok $self->params->get('biography') =~ /^[^\n]+$/,
        "$class biography filter executed as expected";

    $self = $class->new(bio => $biography);

    ok $class eq ref $self, "$class instantiated";
    is_deeply $self->fields->biography->filters, ['trim', 'strip', 'flatten'],
        "$class has biography field with filters trim, strip and flatten";
    ok $self->params->get('biography') =~ /^[^\n]+$/,
        "$class biography filter executed as expected";

}

{

    package TestClass::FiltersAliasUsage::A;

    use Validation::Class;

    field 'full_name' => {
        filters => ['trim', 'strip', 'titlecase'],
        alias   => ['name']
    };

    1;

    package main;

    my $self;
    my $class = "TestClass::FiltersAliasUsage::A";

    $self = $class->new(full_name => 'elliot    ');

    ok $class eq ref $self, "$class instantiated";
    is_deeply $self->fields->full_name->filters, ['trim', 'strip', 'titlecase'],
        "$class has full_name field with filters trim, strip and titlecase";
    ok $self->param('full_name') =~ /^Elliot$/,
        "$class full_name filter executed as expected";

    $self = $class->new(name => '   elliot   ');

    ok $class eq ref $self, "$class instantiated";
    is_deeply $self->fields->full_name->filters, ['trim', 'strip', 'titlecase'],
        "$class has full_name field with filters trim, strip and titlecase";
    ok $self->param('full_name') =~ /^Elliot$/,
        "$class full_name filter executed as expected";

}

{

    package TestClass::FiltersAliasUsage::B;

    use Validation::Class;

    field 'full_name' => {
        filters => ['trim', 'strip', 'titlecase'],
        alias   => ['name']
    };

    1;

    package main;

    my $self;
    my $class = "TestClass::FiltersAliasUsage::B";

    $self = $class->new;
    $self->params->add({name => 'elliot    '});
    $self->prototype->normalize($self);

    ok $class eq ref $self, "$class instantiated";
    is_deeply $self->fields->full_name->filters, ['trim', 'strip', 'titlecase'],
        "$class has full_name field with filters trim, strip and titlecase";
    ok $self->full_name =~ /^Elliot$/,
        "$class full_name filter executed as expected";

    $self = $class->new;
    $self->params->add({name => '   elliot   '});
    $self->prototype->normalize($self);

    ok $class eq ref $self, "$class instantiated";
    is_deeply $self->fields->full_name->filters, ['trim', 'strip', 'titlecase'],
        "$class has full_name field with filters trim, strip and titlecase";
    ok $self->full_name =~ /^Elliot$/,
        "$class full_name filter executed as expected";

}

done_testing;
