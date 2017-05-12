## $Id:$ ##

package Test::Out;

use strict;
use warnings;

use Carp;
use Carp::Assert;
use File::Temp;
use File::Basename;
use Test::Builder;

my $tstobj = Test::Builder->new;

our $VERSION = '0.21';

=head1 NAME

    Test::Out - Test output from FILEHANDLE

=head1 SYNOPSIS

    use Test::Out;
    my $out = Test::Out->new( output => *STDOUT, tests => 4 );

    # Or ...

    my $out = Test::Out->new(tests => 4);
    $out->redirect( output => *STDOUT );

    ## This will go to a place that your harness can see
    $out->diag("Testing is* functions");

    ## But this will not be displayed but captured for test methods
    $some->method_that_prints("This is a test\n");
    $out->is_output("This is a test\n", "test 1");
    $out->isnt_output("Han shot first", "test 2");

    $out->diag("Testing regex functions");
    CORE::print "A random number: @{[int rand 100]}\n";
    $out->like_output(qr/random number: \d+/, "test 3");
    $out->unlike_output(qr/i like pickles$/, "test 4");

    $out->restore;

    ## This will be printed to STDOUT
    print "Done.\n";

=head1 DESCRIPTION

Test out is another Test::Builder application that implements a few of the well known test facilities
except the result of output to an IO::Handle is used.  This could be used to capture output being
printed to a file, but it's ideal for output being sent to STDOUT or STDERR.

See the SYNOPSIS for an example use.

=begin RCS

    $Id$

=end RCS

=head1 AUTHOR

Lane Davis <cpan@upt.org>

=head1 FUNCTIONS

=head2 METHODS

=over

=item B<$out-E<gt>new(%options)>

The F<Test::Out> package constructor has several arguments, some required some optional

=over

=item B<REQUIRED OPTIONS>

The following options must be present in the hash passed to the constructor:

=over

=item B<THE NUMBER OF PLANNED TESTS>

=over

=item tests =E<gt> $Tests

The number of tests are simply passed to Test::Builder

=back

=back

=item B<NON-REQUIRED OPTIONS>

=over

=item B<THE OUTPUT YOU WISH TO TEST>

Actually the C<output> key is required, but you have the option of passing the key into the constructor or to the B<redirect>
method.  This is useful if you have several segments of tests wrapped with B<redirect> and B<restore>.

=over

=item output =E<gt> *FH

The output argument is required and may contain either a FILEHANDLE typeglob, or

=item output =E<gt> \*FHREF

The C<output> key may also point to a typeglob reference

=back

=back

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my ($object);

    ##
    ## Ensure key/value pairs are passed
    assert(!(@_ & 1));

    $object = { @_ };
    croak("Missing planned tests key: 'tests'") unless exists $object->{tests};

    ##
    ## Remove it from the object so it can't be reused
    $tstobj->plan(tests => delete $object->{tests});

    my $self = bless($object, $class);
    $self->redirect(%$object) if exists $object->{output};

    return $self;
}

=item B<$out-E<gt>redirect>

=item B<$out-E<gt>redirect(output =E<gt> *FH)>

=item B<$out-E<gt>redirect(output =E<gt> \*FH)>

This method will be automatically invoked by the constructor if the output key is passed to new.

=cut

sub redirect {
    my $self = shift;
    my $obj  = { @_ };

    eval {
        no strict 'refs';
        die unless exists $obj->{output} && *{ $obj->{output} }{IO}->isa("IO::Handle");
    };
    croak("Not a valid filehandle or output key missing") if $@;

    $self->_init_redirect($obj);

    ( my $basename = basename $0 ) =~ s/\.[^.]*$//;

    $self->{_temp_file} = File::Temp->new(
        DIR         =>      "/tmp",
        TEMPLATE    =>      join(".", "", $basename, 'X' x 8),
        SUFFIX      =>      '.' . int($$ ^ time & ( 2 ** 16 )),
        UNLINK      =>      0,
    ) or croak("File::Temp: $!");

    ##
    ## Save the prior autoflush value and turn it on
    $self->{_autoflush} = $self->{_io_handle}->autoflush(1);

    ##
    ## dup(2) the IO handle to a saved descriptor then redirect it to the temp file
    open($self->{_saved_handle}, "+>&" . fileno($self->{_io_handle}));
    open($self->{_io_handle}, "+>&" . fileno($self->{_temp_file}));

    ##
    ## This is where diag() messages will go.  Note that I haven't implemented any
    ## TODO handling, but I put the filehandle here in case it's added later.
    $tstobj->failure_output($self->{_saved_handle});
    $tstobj->todo_output($self->{_saved_handle});
    return $self;
}

sub _init_redirect {
    my $self = shift;
    my $obj  = shift;

    ##
    ## Internalize the output descriptor and ensure integrity of calling sequence
    $self->{_io_handle} = delete $obj->{output};
    delete $self->{_saved_handle};
    delete $self->{_autoflush};
    $self->_cleanup_temp(1);
    $self->{_read_offset} = $self->{_buffer_size} = 0;
    return $self;
}

sub restore {
    my $self = shift;

    ##
    ## Ensure proper calling sequence
    croak("Output is not being redirected")
        unless ( exists $self->{_io_handle} and exists $self->{_saved_handle} );

    ##
    ## Restore the saved descriptor and restore the autoflush flag
    open($self->{_io_handle}, ">&" . fileno($self->{_saved_handle}));
    $self->{_io_handle}->autoflush($self->{_autoflush});

    ##
    ## Grab any data remaining in the buffer and clean up
    my $data = $self->drain_out;
    close($self->{_temp_file});
    $self->_cleanup_temp(1);
    delete $self->{_saved_handle};
    delete $self->{_io_handle};
    return $data;
}

sub DESTROY {
    my $self = shift;
    $self->restore if exists $self->{_io_handle} and exists $self->{_saved_handle};
    return $self;
}

sub drain_out {
    my $self = shift;
    my $fh   = $self->{_temp_file};
    local ($/);

    ##
    ## This does something similar to fstat(2)
    my $cursize = ( stat $fh )[ 7 ];
    if ($cursize > $self->{_buffer_size}) {
        $self->{_read_offset} = $self->{_buffer_size};
        $self->{_buffer_size} = $cursize
    }

    ##
    ## Seek to the end of the last read offset (SEEK_SET)
    seek $fh, $self->{_read_offset}, 0;

    ##
    ## Read it all into one scalar
    my $curout  = join '', <$fh>;

    ##
    ## Reposition to the EOF (SEEK_END)
    seek $fh, 0, 2;

    return $curout;
}

sub _cleanup_temp {
    my $self = shift;
    my $unlink = shift;
    return unless exists $self->{_temp_file};
    my $file = $self->{_temp_file}->filename;
    close $self->{_temp_file};
    delete $self->{_temp_file};
    unlink $file if $unlink && -f $file;
    return 1;
}

=pod

=back

=head2 TESTS

=over

=item B<$out-E<gt>is_output(EXPR, NAME)>

=item B<$out-E<gt>was_output(EXPR, NAME)>

Tests the last output buffer against EXPR.  If there isn't a perfect string comparison the test fails.  Pay particular
attention to possible newlines in the last output.  If you're unsure either paste the contents of $\ to your comparitor
or use the C<like> method.

The was_output method is an alias for is_output.

=item B<$out-E<gt>isnt_output(EXPR, NAME)>

=item B<$out-E<gt>wasnt_output(EXPR, NAME)>

This is the inverse of is_output, the negation of the comparing EXPR to the last printed output is performed.

The wasnt_output method is an alias for isnt_output.

=item B<$out-E<gt>like_output(qr/STRING/, NAME)>

This performs a test with the last output and a compiled regular expression as its first argument.

=item B<$out-E<gt>unlike_output(qr/STRING/, NAME)>

This performs a negated test with the last output and a compiled regular expression as its first argument.

=item B<$out-E<gt>cmp_output(OP, EXPR, NAME)>

This performs a comparison allowing you to pass your own perl binary operator as the first arugment (e.g., "==", "eq", etc).

=cut

sub is_output {
    my $self = shift;
    my $comp = shift || return $self->do_fail(q{$obj->is_output("string")});
    my $name = shift || '';
    my $last = $self->drain_out;
    return $tstobj->is_eq($comp, $last, $name);
}

sub was_output {
    goto &is_output;
}

sub isnt_output {
    my $self = shift;
    my $comp = shift || return $self->do_fail(q{$obj->isnt_output("string")});
    my $name = shift || '';
    my $last = $self->drain_out;
    return $tstobj->isnt_eq($comp, $last, $name);
}

sub wasnt_output {
    goto &isnt_output;
}

sub like_output {
    my $self  = shift;
    my $regex = shift || return $self->do_fail(q{$obj->like_output(qr/regex/)});
    my $name  = shift || '';
    my $last = $self->drain_out;
    return $tstobj->like($last, $regex, $name);
}

sub unlike_output {
    my $self  = shift;
    my $regex = shift || return $self->do_fail(q{$obj->unlike_output(qr/regex/)});
    my $name  = shift || '';
    my $last = $self->drain_out;
    return $tstobj->unlike($last, $regex, $name);
}

sub cmp_output {
    my $self  = shift;
    @_ > 1 or return $self->do_fail(q{$obj->cmp_ok(...)});
    my ($type, $that, $name) = @_;
    $name ||= '';
    my $last = $self->drain_out;
    return $tstobj->cmp_ok($last, $type, $that, $name);
}

sub do_fail {
    return $tstobj->ok(0, @_);
}

=item B<$out-E<gt>diag(@messages)>

Prints a diagnostic message

=cut

sub diag {
    my $self = shift;
    return $tstobj->diag(@_);
}

1;

__END__

=back
