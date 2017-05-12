package Text::CSV::Auto::ExportToDB;
BEGIN {
  $Text::CSV::Auto::ExportToDB::VERSION = '0.06';
}
use Moose::Role;

requires 'auto';
requires 'export';

use Moose::Util::TypeConstraints;

subtype 'TextCSVAutoConnection'
    => as 'Object'
    => where { $_->isa('DBI::db') or $_->isa('DBIx::Connector') }
    => message { 'The connection must be either a DBI handle or a DBIx::Connector object' };

has 'connection' => (
    is       => 'ro',
    isa      => 'TextCSVAutoConnection',
    required => 1,
);

has 'table' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);
sub _build_table {
    my ($self) = @_;

    my $table = $self->auto->file();
    $table =~ s{^.+/(.+?)$}{$1};
    $table =~ s{\.[^.]+$}{};
    $table = $self->auto->_format_string( $table );

    return $table;
}

has 'method' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'svp',
);

has 'mode' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'fixup',
);

sub _run {
    my ($self, $sub) = @_;

    if ($self->connection->isa('DBI::db')) {
        return $sub->( $self->connection() );
    }

    my $method = $self->method();
    return $self->connection->$method( $self->mode(), $sub );
}

1;
