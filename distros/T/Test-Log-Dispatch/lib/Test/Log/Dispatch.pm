package Test::Log::Dispatch;
use Data::Dumper;
use List::MoreUtils qw(first_index);
use Log::Dispatch::Array;
use Test::Builder;
use strict;
use warnings;
use base qw(Log::Dispatch);

our $VERSION = '0.03';

my $tb = Test::Builder->new();

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();
    $self->add(
        Log::Dispatch::Array->new(
            name      => 'test',
            min_level => 'debug',
            @_
        )
    );
    return $self;
}

sub clear {
    my ($self) = @_;

    $self->{outputs}{test}{array} = [];
}

sub msgs {
    my ($self) = @_;

    return $self->{outputs}{test}{array};
}

sub contains_ok {
    my ( $self, $regex, $test_name ) = @_;

    $test_name ||= "log contains '$regex'";
    my $found = first_index { $_->{message} =~ /$regex/ } @{ $self->msgs };
    if ( $found != -1 ) {
        splice( @{ $self->msgs }, $found, 1 );
        $tb->ok( 1, $test_name );
    }
    else {
        $tb->ok( 0, $test_name );
        $tb->diag( "could not find message matching $regex; log contains: "
              . _dump_one_line( $self->msgs ) );
    }
}

sub does_not_contain_ok {
    my ( $self, $regex, $test_name ) = @_;

    $test_name ||= "log does not contain '$regex'";
    my $found = first_index { $_->{message} =~ /$regex/ } @{ $self->msgs };
    if ( $found != -1 ) {
        $tb->ok( 0, $test_name );
        $tb->diag( "found message matching $regex: " . $self->msgs->[$found] );
    }
    else {
        $tb->ok( 1, $test_name );
    }
}

sub empty_ok {
    my ( $self, $test_name ) = @_;

    $test_name ||= "log is empty";
    if ( !@{ $self->msgs } ) {
        $tb->ok( 1, $test_name );
    }
    else {
        $tb->ok( 0, $test_name );
        $tb->diag(
            "log is not empty; contains " . _dump_one_line( $self->msgs ) );
        $self->clear();
    }
}

sub contains_only_ok {
    my ( $self, $regex, $test_name ) = @_;

    $test_name ||= "log contains only '$regex'";
    my $count = scalar( @{ $self->msgs } );
    if ( $count == 1 ) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $self->contains_ok( $regex, $test_name );
    }
    else {
        $tb->ok( 0, $test_name );
        $tb->diag(
            "log contains $count messages: " . _dump_one_line( $self->msgs ) );
    }
}

sub _dump_one_line {
    my ($value) = @_;

    return Data::Dumper->new( [$value] )->Indent(0)->Sortkeys(1)->Quotekeys(0)
      ->Terse(1)->Dump();
}

1;

__END__

=pod

=head1 NAME

Test::Log::Dispatch -- Test what you are logging

=head1 SYNOPSIS

    use Test::More;
    use Test::Log::Dispatch;

    my $log = Test::Log::Dispatch->new();

    # ...
    # call something that logs to $log
    # ...

    # now test to make sure you logged the right things

    $log->contains_ok(qr/good log message/, "good message was logged");
    $log->does_not_contain_ok(qr/unexpected log message/, "unexpected message was not logged");
    $log->empty_ok("no more logs");

    # or

    my $msgs = $log->msgs;
    cmp_deeply($msgs, ['msg1', 'msg2', 'msg3']);

=head1 DESCRIPTION

C<Test::Log::Dispatch> is a C<Log::Dispatch> object that keeps track of
everything logged to it in memory, and provides convenient tests against what
has been logged.

=head1 CONSTRUCTOR

The constructor returns a C<Test::Log::Dispatch> object, which inherits from
C<Log::Dispatch> and contains a single C<Log::Dispatch::Array> output at
'debug' level.

The constructor requires no parameters. Any parameters will be forwarded to the
C<Log::Dispatch::Array> constructor. For example, you can pass a I<min_level>
to override the default 'debug'.

=head1 METHODS

The test_name is optional in the *_ok methods; a reasonable default will be
provided.

=over

=item contains_ok ($regex[, $test_name])

Tests that a message in the log buffer matches I<$regex>. On success, the
message is I<removed> from the log buffer (but any other matches are left
untouched).

=item does_not_contain_ok ($regex[, $test_name])

Tests that no message in the log buffer matches I<$regex>.

=item empty_ok ([$test_name])

Tests that there is no log buffer left. On failure, the log buffer is cleared
to limit further cascading failures.

=item contains_only_ok ($regex[, $test_name])

Tests that there is a single message in the log buffer and it matches
I<$regex>. On success, the message is removed.

=item clear ()

Clears the log buffer.

=item msgs ()

Returns the current contents of the log buffer as an array reference, where
each element is a hash containing a I<message> and I<level> key.

=back

=head1 TO DO

=over

=item *

Allow testing of log levels.

=back    

=head1 SEE ALSO

L<Log::Dispatch|Log::Dispatch>, L<Test::Log4perl|Test::Log4perl>

=head1 AUTHOR

Jonathan Swartz

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 Jonathan Swartz, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
