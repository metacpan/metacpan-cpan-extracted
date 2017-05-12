package Tree::Transform::XSLTish::Utils;
use strict;
use warnings;
use Class::MOP;

our $VERSION='0.3';

my $RULES_NAME='%_tree_transform_rules';

sub _rules_store {
    my $pack=Class::MOP::Class->initialize($_[0]);

    if (! $pack->has_package_symbol($RULES_NAME) ) {
        $pack->add_package_symbol($RULES_NAME,{});
    }
    return $pack->get_package_symbol($RULES_NAME);
}

our $ENGINE_FACTORY_NAME='_tree_transform_engine_factory';
my $ENGINE_FACTORY_NAME_WITH_SIGIL='&'.$ENGINE_FACTORY_NAME;

sub _set_engine_factory {
    my ($pack_name,$factory)=@_;
    my $pack=Class::MOP::Class->initialize($pack_name);

    $pack->add_package_symbol($ENGINE_FACTORY_NAME_WITH_SIGIL,$factory);

    return;
}


sub _get_inheritance {
    return Class::MOP::Class->initialize($_[0])->class_precedence_list;
}

1;
__END__

=head1 NAME

Tree::Transform::XSLTish::Utils - utility functions

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=cut
