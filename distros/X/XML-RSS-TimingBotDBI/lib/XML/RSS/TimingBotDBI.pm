
package XML::RSS::TimingBotDBI;
$VERSION = '2.01';
use      XML::RSS::TimingBot ();
@ISA = ('XML::RSS::TimingBot');
use Carp ();
use strict;

BEGIN { *DEBUG = sub () {0} unless defined &DEBUG }

die "Where's _elem?!!?" unless __PACKAGE__->can('_elem');
#--------------------------------------------------------------------------
# Some accessors:

sub rssagent_dbh              { shift->_elem('rssdbi_dbh'  , @_) }
sub rssagent_table            { shift->_elem('rssdbi_table', @_) }
sub rssagent_url_field        { shift->_elem('rssdbi_url_field', @_) }
sub rssagent_lastmod_field    { shift->_elem('rssdbi_lastmod_field', @_) }
sub rssagent_nextupdate_field { shift->_elem('rssdbi_rssagent_nextupdate_field', @_) }
sub rssagent_etag_field       { shift->_elem('rssdbi_rssagent_etag_field', @_) }

#==========================================================================

sub _rssagent_init {
  my $self = shift;
  $self->SUPER::_rssagent_init(@_);

  # set some sane values
  $self->rssagent_table('rsstibot');
  $self->rssagent_url_field('feedurl');
  $self->rssagent_lastmod_field('lastmod');
  $self->rssagent_nextupdate_field('nextup');
  $self->rssagent_etag_field('etag');
  return;
}

sub _assert_dbh {
  my $dbh = shift->rssagent_dbh;
  return $dbh if $dbh;
  Carp::confess("Set \$feedbot->rssagent_dbh( \$some_dbi_object ) first!");
}

#--------------------------------------------------------------------------


sub datum_from_db {
  my($self, $url, $varname) = @_;

  my $table       = $self->rssagent_table;
  my $furl        = $self->rssagent_url_field;
  my $fieldname = 
     $varname eq 'lastmodified' ? $self->rssagent_lastmod_field
   : $varname eq 'nextupdate'   ? $self->rssagent_nextupdate_field
   : $varname eq 'etag'         ? $self->rssagent_etag_field
   : die "I don't know how to turn \"$varname\" into a fieldname!\nAborting";
  
  my $sql = "select $fieldname from $table where $furl = ?";  #  binary
  DEBUG and print " DB: $sql => $url\n";
  my $dbh = $self->_assert_dbh;
  $dbh->do("lock tables $table read");
  my($val) = $dbh->selectrow_array($sql, undef, $url);
  $dbh->do("unlock tables;");
  return $val;
}

sub commit {
  my $self = shift;
  my $for_db = $self->{'rsstimingbot_for_db'} || return;
  DEBUG > 1 and print " I see ", scalar(keys %$for_db), " url-data in $self to save\n";
  return unless keys %$for_db;

  my $table       = $self->rssagent_table;

  my $dbh = $self->_assert_dbh;
  $self->_make_table_exist($dbh, $table);
  $dbh->do("lock tables $table write");

  $self->_dump_dirty_cache_to_db(
    $for_db, $dbh,
    $self->_make_sql_statements( $dbh, $table )
  );

  $dbh->commit;
  $dbh->do("unlock tables");

  DEBUG > 4 and print "Done committing.\n";
  $self->{'rsstimingbot_for_db'} = {};
  return;
}

#--------------------------------------------------------------------------

sub _dump_dirty_cache_to_db {
  my($self, $hoh, $dbh, $action2statement) = @_;

  my($for_this_url, $value, $retval);
  foreach my $url (sort keys %$hoh) {
    $for_this_url = $hoh->{$url} || next;
    DEBUG > 4 and print " Vars for $url : ", join(' ', sort keys %$for_this_url), "\n";
   Var:
    foreach my $varname (sort keys %$for_this_url) {
      $value = $for_this_url->{$varname};
      $value = '' unless defined $value;
      DEBUG > 5 and print "   Saving $url 's $varname = \"$value\"\n";
      foreach my $action ('update', 'insert') {
        Carp::confess "No handler for $varname?!"
         unless   $action2statement->{$action}{$varname};
        $retval = $action2statement->{$action}{$varname}->execute( $value,$url );
        Carp::confess "Couldn't find a way to $action $varname=$value for $url\nReason: ",
          $dbh->err||"??", "\nAborting"
         unless $retval; # i.e., if it dies
        next Var  unless  $retval == 0;  # i.e., unless it affected no rows
      }
      Carp::confess "Couldn't find a way to update/insert $varname=$value ?!";
    }
  }
  return;
}

#--------------------------------------------------------------------------

sub _make_sql_statements {
  my($self, $dbh, $table) = @_;

  my $furl        = $self->rssagent_url_field;
  my %action2statement;

  my $sql;
  for my $equiv (
   [ 'lastmodified' => $self->rssagent_lastmod_field    ],
   [ 'nextupdate'   => $self->rssagent_nextupdate_field ],
   [ 'etag'         => $self->rssagent_etag_field       ],
  ) {
    for my $way (
     [ 'update' => "update $table set $$equiv[1] = ? where $furl = ?"    ],
     [ 'insert' => "insert into $table ($$equiv[1], $furl) values (?,?)" ],
    ) {
      $sql = $way->[1];
      $action2statement{ $way->[0] }{ $$equiv[0] } = $dbh->prepare( $sql )
       || die "Couldn't prepare an $$way[0] statement for $$equiv[0]: ".($dbh->err||"??");
      DEBUG > 6 and print "# $$equiv[0] updater: $sql\n";
    }
  }
  return \%action2statement;
}

#--------------------------------------------------------------------------

sub _make_table_exist {
  my($self, $dbh, $table) = @_ ;

  return 1 if $self->{'rssagent_dbh_exists'}{$table};

  my $furl        = $self->rssagent_url_field;
  my $flastmod    = $self->rssagent_lastmod_field;
  my $fnextupdate = $self->rssagent_nextupdate_field;
  my $fetag       = $self->rssagent_etag_field;

  foreach my $method (
    '_create_table_if_not_exists', '_just_create_table',
  ) {
    next unless $self->$method(
      $dbh, $table, $furl, $fnextupdate, $flastmod, $fetag
    );
    DEBUG > 7 and print "  DB: $method worked.\n";
    $self->{'rssagent_dbh_exists'}{$table} = 1;
    return;
  }
  Carp::confess "I don't know how to make table $table for $dbh and $self!\nAborting";
}

sub _create_table_if_not_exists {
  my($self, $dbh, $table, $furl, $fnextupdate, $flastmod, $fetag) = @_ ;
  return 1 if $dbh->do(qq<
      create table if not exists
      $table (
       $furl varchar(255) not null primary key,
       $fnextupdate int(11),
       $flastmod varchar(40),
       $fetag varchar(250)
      )
  >);
  return 0;
}

sub _just_create_table { # keep it real simple...
  my($self, $dbh, $table, $furl, $fnextupdate, $flastmod, $fetag) = @_ ;
  return 1 if $dbh->do(qq<
      create table
      $table (
       $furl varchar(255) not null primary key,
       $fnextupdate int(11),
       $flastmod varchar(40),
       $fetag varchar(250)
      )
  >);
  return 0;
}

#--------------------------------------------------------------------------

1;
__END__


=head1 NAME

XML::RSS::TimingBotDBI - XML::RSS::TimingBot-subclass that saves state with DBI

=head1 SYNOPSIS


  use XML::RSS::TimingBotDBI;
  use DBI;
  
  my $dbh = DBI->connect( 'whatever...' )
   || die "Can't connect: $DBI::errstr\nAborting";
  
  my $table = "myrsstable";
  
  $browser = XML::RSS::TimingBotDBI->new;
  $browser->rssagent_dbh($dbh);
  $browser->rssagent_table($table);
  
  my $response = $browser->get(
    'http://interglacial.com/rss/cairo_times.rss'
  );

  ... And process $response just as if it came from
     a plain old LWP::UserAgent object, for example: ...
  
  if($response->code == '200') {
    ...process it...
  }

=head1 DESCRIPTION

This class is for requesting RSS feeds only as often as needed, and
storing in a database the data about how often what feeds can be
requested.

This is a subclass of L<XML::RSS::TimingBot>'s methods that stores
its data in a DBI database object that you specify, instead of
using XML::RSS::TimingBot's behavior of storing in a local
flat-file database.

To use this class, C<use> it, create a new object of this class,
and C<use DBI> and make a new database handle-object; then
use C<rssagent_dbh> to assign that handle to this TimingBotDBI
object; and use C<rssagent_url_field>,
C<rssagent_lastmod_field>, C<rssagent_nextupdate_field>,
and C<rssagent_fetag_field>
to set up the right table/field names; and then, finally, you
can use the TimingBotDBI object just like a L<LWP::UserAgent>
(actually L<LWP::UserAgent::Determined>) object, to request
RSS feeds.


=head1 METHODS

This module inherits all of L<XML::RSS::TimingBot>'s methods,
and adds the following ones.  (These examples are of setting
the value of these attributes; but if you call them without
any arguments, then you get back the current value of that
method.  As in C<<
$tblname = $browser->rssagent_table;
>>.)

=over

=item $browser->rssagent_dbh( $dbh );

This sets what DBI handle is used for reading and writing data
about feeds that this $browser object will/might process.

=item $browser->rssagent_table( 'rssjunk' );

This sets the name of the DBI table that the data will be
stored in.  The default values is "rsstibot".

I<NOTE:> If this table doesn't exist when you call
C<< $browser->get($some_rss_thing) >>, then it will be created
with some relatively sane defaults.

=item $browser->rssagent_url_field( 'furl' );

This sets the name of the key field that will be used for storing
the URL of each feed being processed.  The default value is "feedurl".

=item $browser->rssagent_lastmod_field( 'lastm' );

This sets the name of the field that will be used for storing
the date string gotten from "Last-Modified" header on each feed
being processed.  The default value is "lastmod".

=item $browser->rssagent_nextupdate_field( 'nextu' );

This sets the name of the field that will be used for storing
the integer expressing the soonest time that this feed can be
polled for new data.  The default value is "nextup".

=item $browser->rssagent_etag_field( 'entwad' );

This sets the name of the field that will be used for storing
the string gotten from the "ETag" header on each feed being
processed. The default value is "etag".

=back


=head1 IMPLEMENTATION

This class works by overriding L<XML:RSS::TimingBot>'s "datum_from_db"
and "commit" methods.


=head1 DATABASE FUNK

If the SQL that this class uses isn't right for you, email me about
it!  It works for me, but I'd be interested to hear about cases of
it failing.


=head1 SEE ALSO

L<XML::RSS::TimingBot>, L<XML::RSS::Timing>,
L<LWP::UserAgent::Determined>, L<LWP::UserAgent>, L<LWP>, L<DBI>


=head1 COPYRIGHT AND DISCLAIMER

Copyright 2004, Sean M. Burke C<sburke@cpan.org>, all rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.


=head1 AUTHOR

Sean M. Burke, C<sburke@cpan.org>

=cut

