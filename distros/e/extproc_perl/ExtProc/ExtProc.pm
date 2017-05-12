# $Id: ExtProc.pm,v 1.27 2006/08/11 13:27:35 jeff Exp $

package ExtProc;

use 5.6.1;
use strict;
use warnings;
use Symbol qw(gensym);

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
our %EXPORT_TAGS = ( 'all' => [ qw(
    &ep_debug
    &ora_exception
    &is_function
    &is_procedure
    &put_line
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
);
our $VERSION = '2.51';

# destructor functions -- should be per-session
# can't easily put in ExtProc object due to ep_fini, but probably should
my @_destructors;

bootstrap ExtProc $VERSION;

# wraps DBMS_OUTPUT.PUT_LINE so you can print output directly from extproc_perl
sub put_line
{
        my $string = shift;

        if (length($string) > 255) {
                ExtProc::ora_exception('put_line: string longer than 255 chars');
                return;
        }
    my $e = ExtProc->new;
        my $dbh = $e->dbi_connect;
        $dbh->do("BEGIN DBMS_OUTPUT.PUT_LINE('$string'); END;");
}

# implemented in XS for speed
#sub new
#{
#    my $class = shift;
#    my $self = {};
#    bless $self, $class;
#    return $self;
#}

# for print functionality via PUT_LINE
sub fh
{
    my $self = shift;
    return $self->{'fh'} if $self->{'fh'};
    my $fh = gensym;
    bless $fh, 'ExtProc';
    tie *$fh, $fh;
    $self->{'fh'} = $fh;
    return $self->{'fh'};
}

# for print functionality via PUT_LINE
sub TIEHANDLE
{
    return $_[0] if ref($_[0]);
    die "expecting reference in TIEHANDLE";
}

# for print functionality via PUT_LINE
sub PRINT
{
    my ($self, $buf) = @_;
    put_line($buf);
}

# wrapper around DBI->connect so we don't call OCIExtProcGetEnv twice
# expects DBI to be loaded already
sub dbi_connect
{
    my ($self, $userattr) = @_;
    my $dbh;
    my $attr = (ref($userattr) eq 'HASH') ? $userattr : {};

    if (_is_connected()) {
        $dbh = DBI->connect('dbi:Oracle:extproc', '', '',
            { 'ora_context' => context(),
              'ora_envhp' => _envhp(),
              'ora_svchp' => _svchp(),
              'ora_errhp' => _errhp(),
              %{$attr}
            }
        );
    }
    else {
        $dbh = DBI->connect('dbi:Oracle:extproc', '', '',
            { 'ora_context' => context(), %{$attr} } );

        # need to set this even if we fail, cuz GetEnv should succeed
        # even if the connect fails -- in that case you have other
        # problems
        _connected_on();
    }

    return $dbh;
}

sub register_destructor
{
    my ($self, $funcref) = @_;

    die "bad coderef passed to register_destructor" unless
        (ref($funcref) eq 'CODE');

    unshift(@_destructors, $funcref);
}

# called from ep_fini before interpreter is shut down
sub destroy
{
    my $self = shift;
    foreach my $code (@_destructors) {
        &$code();
    }
}

1;
__END__

=head1 NAME

ExtProc - Perl interface to the Oracle Perl External Procedure Library

=head1 SYNOPSIS

  use ExtProc;

  my $e = ExtProc->new;
  my $dbh = $e->dbi_connect;
  $e->ora_exception("error");

=head1 DESCRIPTION

The ExtProc module provides functions for interacting with the calling Oracle
database from extproc_perl scripts.

=head1 FUNCTIONS

=over 4

=item put_line(string)

Uses DBMS_OUTPUT.put_line to return output to the calling program (usually
sqlplus).  You must have enabled output from stored procedures
("set serveroutput" in sqlplus).  You can also use the filehandle interface;
see "fh" for details.

=item ep_debug(message)

If debugging is enabled, write the specified message to the debug log.

=item ora_exception(message)

Throws a user-defined Oracle exception.  Note that the Perl subroutine will
probably complete after this function is called, but no return values should
be accepted by the calling client.

=item is_function()

Returns true if the subroutine is being called as a function.

=item is_procedure()

Returns true if the subroutine is being called as a procedure.

=back

=head1 METHODS

=over 4

=item new()

Returns an ExtProc object that can be used to call the methods below.

=item dbi_connect(\%attr)

Obtain a DBI handle for the calling database, with optional DBI attributes.

 use DBI;
 use ExtProc;

 # get ExtProc object
 my $e = ExtProc->new;

 # connect back to the calling database
 my $dbh = $e->dbi_connect();

 # raise errors
 my $dbh = $e->dbi_connect({RaiseError => 1});

NOTE: External procedures are stateless, so there is no concept of a persistent
connection to the database.  Therefore, you must call dbi_connect once per
transaction.

=item fh()

Returns a filehandle that can be used for returning output to PL/SQL.  You must
have enabled output from stored procedures ("set serveroutput" in sqlplus).

 use ExtProc;

 sub testprint
 {
    my $e = ExtProc->new;
    my $fh = $e->fh;
    print $fh "Hello world!";
 }

 SQL> set serveroutput on
 SQL> exec Perl.proc('testprint')
 Hello world!

=item register_destructor(coderef)

Register a destructor with extproc_perl to be called before the session exits.
coderef should be a reference to a named or anonymous subroutine.  Destructors
are pushed onto a stack, and will be called in LIFO (last in, first out) order.

Destructors MUST exist prior to registration.  Since no context exists between
the database and external procedure during module unload, no attempt will be
made to fetch the code from the database.  In fact, destructors cannot access
the database at all.

 use ExtProc;

 sub bye
 {
    do_something();
 }

 my $e = ExtProc->new;
 $e->register_destructor(\&bye);

=back

=head1 DATE METHODS

Oracle DATE values are passed to Perl as objects of type
ExtProc::DataType::OCIDate.  You can manipulate the date and time values within
by using the methods documented below.

=over 4

=item new()

Creates a new NULL date object.  Use as follows:

use ExtProc;

$date = ExtProc::DataType::OCIDate->new;

=item setdate_sysdate()

Set the DATE to the current system date & time.

=item is_null()

Returns true if the DATE is NULL, false otherwise.

=item set_null()

Set the DATE to an Oracle NULL.  Never "undef" an Oracle DATE type.

=item getdate()

Returns a list of the year, month, and day of the date.

 ($year, $month, $day) = $date->getdate;

=item setdate(year, month, day)

Sets the date in the date object according to the supplied arguments.

=item gettime()

Returns a list of the hour (24-hour format), minute, and second of the date.

 ($hour, $minute, $second) = $date->gettime;

=item settime(hour, minute, second)

Sets the time in the date object according to the supplied arguments.

=item to_char(format)

Perl implementation of the PL/SQL to_char function.  Returns a string
representation of the date object in the format you specify.  See the Oracle
documentation for appropriate date formats.

 print $date->to_char('YYYY/MM/DD HH24:MI:SS');

=head1 AUTHOR

Jeff Horwitz <jeff@smashing.org>

=head1 SEE ALSO

perl(1), perlembed(1), DBI(3), DBD::Oracle(3)

=cut
