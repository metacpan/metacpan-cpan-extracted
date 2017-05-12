package DBIx::Class::Schema::WithTP;

use base DBIx::Class::Schema;
use Config::JFDI;
use TreePath;
use Carp qw/croak/;
use strict;

__PACKAGE__->mk_classdata('treepath');

sub connect {
    my $self = shift;
    my $conffile = shift;

    my ($jfdi_h, $jfdi) = Config::JFDI->open($conffile)
      or croak "Error (conf: $conffile) : $!\n";
    my $config = $jfdi->get;
    my $model = $config->{TreePath}->{backend}->{args}->{model};
    my $dsn = $config->{$model}->{connect_info}->{dsn};

    die 'Error in conf file : $conffile, can not find dsn !'
        if ( ! $dsn );

    my $schema = $self->clone->connection($dsn,@_);

    my $tp = TreePath->new(  conf => $config );

    $tp->schema($schema);

    $schema->treepath($tp);

    return $schema;
}
1;
