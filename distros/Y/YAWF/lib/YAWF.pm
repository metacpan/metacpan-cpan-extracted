package YAWF;

use warnings;
use strict;

use DBI             ();
use File::ShareDir  ();
use FindBin         ();
use HTML::Entities  ();
use Template::Stash ();

use YAWF::Config;
use YAWF::Reply;
use YAWF::Session;

use Class::XSAccessor accessors => {
    request => 'request',
    reply   => 'reply',
    config  => 'config',
};

my %DBH_CACHE;
my %SCHEMA_CACHE;

=head1 NAME

YAWF - Yet another web framework

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

my $SINGLETON;

=head1 SYNOPSIS

YAWF is a framework for building web applications (weblications), it's typically
not used directly but being called by mod_perl to handle a request.

Other frameworks want to be the most flexible and customizable one, but YAWF isn't.
It's optimised for development speed restricting the author in varios matters
(like sessioning, database, templating), but these restrictions make YAWF based
projects more easily maintainable.

=head1 CLASS METHODS

=head2 request

Returns the current YAWF::Request object.

=cut

# Returns the current YAWF object either as a class method or as a object method
sub _unishift {
    my $self = shift;

    # YAWF object was given as argument
    return $self if ref($self) eq __PACKAGE__;

    $SINGLETON ||= __PACKAGE__->new;

    # Something else was given as argument, maybe the classname?
    return $SINGLETON;
}

sub _tt_init {

    # Init some magical Template::Toolkit functions

    # Format a number with decimals
    if ( !defined( $Template::Stash::SCALAR_OPS->{decimal} ) ) {
        $Template::Stash::SCALAR_OPS->{decimal} = sub {
            my $number = shift || 0;
            my $decs = shift || 2;
            my $outnumber = sprintf( '%.0'.$decs.'f', $number );
            $outnumber =~ s/\./\,/;
            return $outnumber;
          }
    }

    # Format a money amount
    if ( !defined( $Template::Stash::SCALAR_OPS->{money} ) ) {
        $Template::Stash::SCALAR_OPS->{money} = sub {
            my $Money = sprintf( '%.02f', shift );
            $Money =~ s/\./\,/;
            return $Money;
          }
    }

    # Fill a text definition with variables
    if ( !defined( $Template::Stash::SCALAR_OPS->{fill} ) ) {
        $Template::Stash::SCALAR_OPS->{fill} = sub {
            my $text = shift;
            return sprintf( $text, @_ );
          }
    }

    # Output text HTML-safe
    if ( !defined( $Template::Stash::SCALAR_OPS->{html} ) ) {
        $Template::Stash::SCALAR_OPS->{html} = sub {
            return HTML::Entities::encode_entities(shift);
          }
    }

    # Return a random list item
    if ( !defined( $Template::Stash::LIST_OPS->{random} ) ) {
        $Template::Stash::LIST_OPS->{random} = sub {
            my $array = shift;
            return $array->[int(rand($#{$array} + 1))];
          }
    }

    # list is a name collision between the YAWF::Object and TT:
    $Template::Stash::LIST_OPS->{as_list} ||= $Template::Stash::LIST_OPS->{list};
    $Template::Stash::SCALAR_OPS->{as_list} ||= $Template::Stash::SCALAR_OPS->{list};

    # Returns a variable in unified date format
    $Template::Stash::SCALAR_OPS->{date} ||= sub {
        my $raw = shift;

        # TODO: Use the preferred date format of the user
        if ( $raw =~
            /^(\d{4})\-(\d{2})\-(\d{2})(?:[T ](\d{2})\:(\d{2})\:(\d{2})(\.\d+Z?)?)$/ )
        {

            # SQL
            return "$3.$2.$1";
        }
        elsif ( $raw =~
            /^(\d{4})\-(\d{2})\-(\d{2})(?: (\d{2})\:(\d{2})\:(\d{2})(\.\d+)?(?:\+(\d+))?)?$/ )
        {
            # TODO: Use timezone

            # SQL
            return "$3.$2.$1";
        }
        elsif ( $raw =~ /^\d+$/ ) {
            my @date = localtime($raw);
            return
                $date[3] . '.'
              . ( $date[4] + 1 ) . '.'
              . ( $date[5] + 1900 );
        }
    };

    # Returns a variable's time part
    $Template::Stash::SCALAR_OPS->{time} ||= sub {
        my $raw = shift;

        # TODO: Use the preferred time format of the user
        if ( $raw =~ /^(\d{4})\-(\d{2})\-(\d{2})[T ](\d{2})\:(\d{2})\:(\d{2})(\.\d+Z?)?$/ )
        {

            # SQL
            return "$4:$5:$6";
        }
        elsif ( $raw =~
            /^(\d{4})\-(\d{2})\-(\d{2}) (\d{2})\:(\d{2})\:(\d{2})(\.\d+)?(?:\+(\d+))?$/ )
        {
            # TODO: Use timezone

            # SQL
            return "$4:$5:$6";
        }
        elsif ( $raw =~ /^\d+$/ ) {
            my @date = localtime($raw);
            return "$date[2]:$date[1]:$date[0]";
        }
    };

    # Returns date and time
    $Template::Stash::SCALAR_OPS->{datetime} ||= sub {
        my $raw = shift;
        return &{ $Template::Stash::SCALAR_OPS->{date} }($raw) . ' '
          . &{ $Template::Stash::SCALAR_OPS->{time} }($raw);
    };

    # Returns the day out of a date
    $Template::Stash::SCALAR_OPS->{date_day} ||= sub {
        return unless     &{$Template::Stash::SCALAR_OPS->{date}}(@_) =~ /^(\d+)\.\d+\.\d+$/;
        return $1 + 0;
};
    # Returns the month out of a date
    $Template::Stash::SCALAR_OPS->{date_month} ||= sub {
        return unless     &{$Template::Stash::SCALAR_OPS->{date}}(@_) =~ /^\d+\.(\d+)\.\d+$/;
        return $1 + 0;
};
    # Returns the year out of a date
    $Template::Stash::SCALAR_OPS->{date_year} ||= sub {
        return unless     &{$Template::Stash::SCALAR_OPS->{date}}(@_) =~ /^\d+\.\d+\.(\d+)$/;
        return $1;
};

    # Search for one item within an array
    if ( !defined( $Template::Stash::LIST_OPS->{match} ) ) {
        $Template::Stash::LIST_OPS->{match} = sub {
            my $value = shift;
            my $search = shift;

            if (ref($value) eq 'ARRAY') {
                return scalar(grep(/^\Q$search\E$/,@{$value})) ? 1 : 0;
            } else {
                return ($search eq $value) ? 1 : 0;
            }
            
          }
    }

}

=head1 METHODS

=head2 new

  my $object = YAWF->new;

The C<new> constructor lets you create a new B<YAWF> object.

=cut

sub new {
    my $class = shift;

    # init Template::Toolkit magic
    &_tt_init;

    $SINGLETON = bless {@_}, $class;

    # Important: Create the SINGLETON before creating the config object!
    $SINGLETON->{config} = YAWF::Config->new(
        YAWF => $SINGLETON,

        # Always insert an "undef" instead of leaving out the item!
        domain => (
            (
                defined( $SINGLETON->request )
                ? $SINGLETON->request->domain
                : undef
            )
              || undef
        ),
    );

    # Preload database definition if it's not loaded:
    eval 'require ' . $SINGLETON->config->database->{class}
      if defined( $SINGLETON->config->database )
          and defined( $SINGLETON->config->database->{class} );

    $SINGLETON->{reply} = YAWF::Reply->new( yawf => $SINGLETON );

    return $SINGLETON;
}

=head2 SINGLETON

  $yawf = YAWF->SINGLETON;

Returns the current YAWF object.

=cut

sub SINGLETON {
    return $SINGLETON;
}

=head2 db

  $db = $yawf->db;

Returns the current DBIx::Class db schema object.

=cut

sub db {
    my $self = _unishift(shift);

    # Return prepared schema object
    return $self->{db} if defined( $self->{db} );

    if ( defined( $self->{config}->{database} ) ) {
        my $db_config     = $self->{config}->{database};
        my $dbh_cache_key = $db_config->{dbi} . chr(0) . $db_config->{username};
        my $schema_cache_key =
          $self->{config}->{domain} . chr(0) . $db_config->{class};

        my $dbh;

        # TODO: Create DB tests and fix DB handle caching
        if (  0 and  defined( $SCHEMA_CACHE{$schema_cache_key} )
            and defined( $SCHEMA_CACHE{$schema_cache_key}->storage->dbh )
            and $SCHEMA_CACHE{$schema_cache_key}
            ->storage->dbh->do( 'use ' . $db_config->{database} ) )
        {
            $dbh = $SCHEMA_CACHE{$schema_cache_key};
        }
        else {

            # use cache if possible
            $dbh = $DBH_CACHE{$dbh_cache_key}
              if defined( $DBH_CACHE{$dbh_cache_key} );

            # Check conn / (re)connect
            for my $loopcount ( 0 .. 2 ) {
                $dbh ||= DBI->connect(
                    $db_config->{dbi},
                    $db_config->{username},
                    $db_config->{password},
                );

                # TODO: Make this (more) database independent
                last
                  if defined($dbh)
                      and $db_config->{dbi} =~ /^dbi\:(sqlite|Pg)\b/i;
                last
                  if defined($dbh)
                      and $dbh->do( 'use ' . $db_config->{database} );
                undef $dbh;    # Force reconnect
                select undef, undef, undef,
                  .01 + ( .5 * $loopcount );    # Short delay before retry
            }

        }

        $DBH_CACHE{$dbh_cache_key} = $dbh
          if defined($dbh);

        # Re-set schema to current config, has to be done on every request
        #  Comparable to "use" on other DBs than Postgres
        if (defined($dbh) and defined($db_config->{db_schema})) {
            # Currently only on Postgres:
            $dbh->do('SET search_path TO '.$db_config->{db_schema});
        }

	if (defined($dbh) and defined($db_config->{sql_postconnect})) {
	    if (ref($db_config->{sql_postconnect}) eq 'ARRAY') {
		for (@{$db_config->{sql_postconnect}}) {
		    $dbh->do($_);
		}
	    } else {
		$dbh->do($db_config->{sql_postconnect});
	    }
	}

        if (   ( !defined( $SCHEMA_CACHE{$schema_cache_key} ) )
            or ( $SCHEMA_CACHE{$schema_cache_key}->storage->dbh ne $dbh ) )
        {
            $SCHEMA_CACHE{$schema_cache_key} =
              $db_config->{class}->connect( sub { return $dbh; } );
              if ($db_config->{quoting}) {
                $SCHEMA_CACHE{$schema_cache_key}->storage->sql_maker->quote_char('"');
                $SCHEMA_CACHE{$schema_cache_key}->storage->sql_maker->name_sep('.');
              }
        }

        $self->{db} = $SCHEMA_CACHE{$schema_cache_key};
        return $self->{db};

    }

    return;
}

=head2 session

  $session = YAWF->session;

Returns the current YAWF session object.

=cut

sub session {
    my $self = _unishift(shift);

    $self->{session} = YAWF::Session->new(
        query   => $self->request->{query},
        cookies => $self->request->{cookies},
        create  => $self->request->{handler}->{SESSION} ? 1 : 0,
      )
      || {}
      if ref( $self->{session} ) ne 'YAWF::Session';

    $self->{session} ||= {};

    return $self->{session};
}

=head2 shared

  $shared = YAWF->shared;

Returns the shared data dir for YAWF.

=cut

sub shared {
    my $self = _unishift(shift);

    if ( !defined( $self->{shared} ) ) {
        for ( eval {File::ShareDir::dist_dir('YAWF')},
            File::Spec->catdir( $FindBin::Bin, 'share' ), 'share' )
        {
            next unless -d $_;
            $self->{shared} = $_;
            last;
        }
    }

    return $self->{shared};
}

=head1 AUTHOR

Sebastian Willing, C<< <sewi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-yawf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=YAWF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YAWF

You can also look for information at:

=over 4

=item * The Authors Blog

L<http://www.pal-blog.de/tag/YAWF>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=YAWF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/YAWF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/YAWF>

=item * Search CPAN

L<http://search.cpan.org/dist/YAWF/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Sebastian Willing, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of YAWF
