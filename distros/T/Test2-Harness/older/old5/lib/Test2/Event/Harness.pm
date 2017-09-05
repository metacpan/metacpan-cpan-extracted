package Test2::Event::Harness;
use strict;
use warnings;

use Test2::Harness::Util::JSON qw/decode_json/;

use Carp qw/confess/;

use Test2::Util::Facets2Legacy ':ALL';

use base 'Test2::Event';
use Test2::Harness::HashBase qw/-facet_data/;

sub init {
    my $self = shift;

    confess("'facet_data' is a required attribute")
        unless $self->{+FACET_DATA};
}

{
    no warnings 'redefine';

    sub causes_fail {
        my $self = shift;
        return 1 if $self->{+FACET_DATA}->{harness}->{exit};
        return $self->Test2::Util::Facets2Legacy::causes_fail(@_);
    }
}

sub new_from_output {
    my $class = shift;
    my ($line, %harness_facet) = @_;

    my $source = $harness_facet{source} ||= 'output';

    return $class->new(
        facet_data => {
            harness => \%harness_facet,
            info    => [
                {
                    details => $line,
                    debug   => $source eq 'stderr' ? 1 : 0,
                    tag     => $source,
                },
            ],
        }
    );
}

sub load_from_stream_line {
    my $class = shift;
    my ($job_id, $line, $json) = @_;

    my $data = eval { decode_json($json) } or die "$job_id ($line): $@";
    my $facet_data = $data->{facets};

    my $stamp        = $data->{stamp};
    my $assert_count = $data->{assert_count};

    $facet_data->{harness} = {
        stamp        => $stamp,
        job_id       => $job_id,
        assert_count => $assert_count,
        source       => 'events',
        line         => $line,
        raw          => $json,
    };

    return $class->new(facet_data => $facet_data);
}

sub job_start {
    my $class = shift;
    my ($job_id, $stamp, $test) = @_;
    return $class->new(
        facet_data => {
            info => [
                {
                    details => $test,
                    tag     => 'LAUNCH',
                }
            ],
            harness => {
                stamp     => $stamp,
                job_id    => $job_id,
                job_start => 1,
                source    => 'harness',
                details   => $test,
            },
        },
    );
}

sub job_end {
    my $class = shift;
    my ($job_id, $stamp, $test, $exit) = @_;
    return $class->new(
        facet_data => {
            info => [
                {
                    details => $test,
                    tag     => 'FINISH',
                }
            ],
            harness => {
                stamp   => $stamp,
                job_id  => $job_id,
                job_end => 1,
                source  => 'harness',
                details => $test,
            },
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
