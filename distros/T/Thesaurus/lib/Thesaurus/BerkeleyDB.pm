package Thesaurus::BerkeleyDB;

use strict;

use Thesaurus;
use base 'Thesaurus';

use BerkeleyDB qw( DB_CREATE DB_INIT_MPOOL DB_INIT_CDB DB_DUP
                   DB_WRITECURSOR DB_NOTFOUND DB_SET DB_KEYLAST
                   DB_NEXT_DUP );


use File::Basename;
use Params::Validate qw( validate SCALAR BOOLEAN );
use Storable;

sub new
{
    my $class = shift;

    return $class->SUPER::new(@_);
}

sub _init
{
    my $self = shift;
    my %p = validate( @_,
                      { filename => { type => SCALAR },
                        locking  => { type => BOOLEAN, default => 0 },
                        mode     => { type => SCALAR, default => 0644 },
                      },
                    );

    my $flags = DB_CREATE | DB_INIT_MPOOL;
    $flags |= DB_INIT_CDB if $p{locking};

    my $env =
        BerkeleyDB::Env->new
            ( -Flags => $flags,
              -Home  => dirname( $p{filename} ),
            )
                or die "Cannot create BerkeleyDB::Env: $BerkeleyDB::Error";

    my %db;
    tie %db, 'BerkeleyDB::Hash', ( -Env => $env,
                                   -Filename => $p{filename},
                                   -Flags => DB_CREATE,
                                   -Property => DB_DUP
                                   -Mode => $p{mode},
                                 );

    die "Cannot tie to BerkeleyDB::Hash: $BerkeleyDB::Error"
        unless tied %db;

    $self->{hash} = \%db;
    $self->{db}   = tied %db;
}

sub _add_list
{
    my $self = shift;
    my $list = shift;

    my %items = $self->_hash_from_list($list);

    my $cursor = $self->{db}->db_cursor( DB_WRITECURSOR )
        or die "cannot make db cursor: $BerkeleyDB::Error";

    foreach my $k ( keys %items )
    {
        my $val;
        my $status = $cursor->c_get( $k, $val, DB_SET );

        die "c_get failed for key $k: $status"
            if $status && $status != DB_NOTFOUND;

        if ( $status != DB_NOTFOUND )
        {
            $status = $cursor->c_del;

            die "c_del failed for key $k: $status" if $status;
        }

        foreach my $v ( @{ $items{$k} } )
        {
            my $status = $cursor->c_put( $k, Storable::nfreeze(\$v), DB_KEYLAST );

            die "c_put failed for $k: $status" if $status;
        }
    }
}

sub _find
{
    my $self = shift;

    my $cursor = $self->{db}->db_cursor
        or die "cannot make db cursor: $BerkeleyDB::Error";

    my %lists;
    foreach my $key (@_)
    {
        my $search_key = $self->{params}{ignore_case} ? lc $key : $key;

        # ignore duplicates
        next if $lists{$key};

        my $value;
        my $status = $cursor->c_get( $search_key, $value, DB_SET );

        if ($status)
        {
            if ( $status == DB_NOTFOUND )
            {
                $lists{$key} = [];
                next;
            }

            die "c_get failed for $search_key: $status";
        }

        push @{ $lists{$key} }, ${ Storable::thaw($value) };

        while (1)
        {
            $status = $cursor->c_get( $search_key, $value, DB_NEXT_DUP );

            if ($status)
            {
                last if $status == DB_NOTFOUND;

                die "c_get failed for $search_key: $status";
            }

            push @{ $lists{$key} }, ${ Storable::thaw($value) };
        }
    }

    return \%lists;
}


sub delete
{
    my $self = shift;


    my $cursor = $self->{db}->db_cursor( DB_WRITECURSOR )
        or die "cannot make db cursor: $BerkeleyDB::Error";

    foreach my $item (@_)
    {
	foreach my $key ( $self->find($item) )
	{
            # needs to be called multiple times to delete all duplicates
            while (1)
            {
                my $val;
                my $status = $cursor->c_get( $key, $val, DB_SET );

                die "c_get failed for key $key: $status"
                    if $status && $status != DB_NOTFOUND;

                last if $status == DB_NOTFOUND;

                $status = $cursor->c_del;

                die "c_del failed for key $key: $status" if $status;
            }
        }
    }
}

1;

__END__

=head1 NAME

Thesaurus::BerkeleyDB - Store thesaurus data in a BerkeleyDB database

=head1 SYNOPSIS

  use Thesaurus::BerkeleyDB;

  my $book = Thesaurus::BerkeleyDB->new( filename => '/some/file/name.db' );

=head1 DESCRIPTION

This subclass of C<Thesaurus> implements persistence by using a
BerkeleyDB file.

This module requires the C<BerkeleyDB> module from CPAN.

=head1 METHODS

=over 4

=item * new

This subclass's C<new> method takes the following parameters, in
addition to those accepted by its parent class:

=over 8

=item * filename => $filename

A filename for the database file.  It should be noted that the
BerkeleyDB library will usually create extra files for its own use.
These will be created in the same directory as the given filename.

=item * locking => $boolean

If this is true, then the BerkeleyDB concurrent locking system is used
for this database.  This system can handle reads and writes from
multiple processes safely.  This parameter defaults to false.

=item * mode => $mode

An octal mode to be used if the database file needs to be created.
This defaults to 0644.

=back

=item * delete

This subclass overrides the C<delete()> method.

=back

=cut
