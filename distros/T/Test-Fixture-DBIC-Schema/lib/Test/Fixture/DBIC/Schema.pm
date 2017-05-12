package Test::Fixture::DBIC::Schema;
use strict;
use warnings;
our $VERSION = '0.04';
use base 'Exporter';
our @EXPORT = qw/construct_fixture/;
use Params::Validate ':all';
use Kwalify ();
use Carp;

sub construct_fixture {
    validate(
        @_ => +{
            schema  => +{ isa => 'DBIx::Class::Schema' },
            fixture => 1,
        }
    );
    my %args = @_;

    my $fixture = _validate_fixture(_load_fixture($args{fixture}));
    _delete_all($args{schema});
    return _insert($args{schema}, $fixture);
}

sub _load_fixture {
    my $stuff = shift;

    if (ref $stuff) {
        if (ref $stuff eq 'ARRAY') {
            return $stuff;
        } else {
            croak "invalid fixture stuff. should be ARRAY: $stuff";
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
                        schema => { type => 'str', required => 1 },
                        name   => { type => 'str', required => 1 },
                        data   => { type => 'any', required => 1 },
                    },
                }
            ]
        },
        $stuff
    );

    $stuff;
}

sub _delete_all {
    my $schema = shift;

    $schema->resultset($_)->delete for
        grep { $schema->source_registrations->{$_}->isa('DBIx::Class::ResultSource::Table') }
            $schema->sources;
}

sub _insert {
    my ($schema, $fixture) = @_;

    my $result = {};
    for my $row ( @{ $fixture } ) {
        $schema->resultset( $row->{schema} )->create( $row->{data} );
        $result->{ $row->{name} } = $schema->resultset( $row->{schema} )->find( $row->{data} );
    }
    return $result;
}

1;
__END__

=encoding utf8

=for stopwords Fushihara Kan

=head1 NAME

Test::Fixture::DBIC::Schema - load fixture data to storage.

=head1 SYNOPSIS

  # in your t/*.t
  use Test::Fixture::DBIC::Schema;
  my $data = construct_fixture(
    schema  => $self->model,
    fixture => 'fixture.yaml',
  );

  # in your fixture.yaml
  - schema: Entry
    name: entry1
    data:
      id: 1
      title: my policy
      body: shut the f*ck up and write some code
      timestamp: 2008-01-01 11:22:44
  - schema::Entry
    name: entry2
    data:
      id: 2
      title: please join
      body: #coderepos-en@freenode.
      timestamp: 2008-02-23 23:22:58

=head1 DESCRIPTION

Test::Fixture::DBIC::Schema is fixture data loader for DBIx::Class::Schema.

=head1 METHODS

=head2 construct_fixture

  my $data = construct_fixture(
    schema  => $self->model,
    fixture => 'fixture.yaml',
  );

construct your fixture.

=head1 CODE COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    ...st/Fixture/DBIC/Schema.pm  100.0  100.0    n/a  100.0  100.0  100.0  100.0
    Total                         100.0  100.0    n/a  100.0  100.0  100.0  100.0
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

Kan Fushihara

=head1 SEE ALSO

L<DBIx::Class>, L<Kwalify>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
