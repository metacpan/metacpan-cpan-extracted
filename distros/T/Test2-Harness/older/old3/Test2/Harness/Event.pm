package Test2::Harness::Event;
use strict;
use warnings;

BEGIN {
    local $@ = undef;
    my $ok = eval {
        require JSON::MaybeXS;
        JSON::MaybeXS->import('JSON');
        1;
    };

    $ok ||= eval {
        require JSON::PP;
        *JSON = sub() { 'JSON::PP' };
    };

    die "Could not find either JSON::MaybeXS or JSON::PP, you must install a JSON library before using " . __PACKAGE__ . "\n"
        unless $ok;
}

use Carp qw/confess/;

use Test2::Util::Facets2Legacy ':ALL';

use Test2::Harness::HashBase qw/-facet_data -job_id -stamp -assert_count -source -is_start -is_end/;

use base 'Test2::Event';

sub init {
    my $self = shift;

    confess("'facet_data' is a required attribute")
        unless $self->{+FACET_DATA};
}

sub load {
    my $class = shift;
    my ($job_id, $json) = @_;

    my $data = eval { JSON->new->decode($json) } or die "JSON decode error: $@$json";
    my $facet_data   = $data->{facets};
    my $stamp        = $data->{stamp};
    my $assert_count = $data->{assert_count};

    return $class->new(
        facet_data   => $facet_data,
        stamp        => $stamp,
        job_id       => $job_id,
        assert_count => $assert_count,
        source       => 'events',
    );
}

sub job_start {
    my $class = shift;
    my ($job_id, $stamp, $test) = @_;
    return $class->new(
        stamp    => $stamp,
        job_id   => $job_id,
        is_start => 1,

        facet_data => {
            info => [
                {
                    details => $test,
                    tag     => 'LAUNCH',
                }
            ],
        },
    );
}

sub job_end {
    my $class = shift;
    my ($job_id, $stamp, $test, $exit) = @_;
    return $class->new(
        stamp  => $stamp,
        job_id => $job_id,
        is_end => 1,

        facet_data => {
            info => [
                {
                    details => $test,
                    tag     => 'FINISH',
                }
            ],
            $exit
            ? (
                errors => [
                    {
                        details => "'$test' exited with error code $exit",
                        fail    => 1,
                        tag     => 'BAD EXIT',
                    },
                ],
                )
            : (),
        },
    );
}

1;
