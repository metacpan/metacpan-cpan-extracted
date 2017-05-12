package Test::Steering::Wheel;

use warnings;
use strict;
use Carp;
use TAP::Harness;
use Scalar::Util qw(refaddr);

=head1 NAME

Test::Steering::Wheel - Execute tests and renumber the resulting TAP.

=head1 VERSION

This document describes Test::Steering::Wheel version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Test::Steering::Wheel;

    my $wheel = Test::Steering::Wheel->new;
    $wheel->include_tests( 'xt/vms/*.t' ) if $^O eq 'VMS';
    $wheel->include_tests( 'xt/windows/*.t' ) if $^O =~ 'MSWin32';

=head1 DESCRIPTION

Behind the scenes in L<Test::Steering> is a singleton instance of
C<Test::Steering::Wheel>.

See L<Test::Steering> for more information.

=head1 INTERFACE

=head2 C<< new >>

Create a new C<Test::Steering::Wheel>.

=over

=item C<< add_prefix >>

=item C<< announce >>

=item C<< defaults >>

=item C<< harness >>

=back

=cut

{
    my %DEFAULTS;

    BEGIN {
        %DEFAULTS = (
            add_prefix => 0,
            announce   => 0,
            defaults   => {},
            harness    => 'TAP::Harness',
        );

        for my $method ( keys %DEFAULTS ) {
            no strict 'refs';
            *{ __PACKAGE__ . '::' . $method } = sub {
                my $self = shift;
                croak "$method may not be set" if @_;
                return $self->{$method};
            };
        }
    }

    sub new {
        my $class = shift;
        croak "Must supply an even number of arguments" if @_ % 1;
        my %args = ( %DEFAULTS, @_ );

        my @bad = grep { !exists $DEFAULTS{$_} } keys %args;
        croak "Illegal option(s): ", join ', ', sort @bad if @bad;

        return bless { _test_number_adjust => 0, %args }, $class;
    }

    # Documentation lower down
    sub option_names {
        my $class = shift;
        return sort keys %DEFAULTS;
    }
}

# Output demultiplexer. Handles output associated with multiple parsers.
# If parsers output sequentially no buffering is done. If, however,
# output from multiple parsers is interleaved output from the first
# encountered will be echoed directly and output from all the others
# will be buffered.
#
# After a parser finishes (calls $done) the next parser to generate
# output will have its buffer flushed and will start output directly.
#
# The upshot of all this is that we output from multiple parsers doing
# the minimum amount of buffering necessary to keep per-parser output
# ordered.

sub _output_demux {
    my ( $self, $printer, $complete ) = @_;
    my $current_id = undef;
    my %queue_for  = ();
    my @completed  = ();

    my $finish = sub {
        while ( my $job = shift @completed ) {
            my ( $parser, $buffered ) = @$job;
            $printer->( $parser, @$_ ) for @$buffered;
            $complete->( $parser );
        }
    };

    return (
        # demux
        sub {
            my ( $parser, $type, $line ) = @_;
            my $id = refaddr $parser;

            unless ( defined $current_id ) {
                # Our chance to take over...
                if ( $self->announce ) {
                    my $name = $self->_name_for_parser( $parser );
                    print STDERR "# Running $name\n";
                }
                if ( my $buffered = delete $queue_for{$id} ) {
                    $printer->( $parser, @$_ ) for @$buffered;
                }
                $current_id = $id;
            }

            if ( $current_id == $id ) {
                $printer->( $parser, $type, $line );
            }
            else {
                push @{ $queue_for{$id} }, [ $type, $line ];
            }

        },
        # done
        sub {
            my $parser = shift;
            my $id     = refaddr $parser;
            if ( defined $current_id && $current_id == $id ) {
                # Finished the current one so allow another to
                # take over
                $complete->( $parser );
                undef $current_id;
                # Flush any others that have completed in the mean time
                $finish->();
            }
            else {
                # Add to completed list
                push @completed, [ $parser, delete $queue_for{$id} ];
            }
        },
        # finish
        $finish,
    );
}

sub _name_for_parser {
    my $self   = shift;
    my $parser = shift;
    my $id     = refaddr $parser;
    return $self->{parser_name}->{$id} unless @_;
    return $self->{parser_name}->{$id} = shift;
}

# Like ok
sub _output_result {
    my ( $self, $ok, $description ) = @_;
    printf( "%sok %d %s\n",
        $ok ? '' : 'not ',
        ++$self->{_test_number_adjust}, $description );
}

# Output additional test failures if our subtest had problems.

sub _parser_postmortem {
    my ( $self, $parser ) = @_;

    my $test = $self->_name_for_parser( $parser );

    my @errs = ();

    push @errs, "$test: Parse error: $_" for $parser->parse_errors;

    my ( $wait, $exit ) = ( $parser->wait, $parser->exit );
    push @errs, "$test: Non-zero status: exit=$exit, wait=$wait"
      if $exit || $wait;

    if ( @errs ) {
        $self->_output_result( 0, $_ ) for @errs;
    }
    else {
        $self->_output_result( 1, "$test done" );
    }
}

sub _load {
    my $class = shift;
    unless ( $INC{$class} || eval "use $class; 1" ) {
        croak "Can't load $class: $@";
    }
    return $class;
}

=head2 C<< include_tests >>

Run one or more tests. Wildcards will be expanded.

    include_tests( 'xt/vms/*.t' ) if $^O eq 'VMS';
    include_tests( 'xt/windows/*.t' ) if $^O =~ 'MSWin32';

=cut

sub include_tests {
    my ( $self, @tests ) = @_;

    my %options = ( verbosity => -9, %{ $self->defaults } );
    my @real_tests = ();

    # Split options hashes from tests
    for my $t (
        map { 'ARRAY' eq ref $_ ? $_ : [ $_, $_ ] }
        map { ref $_ ? $_ : glob $_ } @tests
      ) {
        if ( 'HASH' eq ref $t ) {
            %options = ( %options, %$t );
        }
        else {
            push @real_tests,
              grep { !$self->{_seen}->{ $_->[1] }++ } $t;
        }
    }

    my $harness    = _load( $self->harness )->new( \%options );
    my $add_prefix = $self->add_prefix;

    my $printer = sub {
        my ( $parser, $type, $line ) = @_;
        print "TAP version 13\n" unless $self->{_started}++;
        if ( $type eq 'test' ) {
            $line =~ s/(\d+)/$1 + $self->{_test_number_adjust}/e;
            if ( $add_prefix ) {
                my $name = $self->_name_for_parser( $parser );
                $line =~ s/(\d+)[ \t]*(\S+)/$1: $2/;
                $line =~ s/(\d+)/$1 $name/;
            }
        }
        print $line;
    };

    my $complete = sub {
        my $parser    = shift;
        my $tests_run = $parser->tests_run;
        $self->{_test_number_adjust} += $parser->tests_run;
    };

    my ( $demux, $done, $finish )
      = $self->_output_demux( $printer, $complete );

    $harness->callback(
        made_parser => sub {
            my ( $parser, $test_desc ) = @_;

            $self->_name_for_parser( $parser, $test_desc->[1] );

            $parser->callback( plan    => sub { } );
            $parser->callback( version => sub { } );
            $parser->callback(
                test => sub {
                    my $test = shift;
                    my $raw  = $test->as_string;
                    $demux->( $parser, 'test', "$raw\n" );
                }
            );
            $parser->callback(
                ELSE => sub {
                    my $result = shift;
                    $demux->( $parser, 'raw', $result->raw . "\n" );
                }
            );
            $parser->callback(
                EOF => sub {
                    $done->( $parser );
                    $self->_parser_postmortem( $parser );
                }
            );
        }
    );

    my $aggregator = $harness->runtests( @real_tests );
    $finish->();
}

=head2 C<end_plan>

Output the trailing plan.

=cut

sub end_plan {
    my $self = shift;
    if ( my $plan = $self->{_test_number_adjust} ) {
        print "1..$plan\n";
        $self->{_test_number_adjust} = 0;
    }
}

=head2 C<< tests_run >>

Get a list of tests that have been run.

    my @tests = $wheel->tests_run();

=cut

sub tests_run {
    my $self = shift;
    return sort keys %{ $self->{_seen} || {} };
}

=head2 C<< option_names >>

Get the names of the supported options to C<new>. Used by L<Test::Steering>
to validate its arguments.

=cut

1;

__END__

=head1 CONFIGURATION AND ENVIRONMENT

Test::Steering::Wheel requires no configuration files or environment
variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-steering@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
