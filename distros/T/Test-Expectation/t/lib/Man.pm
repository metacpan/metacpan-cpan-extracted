package Man;
    sub new {
        bless {}, shift
    }

    sub die {
        $self = undef;
    }

    sub job {
    }

    sub work {
        shift->job('qualifications');
    }

    sub school {
        'fight'
    }

    sub beChild {
        my $self = shift;

        return 'has learned ' . $self->school();
    }

    sub std {
    }

    sub meetsWoman {
        my ($self, $quality) = @_;

        $self->std() if $quality eq 'hooker';
    }

    sub hired {}
    sub fired {}

    sub career {
        hired();
        fired();
    }
1;

