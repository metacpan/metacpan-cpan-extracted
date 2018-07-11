package testcases::Web::WebSetArg;
use warnings;
use strict;
use XAO::Projects;

use base qw(XAO::testcases::Web::base);

###############################################################################

sub test_all {
    my $self=shift;

    my $page=XAO::Objects->new(objname => 'Web::Page');
    $self->assert(ref($page),
                  "Can't load Page object");

    my $t1='<%SetArg name="TEST" value="NEW"%><%TEST%><%End%>';
    my $t2='<%SetArg name="TEST" value="NEW" override%><%TEST%><%End%>';
    my $t3=<<'EOT';
<%SetArg
  name='TEST'
  value='NEW'
%>Is<%Condition
  a.arg='TEST=NEW'
  a.template='New'
  b.arg='TEST=OLD'
  b.template='Old'
  default.template='Default'
%><%End%>
EOT
    my $t4=<<'EOT';
<%SetArg
  name='TEST'
  value={<%Page template='NEW'%>}
%>Is<%Condition
  a.arg='TEST=NEW'
  a.template='New'
  b.arg='TEST=OLD'
  b.template='Old'
  default.template='Default'
%><%End%>
EOT

    my %matrix=(
        simple => {
            template    => $t1,
            tests       => {
                r1 => {
                    args => {
                        TEST => 'OLD',
                    },
                    result => 'OLD',
                },
                r2 => {
                    args => {
                    },
                    result => 'NEW',
                },
                r3 => {
                    args => {
                        TEST => undef,
                    },
                    result => 'NEW',
                },
            },
        },
        with_override => {
            template    => $t2,
            tests       => {
                r1 => {
                    args => {
                        TEST => 'OLD',
                    },
                    result => 'NEW',
                },
                r2 => {
                    args => {
                    },
                    result => 'NEW',
                },
                r3 => {
                    args => {
                        TEST => undef,
                    },
                    result => 'NEW',
                },
            },
        },
        cond_1 => {
            template    => $t3,
            tests       => {
                r1 => {
                    args => {
                        TEST => 'OLD',
                    },
                    result => 'IsOld',
                },
                r2 => {
                    args => {
                    },
                    result => 'IsNew',
                },
                r3 => {
                    args => {
                        TEST => undef,
                    },
                    result => 'IsNew',
                },
            },
        },
        cond_2 => {
            template    => $t4,
            tests       => {
                r1 => {
                    args => {
                        TEST => 'OLD',
                    },
                    result => 'IsOld',
                },
                r2 => {
                    args => {
                    },
                    result => 'IsNew',
                },
                r3 => {
                    args => {
                        TEST => undef,
                    },
                    result => 'IsNew',
                },
            },
        },
    );

    foreach my $phase (keys %matrix) {
        my $template=$matrix{$phase}->{'template'};
        my $tests=$matrix{$phase}->{'tests'};

        foreach my $test (keys %$tests) {
            my $args=$tests->{$test}->{'args'};
            my $got=$page->expand($args,{
                template    => $template,
            });
            my $expect=$tests->{$test}->{'result'};
            $self->assert($got eq $expect,
                          "Phase '$phase', test '$test' failed - expected '$expect', got '$got'");
        }
    }
}

###############################################################################
1;
