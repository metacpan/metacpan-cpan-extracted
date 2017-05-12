package Test::LectroTest::FailureRecorder;
{
  $Test::LectroTest::FailureRecorder::VERSION = '0.5001';
}

use strict;
use warnings;

use Data::Dumper;


=head1 NAME

Test::LectroTest::FailureRecorder - Records/plays failures for regression testing

=head1 VERSION

version 0.5001

=head1 SYNOPSIS

 use Test::LectroTest::Recorder;

 my $recorder = Test::LectroTest::Recorder->new("storage_file.txt");

 my $recorder->record_failure_for_property(
    "property name",
    $input_hashref_from_counterexample
 );

 my $failures = $recorder->get_failures_for_property("property name");
 for my $input_hashref (@$failures) {
    # do something with hashref
 }


=head1 DESCRIPTION

This module provides a simple means of recording property-check
failures so they can be reused as regression tests.  You do not need
to use this module yourself because the higher-level LectroTest
modules will use it for you when needed.  (These docs are mainly
for LectroTest developers.)

The basic idea is to record a failure as a pair of the form

 [ <property_name>, <input hash from counterexample> ]

and Dump these pairs into a text file, each record terminated by blank
line so that the file can be read using paragraph-slurp mode.

The module provides methods to add such pairs to a recorder file and
to retrieve the recorded failures by property name.  It uses a cache
to avoid repetitive reads.


=head1 METHODS

=head2 new(I<storage-file>)

  my $recorder = Test::LectroTest::Recorder->new("/path/to/storage.txt");

Creates a new recorder object and tells it to use I<storage-file>
for the reading and writing of failures.

The recorder will not access the storage file until you attempt to
get or record a failure.  Thus it is OK to specify a storage file that
does not yet exist, provided you record failures to it before you
attempt to get failures from it.

=cut

sub new {
    my $class = shift;
    return bless { file => $_[0] }, $class;
}

# get failure store from cache or file

sub _store {
    my ($self) = @_;
    my $file = $self->{file};
    $self->{cache} ||= do {
        open my $fh, $file or die "could not open $file: $!";
        local $/ = "";  # paragraph slurp mode
        my @recs = map eval($_), <$fh>;
        close $fh;
        \@recs;
    };
}

=pod

=head2 get_failures_for_property(I<propname>)

  my $failures = $recorder->get_failures_for_property("property name");
  for my $input_hashref (@$failures) {
     # do something with hashref
     while (my ($var, $value) = each %$input_hashref) {
         # ...
     }
  }

Returns a reference to an array that contains the recorded failures
for the property with the name I<propname>.  In the event no
such failures exist, the array will be empty.
Each failure is represented by a hash containing the inputs that
caused the failure.

If the recorder's storage file does not exist or cannot be
opened for reading, this method dies.  Thus, you should call
it from within an C<eval> block.

=cut

sub get_failures_for_property {
    my ($self, $property_name) = @_;
    [ map $_->[1], grep { $_->[0] eq $property_name } @{$self->_store} ];
}

=pod

=head2 record_failure_for_property(I<propname>, I<input-hashref>)

  my $recorder->record_failure_for_property(
     "property name",
     $input_hashref_from_counterexample
  );

Adds a failure record for the property named I<propname>.  The
record captures the counterexample represented by the I<input-hashref>.
The record is immediately appended to the recorder's storage file.

Returns 1 upon success; dies otherwise.

If the recorder's storage file cannot be opened for writing, this
method dies.  Thus, you should call it from within an C<eval> block.

=cut

sub record_failure_for_property {
    my ($self, $property_name, $input_hash) = @_;
    my $file = $self->{file};
    my $rec  = [ $property_name, $input_hash ];
    local $\ = "\n\n";
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Purity   = 1;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Useqq    = 1;
    open my $fh, ">>$file" or die "could not open $file for appending: $!";
    print $fh
        '# ', scalar gmtime, "\n",
        '# ', $self->_platform, "\n",
        Dumper( $rec );
    close $fh;
    push @{$self->{cache}}, $rec if $self->{cache};
    1;
}

sub _platform {
    shift->{platform} ||= do {
        # first try to grab version line from `perl -v`
        eval {
            local $_ = `$^X -v`;
            $_ && /^This is perl,(.*)/im && "perl$1";
        }
        # if that fails, build our own version line
        ||
        sprintf("perl v%vd on %s", $^V,
                # if uname works, get the platform info from it
                eval {
                    require POSIX;
                    if (my @u = POSIX::uname()) {
                        return "@{[grep defined, @u[0,4,2,3]]}";
                    }
                }
                # otherwise, use the less informative Perl OS-name variable
                ||
                $^O
        );
    };
}

1;



=head1 SEE ALSO

L<Test::LectroTest::TestRunner> explains the internal testing apparatus,
which uses the failure recorders to record and play back failures for
regression testing.

=head1 AUTHOR

Tom Moertel (tom@moertel.com)

=head1 COPYRIGHT and LICENSE

Copyright (c) 2004-13 by Thomas G Moertel.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
