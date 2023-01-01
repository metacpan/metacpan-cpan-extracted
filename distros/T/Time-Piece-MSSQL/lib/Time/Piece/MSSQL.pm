use strict;
use warnings;
package Time::Piece::MSSQL 0.023;
use Time::Piece 1.17;
# ABSTRACT: MSSQL-specific methods for Time::Piece

# stolen from timepiece-mysql 
sub import {
  splice @_, 0, 1, 'Time::Piece';
  goto &Time::Piece::import
}

#pod =head1 SYNOPSIS
#pod
#pod  use Time::Piece::MSSQL;
#pod
#pod  my $time = localtime;
#pod
#pod  print $time->mssql_datetime;
#pod  print $time->mssql_smalldatetime;
#pod
#pod  my $time = Time::Piece->from_mssql_datetime( $mssql_datetime );
#pod  my $time = Time::Piece->from_mssql_smalldatetime( $mssql_smalldatetime );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module adds functionality to L<Time::Piece>, providing methods useful for
#pod using the object in conjunction with a Microsoft SQL database connection.  It
#pod will produce and parse MSSQL's default-format datetime values.
#pod
#pod =method mssql_datetime
#pod
#pod =method mssql_smalldatetime
#pod
#pod These methods return the Time::Piece object, formatted in the default notation
#pod for the correct MSSQL datatype.
#pod
#pod =cut

sub mssql_datetime {
	my $self = shift;
	$self->strftime('%Y-%m-%d %H:%M:%S.000');
}

sub mssql_smalldatetime {
	my $self = shift;
	$self->strftime('%Y-%m-%d %H:%M:%S');
}

#pod =method from_mssql_datetime
#pod
#pod   my $time = Time::Piece->from_mssql_datetime($timestring);
#pod
#pod =method from_mssql_smalldatetime
#pod
#pod   my $time = Time::Piece->from_mssql_smalldatetime($timestring);
#pod
#pod These methods construct new Time::Piece objects from the given strings, which
#pod must be in the default MSSQL format for the correct datatype.  If the string is
#pod empty, undefined, or unparseable, C<undef> is returned.
#pod
#pod =cut

sub from_mssql_datetime {
	my ($class, $timestring) = @_;
	return unless $timestring and ($timestring =~ s/\.\d{3}$//);
	my $time = eval { $class->strptime($timestring, '%Y-%m-%d %H:%M:%S') };
}

sub from_mssql_smalldatetime {
	my ($class, $timestring) = @_;
	return unless $timestring;
	my $time = eval { $class->strptime($timestring, '%Y-%m-%d %H:%M:%S') };
}

BEGIN {
  for (qw(
    mssql_datetime mssql_smalldatetime
    from_mssql_datetime from_mssql_smalldatetime
  )) {
    no strict 'refs'; ## no critic ProhibitNoStrict
    *{"Time::Piece::$_"} = __PACKAGE__->can($_);
  }
}

#pod =head1 FINAL THOUGHTS
#pod
#pod This module saves less time than L<Time::Piece::MySQL>, because there are fewer
#pod strange quirks to account for, but it becomes useful when tied to autoinflation
#pod of datatypes in Class::DBI::MSSQL.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Piece::MSSQL - MSSQL-specific methods for Time::Piece

=head1 VERSION

version 0.023

=head1 SYNOPSIS

 use Time::Piece::MSSQL;

 my $time = localtime;

 print $time->mssql_datetime;
 print $time->mssql_smalldatetime;

 my $time = Time::Piece->from_mssql_datetime( $mssql_datetime );
 my $time = Time::Piece->from_mssql_smalldatetime( $mssql_smalldatetime );

=head1 DESCRIPTION

This module adds functionality to L<Time::Piece>, providing methods useful for
using the object in conjunction with a Microsoft SQL database connection.  It
will produce and parse MSSQL's default-format datetime values.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 mssql_datetime

=head2 mssql_smalldatetime

These methods return the Time::Piece object, formatted in the default notation
for the correct MSSQL datatype.

=head2 from_mssql_datetime

  my $time = Time::Piece->from_mssql_datetime($timestring);

=head2 from_mssql_smalldatetime

  my $time = Time::Piece->from_mssql_smalldatetime($timestring);

These methods construct new Time::Piece objects from the given strings, which
must be in the default MSSQL format for the correct datatype.  If the string is
empty, undefined, or unparseable, C<undef> is returned.

=head1 FINAL THOUGHTS

This module saves less time than L<Time::Piece::MySQL>, because there are fewer
strange quirks to account for, but it becomes useful when tied to autoinflation
of datatypes in Class::DBI::MSSQL.

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

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
