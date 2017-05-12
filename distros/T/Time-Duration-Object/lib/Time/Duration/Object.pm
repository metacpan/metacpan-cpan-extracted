use strict;
use warnings;
package Time::Duration::Object;
{
  $Time::Duration::Object::VERSION = '0.301';
}
# ABSTRACT: Time::Duration, but an object

use Time::Duration 1.02;


sub new {
	my ($class, $duration) = @_;
	return unless defined $duration;
	bless \$duration => $class;
}


sub seconds {
	return ${(shift)};
}


{
  ## no critic (ProhibitNoStrict ProhibitNoWarnings)
  no strict 'refs';
  no warnings 'redefine';
  my @methods = map { $_, "$_\_exact" } qw(duration ago from_now later earlier);
  for (@methods) {
    my $method = \&{"Time::Duration::$_"};
    *{$_} = sub {
      unshift @_, ${(shift)};
      my $result = &$method(@_);
      bless \$result => 'Time::Duration::_Result';
    }
  }
}

package Time::Duration::_Result;
{
  $Time::Duration::_Result::VERSION = '0.301';
}


sub as_string { ${ $_[0] } }


sub concise {
	my $self = shift;
	Time::Duration::concise(${$self});
}

use overload
	'""' => 'as_string',
	fallback => 1;


1;

__END__

=pod

=head1 NAME

Time::Duration::Object - Time::Duration, but an object

=head1 VERSION

version 0.301

=head1 SYNOPSIS

 use Time::Duration::Object;

 my $duration = Time::Duration::Object->new($end_time - $start_time);

=head1 DESCRIPTION

This module provides an object-oriented interface to Time::Duration.  Sure,
it's overkill, and Time::Duration is plenty useful without OO, but this
interface makes it easy to use Time::Duration with Class::DBI, and that's a
good thing.

=head1 METHODS

=head2 C< new($seconds) >

This returns a new Time::Duration::Object for the given number of seconds.

=head2 C< seconds >

This returns the number of seconds in the duration (i.e., the argument you
passed to your call to C<new>.)

=head2 C<duration>

=head2 C<duration_exact>

=head2 C<ago>

=head2 C<ago_exact>

=head2 C<from_now>

=head2 C<from_now_exact>

=head2 C<later>

=head2 C<later_exact>

=head2 C<earlier>

=head2 C<earlier_exact>

These methods all perform the function of the same name from Time::Duration.

=head2 as_string

Time::Duration::Object methods don't return strings, they return an object that
stringifies.  If you can't deal with that and don't want to stringify by
concatenating an empty string, you can call C<as_string> instead.

 my $duration = Time::Duration::Object->new(8000);
 print $duration->ago->as_string; # 2 hours and 13 minutes ago

=head2 concise

This method can be called on the result of the above methods, trimming down the
ouput.  For example:

 my $duration = Time::Duration::Object->new(8000);
 print $duration->ago; # 2 hours and 13 minutes ago
 print $duration->ago->concise # 2hr13m ago

=head1 SEE ALSO

Obviously, this module would be useless without Sean Burke's super-useful
L<Time::Duration>.  There are those, I'm sure, who will think that even I<with>
that module...

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
