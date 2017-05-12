package WWW::RobotRules::DBIC::Schema::Rule;

# Created by DBIx::Class::Schema::Loader v0.03007 @ 2006-10-18 11:53:27

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "+WWW::RobotRules::DBIC::Schema::DateTime", "Core");
__PACKAGE__->table("rule");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "netloc_id",
  { data_type => "INT", default_value => "", is_nullable => 0, size => 10 },
  "rule",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "created_on",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("netloc_id", ["netloc_id", "rule"]);
__PACKAGE__->belongs_to('netloc', 'WWW::RobotRules::DBIC::Schema::Netloc', 'netloc_id');

1;

