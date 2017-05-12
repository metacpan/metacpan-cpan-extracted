package Test::Parallel;
{
  $Test::Parallel::VERSION = '0.20';
}
use strict;
use warnings;
use Test::More ();
use Parallel::ForkManager;
use Sys::Info;

# ABSTRACT: launch your test in parallel

=head1 NAME
Test::Parallel - simple object interface to launch unit test in parallel

=head1 VERSION

version 0.20

=head1 DESCRIPTION

Test::Parallel is a simple object interface used to launch test in parallel.
It uses Parallel::ForkManager to launch tests in parallel and get the results.

Alias for basic methods are available

    ok is isnt like unlike cmp_ok is_deeply

=head1 Usage

=head2 Wrap common Test::More methods
    
It can be used nearly the same way as Test::More

    use Test::More tests => 8;
    use Test::Parallel;
    
    my $p = Test::Parallel->new();
    
    # queue some tests that can be parallelized
    $p->ok( sub { 1 }, "can do ok" );
    $p->is( sub { 42 }, 42, "can do is" );
    $p->isnt( sub { 42 }, 51, "can do isnt" );
    $p->like( sub { "abc" }, qr{ab}, "can do like: match ab");
    $p->unlike( sub { "abc" }, qr{xy}, "can do unlike: match ab");
    $p->cmp_ok( sub { 'abc' }, 'eq', 'abc', "can do cmp ok");
    $p->cmp_ok( sub { '1421' }, '==', 1_421, "can do cmp ok");
    $p->is_deeply( sub { [ 1..15 ] }, [ 1..15 ], "can do is_deeply");

    # run the tests in background
    $p->done();

=head2 Implement your own logic

You could also use the results returned by the test function to launch multiple test

    use Test::Parallel;
    use Test::More;

    my $p = Test::Parallel->new();
    $p->add( sub { 
        # will be launched in parallel
        # any code that take time to execute need to go there
        my $time = int( rand(42) );
        sleep( $time );
        return { number => 123, time => $time };
    },
        sub {
            # will be execute from the main thread ( not in parallel )
            my $result = shift;
            is $result->{number} => 123;
            cmp_ok $result->{time}, '<=', 42;                    
        }
     );
    
    $p->done();

=for Pod::Coverage ok is isnt like unlike cmp_ok is_deeply can_ok isa_ok

=head1 METHODS

=head2 new

Create a new Test::Parallel object.
By default it will use the number of cores you have as a maximum limit of parallelized job,
but you can control this value with two options :
- max_process : set the maximum process to this value
- max_process_per_cpu : set the maximum process per cpu, this value
will be multiplied by the number of cpu ( core ) avaiable on your server
- max_memory : in MB per job. Will use the minimum between #cpu and total memory available / max_memory

    my $p = Test::Parallel->new()
        or Test::Parallel->new( max_process => N )
        or Test::Parallel->new( max_process_per_cpu => P )
        or Test::Parallel->new( max_memory => M )

=cut

my @methods = qw{ok is isnt like unlike cmp_ok is_deeply can_ok isa_ok};

sub new {
    my ( $class, %opts ) = @_;

    my $self = bless {}, __PACKAGE__;

    $self->_init(%opts);

    return $self;
}

=head2 ok

Same as Test::More::ok but need a code ref in first argument

=head2 is

Same as Test::More::is but need a code ref in first argument

=head2 isnt

Same as Test::More::isnt but need a code ref in first argument

=head2 like

Same as Test::More::like but need a code ref in first argument

=head2 unlike

Same as Test::More::unlike but need a code ref in first argument

=head2 cmp_ok

Same as Test::More::cmp_ok but need a code ref in first argument

=head2 is_deeply

Same as Test::More::is_deeply but need a code ref in first argument

=cut

sub _init {
    my ( $self, %opts ) = @_;

    $self->_add_methods();
    $self->_pfork(%opts);
    $self->{result} = {};
    $self->{pfork}->run_on_finish(
        sub {
            my ( $pid, $exit, $id, $exit_signal, $core_dump, $data ) = @_;
            die "Failed to process on one job, stop here !"
              if $exit || $exit_signal;
            $self->{result}->{$id} = $data->{result};
        }
    );
    $self->{jobs}  = [];
    $self->{tests} = [];
}

sub _pfork {
    my ( $self, %opts ) = @_;

    my $cpu;
    if ( defined $opts{max_process} ) {
        $cpu = $opts{max_process};
    }
    else {
        my $factor = $opts{max_process_per_cpu} || 1;
        eval { $cpu = Sys::Info->new()->device('CPU')->count() * $factor; };
    }
    if ( defined $opts{max_memory} ) {
        my $free_mem;
        eval {
            require Sys::Statistics::Linux::MemStats;
            $free_mem = Sys::Statistics::Linux::MemStats->new->get->{realfree};
        };
        my $max_mem = $opts{max_memory} * 1024;    # 1024 **2 = 1 GO => expr in Kb
        my $cpu_for_mem;
        if ($@) {
            warn "Cannot guess amount of available free memory need Sys::Statistics::Linux::MemStats";
            $cpu_for_mem = 2;
        }
        else {
            $cpu_for_mem = int( $free_mem / $max_mem );
        }

        # min
        $cpu = ( $cpu_for_mem < $cpu ) ? $cpu_for_mem : $cpu;
    }
    $cpu ||= 1;

    # we could also set a minimum amount of required memory
    $self->{pfork} = new Parallel::ForkManager( int($cpu) );
}

=head2 $pm->add($code)

You can manually add some code to be launched in parallel,
but if you uses this method you will need to manipulate yourself the final
result. 

Prefer using one of the following methods :
    
    ok is isnt like unlike cmp_ok is_deeply

=cut

sub add {
    my ( $self, $code, $test ) = @_;

    return unless $code && ref $code eq 'CODE';
    push(
        @{ $self->{jobs} },
        { name => ( scalar( @{ $self->{jobs} } ) + 1 ), code => $code }
    );
    push( @{ $self->{tests} }, $test );
}

=head2 $p->run

will run and wait for all jobs added
you do not need to use this method except if you prefer to add jobs yourself and manipulate the results

=cut

sub run {
    my ($self) = @_;

    return unless scalar @{ $self->{jobs} };
    my $pfm = $self->{pfork};
    for my $job ( @{ $self->{jobs} } ) {
        $pfm->start( $job->{name} ) and next;
        my $job_result = $job->{code}();

        # can be used to stop on first error
        my $job_error = 0;
        $pfm->finish( $job_error, { result => $job_result } );
    }

    # wait for all jobs
    $pfm->wait_all_children;

    return $self->{result};
}

sub _add_methods {

    return unless scalar @methods;

    foreach my $sub (@methods) {
        my $accessor = __PACKAGE__ . "::$sub";
        my $map_to   = "Test::More::$sub";
        next unless defined &{$map_to};

        # allow symbolic refs to typeglob
        no strict 'refs';
        *$accessor = sub {
            my ( $self, $code, @args ) = @_;
            $self->add( $code, { test => $map_to, args => \@args } );
        };
    }

    @methods = ();
}

=head2 $p->done

    you need to call this function when you are ready to launch all jobs in bg
    this method will call run and also check results with Test::More

=cut

sub done {
    my ($self) = @_;

    # run tests
    die "Cannot run tests" unless $self->run();

    my $c = 0;

    # check all results with Test::More
    my $results = $self->results();
    map {
        my $test = $_;
        return unless $test;
        die "cannot find result for test #${c}" unless exists $results->[$c];
        my $res = $results->[ $c++ ];

        if ( ref $test eq 'HASH' ) {

            # internal mechanism
            return unless defined $test->{test} && defined $test->{args};

            my @args = ( $res, @{ $test->{args} } );
            my $t    = $test->{test};
            my $str  = join( ', ', map { "\$args[$_]" } ( 0 .. $#args ) );
            eval "$t(" . $str . ")";
        }
        elsif ( ref $test eq 'CODE' ) {

            # execute user function
            $test->($res);
        }

    } @{ $self->{tests} };

}

=head2 $p->results

    get an array of results, in the same order of jobs

=cut

sub results {
    my ($self) = @_;

    my @sorted =
      map  { $self->{result}{$_} }
      sort { int($a) <=> int($b) } keys %{ $self->{result} };
    return \@sorted;
}

=head2 $p->result

    alias to results

=cut

{
    no warnings;
    *result = \&results;
}

1;

__END__
    
