package UR::Object::Value;

use strict;
use warnings;
use UR;
our $VERSION = "0.46"; # UR $VERSION;

class UR::Object::Value {
    is => 'UR::Value',
    is_abstract => 1,
    subclassify_by => 'entity_class_name',
    type_has => [
        entity_class_name   => { is => 'Text' },
    ],
    has => [
        rule                => { is => 'UR::BoolExpr', id_by => 'id' },
        entity_class_name   => { via => 'rule', to => 'subject_class_name' },
    ],
    doc => 'an unordered group of distinct UR::Objects'
};

sub AUTOSUB {
    my ($method,$class) = @_;
    my $entity_class_name = $class;
    $entity_class_name =~ s/::Value$//g; 
    return unless $entity_class_name; 
    my $code = $entity_class_name->can($method);
    return $code if $code;
}

1;

