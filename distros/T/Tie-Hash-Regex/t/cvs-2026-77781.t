use strict;
use warnings;

use Test::More;

use Tie::Hash::Regex;

sub fresh {
    my %h;

    tie %h, 'Tie::Hash::Regex';

    $h{alice} = 'record-A';
    $h{bob}   = 'record-B';
    $h{carol} = 'record-C';

    return \%h;
}

#
# First make sure the normal behaviour still works.
#

{
    my $h = fresh();

    is(
        $h->{alice},
        'record-A',
        'exact lookup works',
    );

    is(
        $h->{'^car'},
        'record-C',
        'regex lookup works',
    );

    is(
        $h->{'^zzz'},
        undef,
        'well-formed regex with no match returns undef',
    );
}

#
# Regression tests for CVE-2026-77781.
#
# A malformed regex used as a lookup key should be treated as a
# non-match, rather than throwing an exception from FETCH, EXISTS
# or DELETE.
#

my @payloads = (
    '(',
    '[',
    '*',
    '+',
    '?',
    '\\',
    '(?<',
    '(?{',
);

for my $payload (@payloads) {
    subtest "malformed pattern '$payload'" => sub {
        {
            my $h = fresh();

            my ($value, $error);

            {
                local $@;
                eval {
                    $value = $h->{$payload};
                    1;
                } or $error = $@;
            }

            is(
                $error,
                undef,
                'FETCH does not die',
            );

            is(
                $value,
                undef,
                'FETCH treats malformed pattern as no match',
            );
        }

        {
            my $h = fresh();

            my ($exists, $error);

            {
                local $@;
                eval {
                    $exists = exists $h->{$payload};
                    1;
                } or $error = $@;
            }

            is(
                $error,
                undef,
                'EXISTS does not die',
            );

            ok(
                !$exists,
                'EXISTS treats malformed pattern as no match',
            );
        }

        {
            my $h = fresh();

            my ($deleted, $error);

            {
                local $@;
                eval {
                    $deleted = delete $h->{$payload};
                    1;
                } or $error = $@;
            }

            is(
                $error,
                undef,
                'DELETE does not die',
            );

            is(
                $deleted,
                undef,
                'DELETE treats malformed pattern as no match',
            );

            is_deeply(
                [sort keys %$h],
                [qw(alice bob carol)],
                'failed DELETE leaves hash unchanged',
            );
        }
    };
}

done_testing;
