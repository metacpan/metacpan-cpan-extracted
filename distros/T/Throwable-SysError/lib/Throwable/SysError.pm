package Throwable::SysError;

use namespace::autoclean;
use Errno qw();
use Moo;
use MooX::Types::MooseLike::Base qw( Int Str );
use Scalar::Util qw();

extends qw( Throwable::Error );

our $VERSION = '0.00';


has op     => ( is => 'ro', isa => Str, required => 1 );
has errno  => ( is => 'ro', isa => Int, required => 1 );
has errstr => ( is => 'ro', isa => Str, required => 1 );


around BUILDARGS => sub {
  my ( $orig, $class ) = ( shift, shift );

  my $args   = $class->$orig( @_ );
  my $_errno = defined $args->{_errno}
    ? do { local $! = $args->{_errno}; $! }
    : $!
  ;

  @$args{qw( errno errstr )}
    = ( 0 + $_errno, ''. $_errno );

  $args
};

around throw => sub {
  my ( $orig, $invocant ) = ( shift, shift );

  # save $! as soon as possible
  my $_errno = $!;

  # pass-through on re-throw
  return $invocant->$orig( @_ )
    if Scalar::Util::blessed( $invocant );

  # fix up @_ to include _errno
  if( @_ == 1 ) {
    # inject _errno if we have a single hash argument.
    # otherwise we don't know what to do.
    $_[0]->{_errno} = $_errno
      if ref $_[0] eq 'HASH' && ! defined $_[0]->{_errno};
  }
  else {
    # inject _errno at the front of the list to allow
    # overriding when in new()
    unshift @_, _errno => $_errno;
  }

  $invocant->$orig( @_ )
};

sub is {
  my ( $self, $errname ) = @_;

  local $! = $self->errno;
  $!{$errname}
}


1
__END__

=pod

=head1 NAME

Throwable::SysError - a sub-class of Throwable::Error for system error objects

=head1 SYNOPSIS

  package MyApp::SysError;

  use Moo;

  extends qw( Throwable::SysError );

  has path => ( is => 'ro', required => 1 );

  ...

  open my $fh, '<', $file
    or MyApp::SysError->throw({
         message => 'open() failed',
         op      => 'open',
         path    => $file
       });

  ...

  try {
    mkdir $dir
      or MyApp::SysError->throw(
        message => 'mkdir() failed', op => 'mkdir', path => $dir );

    ...
  }
  catch {
    # ignore errors if making a directory that already exists
    return
      if $_->op eq 'mkdir' && $_->is( 'EEXIST' );

    $logger->log->error( 'unrecoverable system error: ',
      $_->op, ': ', $op->path, ': ', $op->errstr );

    $_->throw;
  };

=head1 DESCRIPTION

Throwable::SysError is a simple class for exceptions that will be
thrown to signal errors related to system functions like C<open()>
or anything that sets C<$!> when an operation fails.  It is built
on top of C<Throwable::Error> as a sub-class which you can use
directly or by sub-classing it yourself for your specific needs.

=head1 ATTRIBUTES

=head2 op

This attribute is required and should contain a string describing the
operation that caused the error.

=head2 errno

This attribute is not meant to be set directly and if not provided is
derived from the numeric value of C<$!> at the time the exception is thrown.
If you need to provide a value for this attribute manually, you can
use C<"_errno"> in calls to C<new()>/C<throw()>.

=head2 errstr

This attribute is not meant to be set directly and if not provided is
derived from the string value of C<$!> at the time the exception is thrown.
If you need to provide a value for this attribute manually, you can
use C<"_errno"> in calls to C<new()>/C<throw()>.

=head1 METHODS

=head2 is( $constant )

Returns true if the error constant named in C<$constant> represents the
current errno.  This allows you to test for specific error
conditions in your exception handlers without needing to import
constants from C<Errno>.

=head1 SEE ALSO

=over 4

=item L<Throwable::Error>

This module is a sub-class of C<Throwable::Error>.

=back

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, jason hord

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
