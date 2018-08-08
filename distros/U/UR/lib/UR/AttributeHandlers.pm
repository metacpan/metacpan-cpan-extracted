package UR::AttributeHandlers;

use strict;
use warnings;
use attributes;

our @CARP_NOT = qw(UR::Namespace);

our $VERSION = "0.47"; # UR $VERSION;

# implement's UR's mechanism for sub/variable attributes.
my %support_functions = (
    MODIFY_CODE_ATTRIBUTES => \&modify_attributes,
    FETCH_CODE_ATTRIBUTES => \&fetch_attributes,
    MODIFY_SCALAR_ATTRIBUTES => \&modify_attributes,
);

sub import_support_functions_to_package {
    my $package = shift;

    while( my($name, $code) = each %support_functions ) {
        my $target = join('::', $package, $name);
        do {
            no strict 'refs';
            *$target = $code;
        };
    }
}


my %modify_attribute_handlers = (
    CODE => { Overrides => \&modify_code_overrides },
    SCALAR => { RoleParam => \&modify_scalar_role_property },
);
my %fetch_attribute_handlers = (
    CODE => { Overrides => \&fetch_code_overrides },
);

sub _modify_attribute_handler {
    my($ref, $attr) = @_;
    my $reftype = attributes::reftype($ref);
    return (exists($modify_attribute_handlers{$reftype}) and $modify_attribute_handlers{$reftype}->{$attr});
}

sub _fetch_attribute_handler {
    my($ref, $attr) = @_;
    my $reftype = attributes::reftype($ref);
    return (exists($fetch_attribute_handlers{$reftype}) and $fetch_attribute_handlers{$reftype}->{$attr});
}

sub _decompose_attr {
    my($raw_attr) = @_;
    my($attr, $params_str) = $raw_attr =~ m/^(\w+)(?:\((.*)\))$/;

    my @params = defined($params_str) ? split(/\s*,\s*/, $params_str) : ();
    $attr = $raw_attr unless defined $attr;
    return ($attr, @params);
}

sub modify_attributes {
    my($package, $ref, @raw_attrs) = @_;

    my @not_recognized;
    foreach my $raw_attr ( @raw_attrs ) {
        my($attr, @params) = _decompose_attr($raw_attr);
        if (my $handler = _modify_attribute_handler($ref, $attr)) {
            $handler->($package, $ref, $attr, @params);
        } else {
            push @not_recognized, $raw_attr;
        }
    }

    return @not_recognized;
}

my %stored_attributes_by_ref;

sub fetch_attributes {
    my($package, $ref) = @_;

    my $reftype = attributes::reftype($ref);
    my @attrs;
    foreach my $attr ( keys %{ $stored_attributes_by_ref{$ref} } ) {
        if (my $handler = _fetch_attribute_handler($ref, $attr)) {
            push @attrs, $handler->($package, $ref);
        }
    }
    return @attrs;
}

sub modify_code_overrides {
    my($package, $coderef, $attr, @params) = @_;

    my $list = $stored_attributes_by_ref{$coderef}->{overrides} ||= [];
    push @$list, @params;
}

sub modify_scalar_role_property {
    my($package, $scalar_ref, $attr, $name) = @_;

    unless ($name) {
        Carp::croak('RoleParam attribute requires a name in parens. For example: my $var : RoleParam(var)');
    }
    $$scalar_ref = UR::Role::Param->new(name => $name, role_name => $package, varref => $scalar_ref);
}

sub fetch_code_overrides {
    my($package, $coderef) = @_;

    return sprintf('overrides(%s)',
                    join(', ', @{ $stored_attributes_by_ref{$coderef}->{overrides} }));
}

sub get_overrides_for_coderef {
    my($ref) = @_;
    return( exists($stored_attributes_by_ref{$ref}) && exists($stored_attributes_by_ref{$ref}->{overrides})
                ? @{ $stored_attributes_by_ref{$ref}->{overrides} }
                : ()
            );
}

1;
