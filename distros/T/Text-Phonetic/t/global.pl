
use Data::Dumper;
use Test::More;
use strict;
use warnings;

sub test_encode {
    my $object = shift;
    my $string = shift;
    my $expect = shift;
    
    my $result = $object->encode($string);
    
    
    if (ref($expect) eq 'ARRAY') {
        my $name = ref($object).': '.$expect->[0].' for '.$string;
        unless (ref($result) eq 'ARRAY'
            && scalar(@$result) == scalar(@$expect)) {
            fail($name.' length differs'.scalar(@$result));
            return;
        }
        for (0..(scalar @$expect -1)) {		
            next if (! defined $expect->[$_] && ! defined $result->[$_]);	
            unless ($expect->[$_] eq $result->[$_]) {
                fail($name.' got '. $result->[$_].' for pos '.$_);
                return;
            }
        }
        pass($name);
    } else {
        my $name = ref($object).': '.$expect.' for '.$string;
        is($result,$expect,$name);
    }
}

sub run_conditional {
    my ($predicate_class,$test_number) = @_;
    
    return 1
        unless $predicate_class;
    
    SKIP :{
        my $ok = eval {
            Class::Load::load_class($predicate_class);
            return 1;
        };
        unless ($ok) {
            skip "Not testing: $predicate_class is not installed",$test_number;
        }
    }
}

sub load_conditional {
    my ($test_class,$predicate_class) = @_;
    
    SKIP :{
        my $ok = eval {
            Class::Load::load_class($predicate_class);
            use_ok($test_class);
            return 1;
        };
        unless ($ok) {
            skip "Not testing $test_class: $predicate_class is not installed",1;
        }
    }
}

1;