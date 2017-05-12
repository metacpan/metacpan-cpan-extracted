
use strict;
use warnings;

use Test::More tests => 53;
use Test::NoWarnings;
use Test::Exception;
use Test::Differences;


use MooseX::Types::XMLSchema qw( :all );
use WSDL::Compile::Meta::Attribute::WSDL;
use Moose::Meta::Class;
use Moose::Meta::Attribute;

BEGIN {
    use_ok "WSDL::Compile::Utils", qw(
        wsdl_attributes
        parse_attr
        load_class_for_meta
    );
};


Moose::Meta::Class->create(
    'WSDL::Compile::Test::Op::Example::Request' => (
        version      => '0.01',
        attributes   => [
            Moose::Meta::Attribute->new(
                regular_attr_1 => (
                    is => 'rw',
                    isa => 'Str',
                ),
            ),
            WSDL::Compile::Meta::Attribute::WSDL->new(
                wsdl_attr_regular_isa_1 => (
                    is => 'rw',
                    isa => 'Str',
                    xs_type => 'xs:string',
                ),
            ),
            Moose::Meta::Attribute->new(
                regular_attr_2 => (
                    is => 'rw',
                    isa => 'Int',
                ),
            ),
            WSDL::Compile::Meta::Attribute::WSDL->new(
                wsdl_attr_xs_isa_1 => (
                    is => 'rw',
                    isa => 'xs:string',
                ),
            ),
            WSDL::Compile::Meta::Attribute::WSDL->new(
                wsdl_attr_xs_isa_2 => (
                    is => 'rw',
                    isa => 'ArrayRef[Maybe[xs:string]]',
                    xs_maxOccurs => 2,
                ),
            ),
        ],
    )
);

Moose::Meta::Class->create(
    'WSDL::Compile::Test::CT::ComplexType' => (
        version      => '0.01',
        attributes   => [
            Moose::Meta::Attribute->new(
                regular_attr_1 => (
                    is => 'rw',
                    isa => 'Str',
                ),
            ),
            WSDL::Compile::Meta::Attribute::WSDL->new(
                wsdl_attr_regular_isa_1 => (
                    is => 'rw',
                    isa => 'Str',
                    xs_type => 'xs:string',
                ),
            ),
            Moose::Meta::Attribute->new(
                regular_attr_2 => (
                    is => 'rw',
                    isa => 'Int',
                ),
            ),
            WSDL::Compile::Meta::Attribute::WSDL->new(
                wsdl_attr_xs_isa_1 => (
                    is => 'rw',
                    isa => 'xs:string',
                ),
            ),
            WSDL::Compile::Meta::Attribute::WSDL->new(
                wsdl_attr_xs_isa_2 => (
                    is => 'rw',
                    isa => 'ArrayRef[Maybe[xs:string]]',
                    xs_maxOccurs => 2,
                ),
            ),
        ],
    )
);


#diag "load_class_for_meta";
my $meta_req;
lives_ok {
    $meta_req = load_class_for_meta('WSDL::Compile::Test::Op::Example::Request');
} "load_class_for_meta executes ok for Moose class";
isa_ok $meta_req, "Moose::Meta::Class", '$meta';

my $meta_test;
lives_ok {
    $meta_test = load_class_for_meta('Test::More');
} "load_class_for_meta executes ok for non moose class";
isa_ok $meta_test, "Moose::Meta::Class", '$meta';

eval {
    load_class_for_meta('WSDL::Compile::Example::Of::Non::Existent::Class');
};
like $@, qr/Can't locate .* in \@INC/, "load_class_for_meta dies for non existent class";

#diag "wsdl_attributes";
my @expected_wsdl_attrs_order = qw(
    wsdl_attr_regular_isa_1
    wsdl_attr_xs_isa_1
    wsdl_attr_xs_isa_2
);

my @wsdl_attr;
lives_ok {
    @wsdl_attr = wsdl_attributes( $meta_req );
} "wsdl_attributes executes ok";

isa_ok  $_, 'WSDL::Compile::Meta::Attribute::WSDL',
    $_->name for @wsdl_attr;

is_deeply [ map { $_->name } @wsdl_attr ], \@expected_wsdl_attrs_order,
    "attributes returned in insertion order";

#diag "parse_attr";

my %expected_parsed_attr = (
    wsdl_attr_regular_isa_1 => {
        minOccurs => 0,
        maxOccurs => 1,
        name => "wsdl_attr_regular_isa_1",
        type => "xs:string",
    },
    wsdl_attr_xs_isa_1 => {
        minOccurs => 0,
        maxOccurs => 1,
        name => "wsdl_attr_xs_isa_1",
        type => "xs:string",
    },
    wsdl_attr_xs_isa_2 => {
        minOccurs => 0,
        maxOccurs => 2,
        ref => "ArrayOfWsdl_attr_xs_isa_2",
        complexType => {
            name => "ArrayOfWsdl_attr_xs_isa_2",
            type => "ArrayRef",
            attr => $meta_req->find_attribute_by_name("wsdl_attr_xs_isa_2"), 
            defined_in => {
                types_xs => 1,
            },
        }
    },
);
my %parsed_attr = map { $_->name => parse_attr($_) } @wsdl_attr;

is_deeply $parsed_attr{$_}, $expected_parsed_attr{$_},
    "$_ parsed attributes data as expected"
    for @expected_wsdl_attrs_order;


my @attrs;

push @attrs, Moose::Meta::Attribute->new(
    regular_attr => (
        is => 'rw',
        isa => 'Str',
    ),
);

eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/WSDL::Compile::Meta::Attribute::WSDL/,
    "parse_attr requires WSDL::Compile::Meta::Attribute::WSDL";


push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    missing_minOccurs=> (
        is => 'rw',
        isa => 'Str',
        required => 1,
    ),
);
eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/is required - xs_minOccurs cannot be set to 0/,
    "required attr has to have xs_minOccurs > 0";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    default_maxOccurs => (
        is => 'rw',
        isa => 'Str',
        required => 1,
        xs_minOccurs => 10,
    ),
);
eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/maxOccurs < minOccurs for /,
    "default xs_maxOccurs < xs_minOccurs";


push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    min_max_and_type => (
        is => 'rw',
        isa => 'Str',
        required => 1,
        xs_minOccurs => 1,
        xs_type => "xs:string",
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "parsed required attr with xs_minOccurs > 0 with xs_type works";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 1,
    maxOccurs => 1,
    name => "min_max_and_type",
    type => "xs:string",
}, "...and parsed attribute as expected";


push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    with_min_and_max => (
        is => 'rw',
        isa => 'Str',
        required => 1,
        xs_minOccurs => 1,
        xs_maxOccurs => 2,
        xs_type => "xs:string",
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "parsed attr with xs_maxOccurs";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 1,
    maxOccurs => 2,
    name => "with_min_and_max",
    type => "xs:string",
}, "...and parsed attribute as expected";


push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    min_higher_then_max => (
        is => 'rw',
        isa => 'Str',
        required => 1,
        xs_minOccurs => 10,
        xs_maxOccurs => 2,
        xs_type => "xs:string",
    ),
);
eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/maxOccurs < minOccurs for /, "minOccurs cannot be higher then maxOccurs";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    maxOccurs_unbounded => (
        is => 'rw',
        isa => 'Str',
        required => 1,
        xs_minOccurs => 10,
        xs_maxOccurs => undef,
        xs_type => "xs:string",
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "maxOccurs set to undef counts as infity";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 10,
    maxOccurs => "unbounded",
    name => "maxOccurs_unbounded",
    type => "xs:string",
}, "...and parsed attribute as expected";


push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    defaults_for_min_and_max => (
        is => 'rw',
        isa => 'Str',
        xs_type => "xs:string",
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "default values for minOccurs and maxOccurs";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 0,
    maxOccurs => 1,
    name => "defaults_for_min_and_max",
    type => "xs:string",
}, "...and parsed attribute as expected";


push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    attr_with_own_xsname => (
        is => 'rw',
        isa => 'Str',
        xs_type => "xs:string",
        xs_name => "my_own_name",
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "attr with xs_name set";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 0,
    maxOccurs => 1,
    name => "my_own_name",
    type => "xs:string",
}, "...and parsed attribute as expected";


push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    maybe_parent_regular_isa => (
        is => 'rw',
        isa => 'Maybe[Str]',
        xs_type => 'xs:string',
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "regular isa with Maybe[xs:string]";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 0,
    maxOccurs => 1,
    name => "maybe_parent_regular_isa",
    type => "xs:string",
    nillable => "true",
}, "...and parsed attribute as expected";


push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    maybe_parent_type_xmlschema => (
        is => 'rw',
        isa => 'Maybe[xs:string]',
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "MooseX::Types::XMLSchema isa with Maybe[xs:string]";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 0,
    maxOccurs => 1,
    name => "maybe_parent_type_xmlschema",
    type => "xs:string",
    nillable => "true",
}, "...and parsed attribute as expected";


push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    isa_ct => (
        is => 'rw',
        isa => 'WSDL::Compile::Test::CT::ComplexType',
        xs_ref => "isa_ct",
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "isa external class";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 0,
    maxOccurs => 1,
    ref => "isa_ct",
    complexType => {
        type => "Class",
        name => "isa_ct",
        attr => $attrs[-1],
        defined_in => {
            class => load_class_for_meta("WSDL::Compile::Test::CT::ComplexType"),
        },
    },
}, "...and parsed attribute as expected";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    unsupported_isa => (
        is => 'rw',
        isa => 'Int',
    ),
);
eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/Unsupported attribute type/, "isa with unsupported type";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    type_and_ref => (
        is => 'rw',
        isa => 'Maybe[Str]',
        xs_type => 'xs:string',
        xs_ref => 'customType',
    ),
);
eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/xs_ref .* is not supported for simple types for/, "both type and ref set";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    type_and_ref_types_xmlschema => (
        is => 'rw',
        isa => 'Maybe[xs:string]',
        xs_ref => 'customType',
    ),
);
eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/xs_ref .* is not supported for simple types for/,
    "both type and ref set using MooseX::Types::XMLSchema";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    array_of_maybes => (
        is => 'rw',
        isa => 'ArrayRef[Maybe[Str]]',
        xs_ref => 'ArrayOfMaybes',
        xs_maxOccurs => 2,
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "type param with Maybe";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 0,
    maxOccurs => 2,
    ref => "ArrayOfMaybes",
    complexType => {
        type => "ArrayRef",
        name => "ArrayOfMaybes",
        attr => $attrs[-1],
        defined_in => {
            types_xs => 1,
        },
    },
}, "...and parsed attribute as expected";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    array_of_ct => (
        is => 'rw',
        isa => 'ArrayRef[WSDL::Compile::Test::CT::ComplexType]',
        xs_ref => 'ArrayOfCT',
        xs_maxOccurs => 2,
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "type param with CT";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 0,
    maxOccurs => 2,
    ref => "ArrayOfCT",
    complexType => {
        type => "ArrayRef",
        name => "ArrayOfCT",
        attr => $attrs[-1],
        defined_in => {
            class => load_class_for_meta("WSDL::Compile::Test::CT::ComplexType"),
        },
    },
}, "...and parsed attribute as expected";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    array_of_maybes => (
        is => 'rw',
        isa => 'Maybe[ArrayRef[Maybe[Str]]]',
        xs_ref => 'ArrayOfMaybes',
        xs_maxOccurs => 2,
    ),
);
eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/cannot have nillable complex types/, "cannot have nillable complex types";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    hashref_as_parent => (
        is => 'rw',
        isa => 'HashRef[Str]',
        xs_ref => 'HashRefOfStr',
    ),
);
eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/is not supported - please use ArrayRef or complex type instead of HashRef for/,
    "HashRef is not supported as parent";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    hashref_as_param => (
        is => 'rw',
        isa => 'ArrayRef[HashRef]',
        xs_ref => 'ArrayOfHashRef',
        xs_maxOccurs => 2,
    ),
);
eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/is not supported - please use ArrayRef or complex type instead of HashRef for/,
    "HashRef is not supported as type param";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    nested_arrayref => (
        is => 'rw',
        isa => 'ArrayRef[Maybe[ArrayRef]]',
        xs_ref => 'ArrayOfNestedArrayRef',
        xs_maxOccurs => 2,
    ),
);
eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/ too deep nesting for /,
    "too deep nesting";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    array_with_maxoccurs_undef => (
        is => 'rw',
        isa => 'ArrayRef[Str]',
        xs_ref => 'ArrayOfStrings',
        xs_maxOccurs => undef,
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "ArrayRef supports maxOccurs unbounded";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 0,
    maxOccurs => "unbounded",
    ref => "ArrayOfStrings",
    complexType => {
        type => "ArrayRef",
        name => "ArrayOfStrings",
        attr => $attrs[-1],
        defined_in => {
            types_xs => 1,
        },
    },
}, "...and parsed attribute as expected";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    maybe_ct => (
        is => 'rw',
        isa => 'Maybe[WSDL::Compile::Test::CT::ComplexType]',
        xs_ref => "maybe_ct",
    ),
);
eval {
    parse_attr( $attrs[-1] )
};
like $@, qr/ is not supported - cannot have nillable complex types for /,
    "ComplexTypes cannot be nillable";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    ct_with_default_maxoccurs => (
        is => 'rw',
        isa => 'WSDL::Compile::Test::CT::ComplexType',
        xs_ref => "ct_with_default_maxoccurs",
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "complex type with default maxOccurs";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 0,
    maxOccurs => 1,
    ref => "ct_with_default_maxoccurs",
    complexType => {
        type => "Class",
        name => "ct_with_default_maxoccurs",
        attr => $attrs[-1],
        defined_in => {
            class => load_class_for_meta("WSDL::Compile::Test::CT::ComplexType"),
        },
    },
}, "...and parsed attribute as expected";

push @attrs, WSDL::Compile::Meta::Attribute::WSDL->new(
    ct_with_default_ref => (
        is => 'rw',
        isa => 'WSDL::Compile::Test::CT::ComplexType',
    ),
);
lives_ok {
    parse_attr( $attrs[-1] )
} "complex type with default ref";
is_deeply parse_attr( $attrs[-1] ), {
    minOccurs => 0,
    maxOccurs => 1,
    ref => "ct_with_default_ref",
    complexType => {
        type => "Class",
        name => "ct_with_default_ref",
        attr => $attrs[-1],
        defined_in => {
            class => load_class_for_meta("WSDL::Compile::Test::CT::ComplexType"),
        },
    },
}, "...and parsed attribute as expected";


