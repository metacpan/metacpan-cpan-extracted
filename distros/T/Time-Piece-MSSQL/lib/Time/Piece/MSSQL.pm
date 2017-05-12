use strict;
use warnings;
package Time::Piece::MSSQL;
{
  $Time::Piece::MSSQL::VERSION = '0.022';
}
use Time::Piece 1.17;
# ABSTRACT: MSSQL-specific methods for Time::Piece

# stolen from timepiece-mysql 
sub import {
  splice @_, 0, 1, 'Time::Piece';
  goto &Time::Piece::import
}


sub mssql_datetime {
	my $self = shift;
	$self->strftime('%Y-%m-%d %H:%M:%S.000');
}

sub mssql_smalldatetime {
	my $self = shift;
	$self->strftime('%Y-%m-%d %H:%M:%S');
}


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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Piece::MSSQL - MSSQL-specific methods for Time::Piece

=head1 VERSION

version 0.022

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

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
