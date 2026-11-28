#############################################################################
#
# Web::Session::SQLite
# Apache persistent user sessions in a SQLite database
# Copyright(c) 2013-2017 Xavier Guimard <x.guimard@free.fr>
# Inspired by Apache::Session::Postgres
# (copyright(c) 1998, 1999, 2000 Jeffrey William Baker (jwbaker@acm.org))
# Distribute under the Perl License
#
############################################################################

package Web::Session::SQLite;

use strict;

use Apache::Session;
use Apache::Session::Lock::Null;
use Web::Session::Store::SQLite;
use Web::Session::Generate::SHA256;
use Web::Session::Serialize::JSON;
use Web::Session::DBI;

our $VERSION = '1.0.0';
our @ISA     = qw(Web::Session::DBI Apache::Session);

sub populate {
    my $self = shift;

    $self->{object_store} =
      new Web::Session::Store::SQLite $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Web::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Web::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Web::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Web::Session::Serialize::JSON::unserialize;

    return $self;
}

1;

=pod

=head1 NAME

Web::Session::SQLite - An implementation of Apache::Session

=head1 SYNOPSIS

 use Web::Session::SQLite;

 #if you want Apache::Session to open new DB handles:

 tie %hash, 'Web::Session::SQLite', $id, {
    DataSource => 'dbi:Pg:dbname=sessions',
    UserName   => $db_user,
    Password   => $db_pass,
    Commit     => 1
 };

 #or, if your handles are already opened:

 tie %hash, 'Web::Session::SQLite', $id, {
    Handle => $dbh,
    Commit => 1
 };

L<Web::Session> function are also available

=head1 DESCRIPTION

This module is an implementation of Apache::Session.  It uses the SQLite
backing store and no locking.  See the example, and the documentation for
Web::Session::Store::SQLite for more details.

=head1 USAGE

The special Apache::Session argument for this module is Commit.  You MUST
provide the Commit argument, which instructs this module to either commit
the transaction when it is finished, or to simply do nothing.  This feature
is provided so that this module will not have adverse interactions with your
local transaction policy, nor your local database handle caching policy.  The
argument is mandatory in order to make you think about this problem.

=head2 searchLt() and searchGt()

searchLt() and searchGt() take the same arguments and return the same data as
searchOn(): sessions whose field is lower (or greater) than the given value,
which is excluded. The value must be a number (C<12>, C<-12> or C<12.5>):
otherwise nothing is returned and an error is printed on STDERR. Spaces
around the value are ignored.

Fields listed in C<Index> are compared in SQL as integers
(C<cast(field as integer)>), other fields in Perl after reading all sessions.
Both compare a non-numeric value as 0, or as its numeric prefix, but SQL keeps
only an integer prefix: C<12.7> is 12 and C<1e3> is 1 in SQL, whereas Perl
compares 12.7 and 1000. Store integers in indexed fields to get the same
results.

Sessions without the field are never returned, whereas the Perl fallback of
Lemonldap::NG compares a missing field as 0.

=head1 AUTHOR

This module was written by Xavier Guimard <x.guimard@free.fr> using
Apache::Session::Postgres from Jeffrey William Baker as example.

=head2 Persistent connection

The database connection is kept open between sessions. Set
C<noreuse =E<gt> 1> to open and close one for each session, see
L<Web::Session/"PERSISTENT DATABASE CONNECTIONS">.

=head1 SEE ALSO

L<Web::Session>
