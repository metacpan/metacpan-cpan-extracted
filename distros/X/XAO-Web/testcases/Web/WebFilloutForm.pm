package testcases::Web::WebFilloutForm;
use strict;
use XAO::Projects;

use base qw(XAO::testcases::Web::base);

sub test_cc_validate {
    my $self=shift;

    my $form=XAO::Objects->new(objname => 'Web::FilloutForm');
    $self->assert(ref($form),
                  "Can't load Web::FilloutForm object");

    my %matrix=(
        '4111-1111-1111-1111' => {
            validated   => '4111111111111111',
            typecode    => 'VI',
        },
        '4111-1111-1111-1111/visa' => {
            validated   => '4111111111111111',
            typecode    => 'VI',
        },
        '4111-1111-1111-1111-3' => undef,
        '3712 345678 90120' => {
            validated   => '371234567890120',
            typecode    => 'AE',
        },
    );

    foreach my $test (keys %matrix) {
        my $number;
        my $type;
        if($test=~/^(.*?)(\/(.*?))?$/) {
            $number=$1;
            $type=$2;
        }
        else {
            $number=$test;
        }

        my $validated;
        my $typecode;
        my $rc=$form->cc_validate(
            number      => $number,
            type        => $type,
            validated   => \$validated,
            typecode    => \$typecode,
        );

        if($matrix{$test}) {
            $self->assert(!$rc,
                          "Test '$test' failed, got error ($rc)");
            $self->assert($validated eq $matrix{$test}->{'validated'},
                          "Test '$test' failed, expected validated to be '$matrix{$test}->{'validated'}', got $validated");
            $self->assert($typecode eq $matrix{$test}->{'typecode'},
                          "Test '$test' failed, expected typecode to be '$matrix{$test}->{'typecode'}', got $typecode");
        }
        else {
            $self->assert($rc,
                          "Test '$test' failed, expected to get an error");
        }
    }
}

1;
