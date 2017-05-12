use FindBin;
use Test::More;
use Data::Dumper;

use utf8;
use strict;
use warnings;

{

    package TestClass::A;

    use Validation::Class;

    field word => {
        all_caps => 1
    };

    directive all_caps => sub {

        my ($self, $field, $param) = @_;

        if (defined $field->{all_caps} && defined $param) {

            my $length = $field->{all_caps};

            if ($field->{required} || $param) {

                unless ($param =~ /^[A-Z]+$/) {

                    $field->errors->add("This is all wrong");

                }

            }

        }

        return $self;

    };

    package main;

    my $class = "TestClass::A";
    my $self  = $class->new(word => 'blah blah');

    ok $class eq ref $self, "$class instantiated";
    ok $self->proto->directives->has('all_caps'), "$class has foreign all_caps directives";
    ok !$self->validate('word'), 'word is not in all caps';
    ok $self->error_count, 'an error was registered';

}

# NO SUPPORT FOR FOREIGN DIRECTIVES ATM, COMING SOON
#{
#
#    package AllCaps;
#
#    use base 'Validation::Class::Directive';
#
#    use Validation::Class::Directives;
#    use Validation::Class::Util;
#
#    has 'mixin'   => 1;
#    has 'field'   => 1;
#    has 'multi'   => 0;
#    has 'message' => '%s should be exactly %s characters';
#
#    sub validate {
#
#        my $self = shift;
#
#        my ($proto, $field, $param) = @_;
#
#        if (defined $field->{all_caps} && defined $param) {
#
#            my $length = $field->{all_caps};
#
#            if ($field->{required} || $param) {
#
#                unless ($param =~ /^[A-Z]+$/) {
#
#                    $self->error(@_, $length);
#
#                }
#
#            }
#
#        }
#
#        return $self;
#
#    }
#
#    package TestClass::B;
#
#    use Validation::Class;
#
#    field word => {
#        all_caps => 1
#    };
#
#    package main;
#
#    my $class = "TestClass::B";
#    my $self  = $class->new(word => 'blah blah');
#
#    ok $class eq ref $self, "$class instantiated";
#    ok $self->proto->directives->has('all_caps'), "$class has foreign all_caps directives";
#    ok !$self->validate('word'), 'word is not in all caps';
#
#    warn $self->errors_to_string;
#
#}

done_testing;
