use utf8;
package Schema::TPath::Result::Comment;

=head1 NAME

Schema::TPath::Result::Comment

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';


__PACKAGE__->load_components;
__PACKAGE__->table("comments");
__PACKAGE__->add_columns(
    "id",
    {
        data_type         => "INTEGER",
        is_nullable       => 0,
        size              => undef,
        is_auto_increment => 1
    },
    "page_id",
    { data_type => "INTEGER", is_nullable => 0, size => undef },
    "body",
    { data_type => "TEXT", is_nullable => 0, size => undef },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
    "page",
    "Schema::TPath::Result::Page",
    { "foreign.id" => "self.page_id" }
);

=head1 NAME

Schema::TPath::Result::Comment - store comments

=head1 METHODS


=head1 AUTHOR

Daniel Brosseau <dab@catapulse.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
