package WWW::RobotRules::DBIC::Schema::Netloc;

# Created by DBIx::Class::Schema::Loader v0.03007 @ 2006-10-18 11:53:27

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "+WWW::RobotRules::DBIC::Schema::DateTime", "Core");
__PACKAGE__->table("netloc");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "user_agent_id",
  { data_type => "INT", default_value => "", is_nullable => 0, size => 10 },
  "netloc",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 64 },
  "count",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "visited_on",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "fresh_until",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "created_on",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("netloc", ["user_agent_id", "netloc"]);
__PACKAGE__->has_many('rules', 'WWW::RobotRules::DBIC::Schema::Rule', 'netloc_id');
__PACKAGE__->belongs_to('user_agent', 'WWW::RobotRules::DBIC::Schema::UserAgent', 'user_agent_id');

1;

