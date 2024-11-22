use warnings;
use 5.020;
use experimental qw( postderef signatures );

package Test2::Tools::ComboObject 0.01 {

  # ABSTRACT: Combine checks and diagnostics into a single test as an object


  use Exporter 'import';
  use Test2::API ();
  use Class::Tiny qw/ context /, {
    name => "combo object test",
    status => 1,
    _log => sub { [] },
    _count => 0,
    _done => 0,
    _extra => 0,
  };

  sub BUILD ($self, $) {
    my %args = ( level => 3 + $self->_extra );
    $self->context( Test2::API::context( %args ) );
  }

  sub DEMOLISH ($self, $) {
    $self->finish;
  }


  our @EXPORT = qw( combo );

  sub combo :prototype(;$) {
    my $name = shift // 'combo object test';
    return __PACKAGE__->new( name => $name, _extra => 1 );
  }


  sub finish ($self) {
    return $self->status if $self->_done;

    $self->_done(1);

    unless ( $self->_count ) {
      push $self->_log->@*, "Test::ComboTest object had no checks";
      $self->status(0);
    }

    if ( $self->status ) {
      if ( $self->_log->@* ) {
        $self->context->pass( $self->name );
        $self->context->note( $_ ) for $self->_log->@*;
        $self->context->release;
      } else {
        $self->context->pass_and_release( $self->name );
      }
    } else {
      $self->context->fail_and_release( $self->name, $self->_log->@* );
    }

    return $self->status;
  }


  sub log ( $self, @messages ) {
    push $self->_log->@*, @messages;
    return $self;
  }


  sub pass ( $self, @messages ) {
    $self->log(@messages);
    $self->_count( $self->_count + 1 );
    return $self;
  }


  sub fail ( $self, @messages ) {
    $self->status(0);
    $self->log(@messages);
    $self->_count( $self->_count + 1 );
    return $self;
  }


  sub ok ( $self, $status, @messages ) {
    $self->status(0) unless $status;
    $self->log(@messages);
    $self->_count( $self->_count + 1 );
    return $self;
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::ComboObject - Combine checks and diagnostics into a single test as an object

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Tools::ComboObject;
 use feature qw( signatures );
 
 sub my_test_tool ($test_name //='my test tool', @numbers) {
   my $combo = combo $test_name;
   foreach my $number (@numbers) {
     if($number % 2) {
       $combo->fail("$number is not even");
     } else {
       $combo->pass;
     }
   }
   return $combo->finish;
 }
 
 my_test_tool undef, 4, 6, 8, 9, 100, 200, 300, 9999, 2859452842;
 my_test_tool 'try again', 2, 4, 6, 8;
 
 done_testing;

output:

 prove -lvm examples/synopsis.t
 examples/synopsis.t ..
 # Seeded srand with seed '20241121' from local date.
 not ok 1 - my test tool
 
 # Failed test 'my test tool'
 # at examples/synopsis.t line 17.
 # 9 is not even
 # 9999 is not even
 ok 2 - try again
 1..2
 Dubious, test returned 1 (wstat 256, 0x100)
 Failed 1/2 subtests
 
 Test Summary Report
 -------------------
 examples/synopsis.t (Wstat: 256 (exited 1) Tests: 2 Failed: 1)
   Failed test:  1
   Non-zero exit status: 1
 Files=1, Tests=2,  0 wallclock secs ( 0.00 usr  0.00 sys +  0.03 cusr  0.00 csys =  0.03 CPU)
 Result: FAIL

=head1 DESCRIPTION

Combine multiple checks into a single test.  Sometimes you want a test tool that has multiple
possible failure points, but you want to hide that complexity from the user of your test tool.
This class helps provide a OO interface to make this easy without having to track status and
diagnostics in separate variables.

If any one check fails the test will fail.  If all checks pass then the test will pass.
You can log diagnostics which will be directed to either C<diag> or C<note> depending on
if the test fails or passes (respectively) overall.

=head1 ATTRIBUTES

=head2 context

 my $ctx = $combo->context;

The L<Test2::API::Context> context.  When created, this context takes into account the
extra stack frames so that any failure diagnostics will point back to the call point of
your tool.

=head2 name

 my $name = $combo->name;

The string name of the test.  The default C<combo object test> will be used if not provided.

=head2 status

The boolean status of the test.  Zero C<0> for failure and One C<1> for pass.  You should
generally not set this yourself directly, and instead use L</pass>, L</fail> or L</ok>
below.

=head1 FUNCTIONS

=head2 combo

 my $combo = combo $test_name;
 my $combo = combo;

Exported by default.  Takes an optional test name.  Will use
C<combo object test> if not provided.

=head1 METHODS

Note that methods that do not specify a return type will return the combo object,
so such methods may be chained.

=head2 finish

 my $status = $combo->finish;

Complete the combo test by generating the appropriate L<Test2> events and release its
context.  It also returns the pass/fail status, to make it a good choice to return from
your tool, since it is a common practice for tools to return true/false when the
pass/fail (respectively).

 sub test_tool {
   my $combo = combo;
   ...
   return $combo->finish;
 }

If the the combo object is not explicitly finished when the object is destroyed then
it will be finished for you in its destructor.

=head2 log

 $combo->log(@messages);

Include the given C<@messages> as either a C<diag> or C<note> if the test
overall fails or passes (respectively).

=head2 pass

 $self->pass;
 $self->pass(@messages);

Marks a passing check.  C<@messages> if provided will be added to the log.

=head2 fail

 $self->fail;
 $self->fail(@messages);

Marks a failing check.  C<@messages> if provided will be added to the log.

=head2 ok

  $self->ok($status);
  $self->ok($status, @messages);

Marks a passing or failing check depending on if the C<$status> is true or false (respectively).
C<@messages> if provided will be added to the log.

=head1 CAVEATS

This class creates a L<Test2::API::Context>, and does release it when the object is
either finished (via L</finish>) or when it falls out of scope.  Because of this any
caveats about storing and releasing contexts also applies to objects of this class.

=cut

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
