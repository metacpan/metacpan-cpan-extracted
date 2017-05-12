package VUser::ExtLib::SQL;
use warnings;
use strict;

# Copyright 2006 Randy Smith <perlstalker@vuser.org>
# $Id: SQL.pm,v 1.11 2007/04/10 22:38:39 perlstalker Exp $

our $VERSION = "0.1.1";

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = (); # Export nothing by default
our @EXPORT_OK = qw(execute);
our %EXPORT_TAGS = ();

use VUser::Log qw(:levels);
use DBI;

=head1 NAME

VUser::ExtLib::SQL - Common functions for handling SQL with in vuser

=head1 DESCRIPTION

VUser::ExtLib::SQL contains common functions and features for working
with databases. It has both a functional and an object-oriented interface.
The OO interface offers more features such as macros.

=head1 Class Methods

=head2 new

 VUser::ExtLib::SQL->new($cfg, $paramters);
 
=over 4

=item $cfg

The config hash

=item $paramters

 { user => 'foo',
   password => 'bar',
   dsn => 'dbi:mysql:database=baz',
   macros => { 'u' => 'username',
               'p' => 'password'
              }
 }

=back

=cut

sub new {
    my $class = shift;
    my $cfg = shift;
    my $params = shift;
    
    my $self = {dsn => undef,
                user => undef,
                password => undef,
                macros => {},
                _log => undef                
                };
    bless $self, $class; 

    if (ref $class && UNIVERSAL::isa($class, 'VUser::ExtLib::SQL')) {
        $self->dsn($class->dsn());
        $self->user($class->user());
        $self->password($class->password());
        $self->macros($class->macros());
        $self->{_log} = $class->Log();
    } else {
        if (defined $main::log
            and UNIVERSAL::isa($main::log, 'VUser::Log'))
        {
            $self->{_log} = $main::log;
        } else {
            $self->{_log} = VUser::Log->new($cfg, 'VUser::ExtLib::SQL');
        }
    }
    
    $self->dsn($params->{dsn});
    $self->user($params->{user});
    $self->password($params->{password});
    $self->macros($params->{macros});    
    return $self;
}

=pod

=head2 execute

Execute a SQL query.

There are a few predefined macros that you can use in your
SQL. The values will be quoted and escaped before being inserted into
the SQL. You can specify your own custom macros if you use the OO
interface for VUser::ExtLib::SQL. See L<new|the new() method> above.

=over 4

=item %%

Unquoted %

=item %-option

This will be replaced by the value of --option passed in when vuser is called.

=item %$option

This will be replaced by the value of $args{option} passed to execute().
option may only match I<\w> or I<->. For example:

 my $db = VUser::ExtUtil::SQL->new(...);
 my $sth = $db->execute($opts,
                        "select * from foo where bar = %$bar",
                        {bar => 'baz'} );
 # Possibly get results with $sth->fetchrow_*
 $sth->finish;

execute() returns the statement handle after $sth->execute() has been run.
Remember to run $sth->finish() on the returned statement handle when you're
done with it.

=item %\option

B<WARNING:> This is a very dangerous option and must be handled with care.
If you don't need to use it, don't use it.

Replace the option with the unescaped value of the option. This does not
use placeholders like the other options above. All quoting, escaping, etc.
is left to the caller to handle before passing the value to execute().

=back

=cut

sub execute {
    my $self;
    my $dbh;

    my $macros = '';
    my %macros = ();

    if (UNIVERSAL::isa($_[0], 'VUser::ExtLib::SQL')) {
        $self = shift;
        $dbh = $self->db_connect();
        $macros = join('|', keys %{$self->macros()});
        %macros = %{ $self->macros() };
    } elsif (UNIVERSAL::isa($_[0], '')) {
        $dbh = shift;
    }
    
    my $opts = shift;
    my $sql  = shift;
    my $argsref = shift;
    my $overridesref = shift;

    my %args = (); 
    if (defined $argsref and ref $argsref eq 'HASH') {
	%args = %{ $argsref };
    }

    my %overrides = ();
    if (defined $overridesref and ref $overridesref eq 'HASH') {
	%overrides = %{ $overridesref };
    }

    if ( not defined $sql or $sql =~ /^\s*$/ ) {
        Log()->log( LOG_ERROR, "No SQL command given." );
        die "No SQL command given\n";
    }

    Log()->log( LOG_DEBUG, "Original SQL: $sql" );

    # This will match the macros we are using
    my $re = qr/(?:%($macros|%|-[\w-]+|\$[\w-]+))/;

    Log()->log( LOG_DEBUG, "Macros: $macros; RE: $re");

    # Pull the options out of the query
    my @options = $sql =~ /$re/g;

    # replace the options with ? placeholders
    $sql =~ s/$re/?/g;

    # Now replace the manually escaped options. %\option-name
    my @man_opts = $sql =~ /(?:%\\([\w-]+))/;
    foreach my $opt (@man_opts) {
	   if (defined $overrides{$opt}) {
	       $sql =~ s/%\\$opt/$overrides{$opt}/e;
	   } elsif (defined $args{$opt}) {
	       $sql =~ s/%\\$opt/$args{$opt}/e;
	   } elsif (defined $macros{$opt}) {
	       $sql =~ s/%\\$opt/$opts->{$macros{$opt}}/e;
	   }
    }

    Log()->log( LOG_DEBUG, "Options (" .scalar @options .'): ' . join( ', ', @options ) );
    Log()->log( LOG_DEBUG, "New SQL: $sql" );

    my @passed_options = ();
    foreach my $opt (@options) {
        if ( $opt eq '%') {
            push @passed_options, '%';
        } elsif ( $opt =~ /^-([\w-]+)/ ) {
            push @passed_options, $opts->{$1};
        } elsif ( $opt =~ /^\$([\w-]+)/ ) {
            push @passed_options, $args{$1};
        } elsif ( defined $macros{$opt} ) {
	    if (exists $args{$opt}) {
		push @passed_options, $overrides{$opt};
	    } else {
		push @passed_options, $opts->{$macros{$opt}};
	    }
        }
    }

    Log()->log( LOG_DEBUG, "Passed Options (" . scalar @passed_options .'): '
        . join( ', ', map { defined $_? $_ : 'undef' } @passed_options ) );

    my $sth = $dbh->prepare($sql)
      or die "Cannot prepare SQL: ", $dbh->errstr, "\n";
    my $rc;
    if (@passed_options) {
        $rc = $sth->execute( @passed_options )
    } else {
        $rc = $sth->execute( )
    }
    die ("Cannot execute SQL: ", $sth->errstr, "\n") unless $rc;

    return $sth;
}

=pod

=head2 db_connect

Connect to the database.

Returns a DBI database handle.

=cut

sub db_connect {
    my $self;
    
    my $dsn;
    my $user;
    my $password;
    
    my $scope;
    
    if (ref $_[0] and UNIVERSAL::isa($_[0], 'VUser::ExtLib::SQL')) {
        $self = shift;
        $dsn = $self->dsn();
        $user = $self->user();
        $password = $self->password();
    } else {
        ($dsn, $user, $password) = @_;
    }
    
    $scope = shift || 'VUser::ExtLib::SQL';

    die "No DSN specified\n" unless $dsn;

    Log()->log(LOG_DEBUG, "Connecting to $dsn as $user");
    
    my $dbh =
      DBI->connect_cached( $dsn, $user, $password,
                           { private_vuser_cachekey => $scope } )
      or die $DBI::errstr;
    return $dbh;
}

=pod

=head1 Instance Methods

=head2 dsn

=head2 user

=head2 password

=cut

sub dsn { $_[0]->{dsn} = $_[1] if defined $_[1]; return $_[0]->{dsn}; }
sub user { $_[0]->{user} = $_[1] if defined $_[1]; return $_[0]->{user}; }
sub password { $_[0]->{password} = $_[1] if defined $_[1]; return $_[0]->{password}; }
sub macros { $_[0]->{macros} = $_[1] if defined $_[1]; return $_[0]->{macros}; }

sub Log {
    my $self = shift;
    if (defined $self and UNIVERSAL::isa($self, 'VUser::ExtLib::SQL')) {
        return $self->{_log};
    } else {
        if (defined ($main::log) and UNIVERSAL::isa($main::log, 'VUser::Log')) {
            return $main::log;
        } elsif (defined $VUser::ExtLog::log
                 and UNIVERSAL::isa($main::log, 'VUser::Log')
                 ) {
            return $VUser::ExtLog::log;
        } else {
            # I need to create VUser::ExtLib::log but don't have a $cfg. Hmmm.
            die "I can't find a VUser::Log\n";
        }
    }
}

sub begin {
    my $self = shift;
    if (UNIVERSAL::isa($self, "VUser::ExtLib::SQL")) {
        Log()->log(LOG_DEBUG, "Beginning transaction");
        $self->db_connect()->begin_work();
    } else {
        Log()->log(LOG_DEBUG, "Cannot begin transaction in function mode");
    }
}

sub commit {
    my $self = shift;
    if (UNIVERSAL::isa($self, "VUser::ExtLib::SQL")) {
        Log()->log(LOG_DEBUG, "Committing transaction");
        $self->db_connect()->commit();
    } else {
        Log()->log(LOG_DEBUG, "Cannot commit transaction in function mode");
    }
}

sub rollback {
    my $self = shift;
    if (UNIVERSAL::isa($self, "VUser::ExtLib::SQL")) {
        Log()->log(LOG_DEBUG, "Rolling back transaction");
        $self->db_connect()->rollback();
    } else {
        Log()->log(LOG_DEBUG, "Cannot rollback transaction in function mode");
    }
}

# Clean up after ourself
sub DESTROY {
    my $self = shift;
    #my $cached_connections = $self->db_connect();
    #%$cached_connections = () if $cached_connections;
}

1;

__END__

=head1 AUTHORS

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE

 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
