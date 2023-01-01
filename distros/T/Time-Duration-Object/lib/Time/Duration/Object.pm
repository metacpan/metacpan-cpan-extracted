use strict;
use warnings;
package Time::Duration::Object 0.302;
# ABSTRACT: Time::Duration, but an object

use Time::Duration 1.02;

#pod =head1 SYNOPSIS
#pod
#pod  use Time::Duration::Object;
#pod
#pod  my $duration = Time::Duration::Object->new($end_time - $start_time);
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides an object-oriented interface to Time::Duration.  Sure,
#pod it's overkill, and Time::Duration is plenty useful without OO, but this
#pod interface makes it easy to use Time::Duration with Class::DBI, and that's a
#pod good thing.
#pod
#pod =head1 METHODS
#pod
#pod =head2 C< new($seconds) >
#pod
#pod This returns a new Time::Duration::Object for the given number of seconds.
#pod
#pod =cut

sub new {
	my ($class, $duration) = @_;
	return unless defined $duration;
	bless \$duration => $class;
}

#pod =head2 C< seconds >
#pod
#pod This returns the number of seconds in the duration (i.e., the argument you
#pod passed to your call to C<new>.)
#pod
#pod =cut

sub seconds {
	return ${(shift)};
}

#pod =head2 C<duration>
#pod
#pod =head2 C<duration_exact>
#pod
#pod =head2 C<ago>
#pod
#pod =head2 C<ago_exact>
#pod
#pod =head2 C<from_now>
#pod
#pod =head2 C<from_now_exact>
#pod
#pod =head2 C<later>
#pod
#pod =head2 C<later_exact>
#pod
#pod =head2 C<earlier>
#pod
#pod =head2 C<earlier_exact>
#pod
#pod These methods all perform the function of the same name from Time::Duration.
#pod
#pod =cut

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

package Time::Duration::_Result 0.302;

#pod =head2 as_string
#pod
#pod Time::Duration::Object methods don't return strings, they return an object that
#pod stringifies.  If you can't deal with that and don't want to stringify by
#pod concatenating an empty string, you can call C<as_string> instead.
#pod
#pod  my $duration = Time::Duration::Object->new(8000);
#pod  print $duration->ago->as_string; # 2 hours and 13 minutes ago
#pod
#pod =cut

sub as_string { ${ $_[0] } }

#pod =head2 concise
#pod
#pod This method can be called on the result of the above methods, trimming down the
#pod ouput.  For example:
#pod
#pod  my $duration = Time::Duration::Object->new(8000);
#pod  print $duration->ago; # 2 hours and 13 minutes ago
#pod  print $duration->ago->concise # 2hr13m ago
#pod
#pod =cut

sub concise {
	my $self = shift;
	Time::Duration::concise(${$self});
}

use overload
	'""' => 'as_string',
	fallback => 1;

#pod =head1 SEE ALSO
#pod
#pod Obviously, this module would be useless without Sean Burke's super-useful
#pod L<Time::Duration>.  There are those, I'm sure, who will think that even I<with>
#pod that module...
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Duration::Object - Time::Duration, but an object

=head1 VERSION

version 0.302

=head1 SYNOPSIS

 use Time::Duration::Object;

 my $duration = Time::Duration::Object->new($end_time - $start_time);

=head1 DESCRIPTION

This module provides an object-oriented interface to Time::Duration.  Sure,
it's overkill, and Time::Duration is plenty useful without OO, but this
interface makes it easy to use Time::Duration with Class::DBI, and that's a
good thing.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Ricardo SIGNES Signes

=over 4

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
