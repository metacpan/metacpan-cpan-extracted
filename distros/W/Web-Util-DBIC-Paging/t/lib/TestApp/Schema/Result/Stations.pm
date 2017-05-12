package TestApp::Schema::Result::Stations;
use parent 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components('Core');
__PACKAGE__->table('Station');
__PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    bill => { data_type => 'varchar' },
    ted  => { data_type => 'text' },
);
__PACKAGE__->set_primary_key('id');

sub TO_JSON {
   my $self = shift;
   return { map { $_ => $self->$_ } qw{id bill ted} };
}
1;
