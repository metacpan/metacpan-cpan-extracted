use strict;
use warnings;

use Test::More 0.98;
use Test::Base::Less;

use Text::MustacheTemplate::Evaluator;

filters {
    function => [qw/chomp/],
    args     => [qw/eval/],
    expected => [qw/eval/],
};

my %blocks;
for my $block (blocks) {
    push @{ $blocks{$block->function} } => $block;
}

for my $function (sort keys %blocks) {
    my $evaluator = Text::MustacheTemplate::Evaluator->can($function);
    subtest $function => sub {
        for my $block (@{$blocks{$function}}) {
            my @args = @{ $block->args };
            my @result = $evaluator->(@args);
            is_deeply \@result, $block->expected, $block->name
                or diag explain \@args;
        }
    };
}

done_testing;
__DATA__

=== array ref should be opened
--- function: evaluate_section
--- args
[[qw/a b c/]]
--- expected
[qw/a b c/]

=== hash ref should be kept
--- function: evaluate_section
--- args
[{ a => 'b' }]
--- expected
[{ a => 'b' }]

=== scalar should be kept
--- function: evaluate_section
--- args
['value!']
--- expected
['value!']

=== zero should be empty
--- function: evaluate_section
--- args
[0]
--- expected
[]

=== empty string should be empty
--- function: evaluate_section
--- args
['']
--- expected
[]

=== undef should be empty
--- function: evaluate_section
--- args
[undef]
--- expected
[]

=== root value should be found
--- function: evaluate_section_variable
--- args
[
    [
        {
            foo => 'value!'
        }
    ],
    qw/foo/,
]
--- expected
['value!']

=== root value should not be found
--- function: evaluate_section_variable
--- args
[
    [
        {
            foo => 'value!'
        }
    ],
    qw/bar/,
]
--- expected
[]

=== nearest hashref value should be found in deep context
--- function: evaluate_section_variable
--- args
[
    [
        {
            foo => 'incorrect'
        },
        {},
        {
            foo => {
                bar => 'value!',
            },
        },
    ],
    qw/foo/,
]
--- expected
[{ bar => 'value!' }]

=== root value should not be found in deep context
--- function: evaluate_section_variable
--- args
[
    [
        {
            foo => {},
        },
        {},
        {
            foo => {
                bar => 'incorrect',
            },
        },
    ],
    qw/bar/,
]
--- expected
[]

=== nested value should be found
--- function: evaluate_section_variable
--- args
[
    [
        {
            foo => {
                bar => 'value!',
            }
        }
    ],
    qw/foo bar/,
]
--- expected
['value!']

=== nested value should not be found
--- function: evaluate_section_variable
--- args
[
    [
        {
            foo => 'value!'
        }
    ],
    qw/foo bar/,
]
--- expected
[]

=== nested scalar value should be found in deep context
--- function: evaluate_section_variable
--- args
[
    [
        {
            foo => {
                bar => 'value!',
            }
        },
        {},
        {
            foo => 'value!'
        },
        {},
    ],
    qw/foo bar/,
]
--- expected
['value!']

=== nested hashref value should be found in deep context
--- function: evaluate_section_variable
--- args
[
    [
        {
            foo => 'incorrect!'
        },
        {},
        {
            foo => {
                bar => {
                    buz => 'value!',
                }
            }
        },
        {},
    ],
    qw/foo bar/,
]
--- expected
[{ buz => 'value!' }]

=== root value should be found
--- function: retrieve_variable
--- args
[
    [
        {
            foo => 'value!'
        }
    ],
    qw/foo/,
]
--- expected
['value!']

=== root value should not be found
--- function: retrieve_variable
--- args
[
    [
        {
            foo => 'value!'
        }
    ],
    qw/bar/,
]
--- expected
['']

=== root value should be found in deep context
--- function: retrieve_variable
--- args
[
    [
        {
            foo => 'value!'
        },
        {},
        {
            foo => {
                bar => 'incorrect',
            },
        },
    ],
    qw/foo/,
]
--- expected
['value!']

=== root value should not be found in deep context
--- function: retrieve_variable
--- args
[
    [
        {
            foo => {},
        },
        {},
        {
            foo => {
                bar => 'incorrect',
            },
        },
    ],
    qw/bar/,
]
--- expected
['']

=== nested value should be found
--- function: retrieve_variable
--- args
[
    [
        {
            foo => {
                bar => 'value!',
            }
        }
    ],
    qw/foo bar/,
]
--- expected
['value!']

=== nested value should not be found
--- function: retrieve_variable
--- args
[
    [
        {
            foo => 'value!'
        }
    ],
    qw/foo bar/,
]
--- expected
['']

=== nested value should be found in deep context
--- function: retrieve_variable
--- args
[
    [
        {
            foo => {
                bar => 'value!',
            }
        },
        {},
        {
            foo => 'value!'
        },
        {},
    ],
    qw/foo bar/,
]
--- expected
['value!']

=== nested value should not be found in deep context
--- function: retrieve_variable
--- args
[
    [
        {
            foo => 'value!'
        },
        {},
        {
            foo => {
                bar => {
                    buz => 'incorrect!',
                }
            }
        },
        {},
    ],
    qw/foo bar/,
]
--- expected
['']

=== deepest context is preffered
--- function: retrieve_variable
--- args
[
    [
        {
            foo => 'incorrect!'
        },
        {
            foo => {
                bar => 'incorrect!',
            }
        },
        {
            foo => 'value!',
        },
        {
            foo => {
                bar => 'incorrect!',
            }
        },
    ],
    qw/foo/,
]
--- expected
['value!']