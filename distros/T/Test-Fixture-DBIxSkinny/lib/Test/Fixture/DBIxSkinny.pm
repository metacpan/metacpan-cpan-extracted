package Test::Fixture::DBIxSkinny;
use strict;
use warnings;
our $VERSION = '0.01';
use base 'Exporter';
our @EXPORT = qw/construct_fixture/;
use Params::Validate ':all';
use Carp ();
use Kwalify ();

sub construct_fixture {
    my %args = validate(
        @_ => +{
            db      => 1,
            fixture => 1,
        }
    );

    my $fixture = _validate_fixture(_load_fixture($args{fixture}));
    _delete_all($args{db});
    return _insert($args{db}, $fixture);
}

sub _load_fixture {
    my $stuff = shift;

    if (ref $stuff) {
        if (ref $stuff eq 'ARRAY') {
            return $stuff;
        } else {
            Carp::croak "invalid fixture stuff. should be ARRAY: $stuff";
        }
    } else {
        require YAML::Syck;
        return YAML::Syck::LoadFile($stuff);
    }
}

sub _validate_fixture {
    my $stuff = shift;

    Kwalify::validate(
        {
            type     => 'seq',
            sequence => [
                {
                    type    => 'map',
                    mapping => {
                        table => { type => 'str', required => 1 },
                        name  => { type => 'str', required => 1 },
                        data  => { type => 'any', required => 1 },
                    },
                }
            ]
        },
        $stuff
    );

    $stuff;
}

sub _delete_all {
    my $db = shift;
    $db->delete($_) for
        keys %{$db->schema->schema_info};
}

sub _insert {
    my ($db, $fixture) = @_;

    my $result = {};
    for my $row ( @{ $fixture } ) {
        $result->{ $row->{name} } = $db->insert($row->{table}, $row->{data});
    }
    return $result;
}

1;
__END__

=head1 NAME

Test::Fixture::DBIxSkinny - load fixture data to storage for DBIx::Skinny

=head1 SYNOPSIS

  # in your t/*.t
  use Test::Fixture::DBIxSkinny;
  my $data = construct_fixture(
    db      => Your::Skinny::Class,
    fixture => 'fixture.yaml',
  );

  # in your fixture.yaml
  - table: entry
    name: entry1
    data:
      id: 1
      title: my policy
      body: shut the f*ck up and write some code
      timestamp: 2008-01-01 11:22:44
  - table: entry
    name: entry2
    data:
      id: 2
      title: please join
      body: #coderepos-en@freenode.
      timestamp: 2008-02-23 23:22:58

=head1 DESCRIPTION

Test::Fixture::DBIxSkinny is fixture data loader for DBIx::Skinny.

=head1 METHODS

=head2 construct_fixture

  my $data = construct_fixture(
      db      => Your::Skinny::Class,
      fixture => 'fixture.yaml',
  );

construct your fixture.

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 SEE ALSO

L<DBIx::Skinny>, L<Kwalify>

=head1 THANKS

L<Test::Fixture::DBIC::Schema>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
