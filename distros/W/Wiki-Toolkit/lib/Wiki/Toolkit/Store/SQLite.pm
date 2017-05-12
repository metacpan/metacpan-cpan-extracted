package Wiki::Toolkit::Store::SQLite;

use strict;

use vars qw( @ISA $VERSION );

use Wiki::Toolkit::Store::Database;
use Carp qw/carp croak/;

@ISA = qw( Wiki::Toolkit::Store::Database );
$VERSION = 0.06;

=head1 NAME

Wiki::Toolkit::Store::SQLite - SQLite storage backend for Wiki::Toolkit

=head1 SYNOPSIS

See Wiki::Toolkit::Store::Database

=cut

# Internal method to return the data source string required by DBI.
sub _dsn {
    my ($self, $dbname) = @_;
    return "dbi:SQLite:dbname=$dbname";
}

=head1 METHODS

=over 4

=item B<new>

  my $store = Wiki::Toolkit::Store::SQLite->new( dbname => "wiki" );

The dbname parameter is mandatory.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;
    @args{qw(dbuser dbpass)} = ("", "");  # for the parent class _init
    return $self->_init(%args);
}

=item B<check_and_write_node>

  $store->check_and_write_node( node     => $node,
                checksum => $checksum,
                                %other_args );

Locks the node, verifies the checksum, calls
C<write_node_post_locking> with all supplied arguments, unlocks the
node. Returns the version of the updated node on successful writing, 0 if
checksum doesn't match, -1 if the change was not applied, croaks on error.

=back

=cut

sub check_and_write_node {
    my ($self, %args) = @_;
    my ($node, $checksum) = @args{qw( node checksum )};

    my $dbh = $self->{_dbh};
    $dbh->begin_work;

    my $ok = eval {
        $self->verify_checksum($node, $checksum) or return 0;
        $self->write_node_post_locking( %args );
    };
    if ($@) {
        my $error = $@;
        $dbh->rollback;
        if ( $error =~ /database is locked/
            or $error =~ /DBI connect.+failed/ ) {
            return 0;
        } else {
            croak "Unhandled error: [$error]";
        }
    } else {
        $dbh->commit;
        return $ok;
    }
}

# Get the attributes for the database connection.  We set
# sqlite_use_immediate_transaction to false because we use database locking
# explicitly in check_and_write_node.  This is required for DBD::SQLite 1.38.
sub _get_dbh_connect_attr {
    my $self = shift;
    my $attrs = $self->SUPER::_get_dbh_connect_attr;
    return {
             %$attrs,
             sqlite_use_immediate_transaction => 0
    };
}

sub _get_lowercase_compare_sql {
    my ($self, $column) = @_;
    return "$column LIKE ?";
}

sub _get_comparison_sql {
    my ($self, %args) = @_;
    if ( $args{ignore_case} ) {
        return "$args{thing1} LIKE $args{thing2}";
    } else {
        return "$args{thing1} = $args{thing2}";
    }
}

sub _get_node_exists_ignore_case_sql {
    return "SELECT name FROM node WHERE name LIKE ? ";
}

1;
