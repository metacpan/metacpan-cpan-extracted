use strict;
use warnings;
use Test::More;
use Test::Exception;
use t::lib::Harness qw(constructor_io skip_unless_has_keys);

skip_unless_has_keys;

plan tests => 11;

#ok constructor_io->remove(item_name => "item", autocomplete_section => "standard"), "Successfully removed item";
#ok constructor_io->remove(item_name => "item-a", autocomplete_section => "standard"), "Successfully removed item";
#ok constructor_io->remove(item_name => "item-b", autocomplete_section => "standard"), "Successfully removed item";

ok constructor_io->add(item_name => "item", autocomplete_section => "standard"), "Successfully added item";

ok constructor_io->add_or_update(item_name => "item", suggested_score => 2000, autocomplete_section => "standard"), "Successfully updated item with add_or_update";
ok constructor_io->add_or_update(item_name => "item2", autocomplete_section => "standard"), "Successfully added item with add_or_update";
ok constructor_io->remove(item_name => "item2", autocomplete_section => "standard"), "Successfully removed item2";

ok constructor_io->modify(item_name => "item", new_item_name => "new item",
  autocomplete_section => "standard"), "Successfully modified item";
ok constructor_io->remove(item_name => "new item", autocomplete_section => "standard"), "Successfully removed item";

throws_ok { constructor_io->add(item_name => "item", autocomplete_section =>
  "whatevs") } qr/invalid autocomplete_section/, "Threw invalid autocomplete section exception";

ok constructor_io->add_batch(items => [ { item_name => "item-a" }, { item_name => "item-b" } ], autocomplete_section => "standard"), "Successfully added multiple items in a batch";
ok constructor_io->add_or_update_batch(items => [ { item_name => "item-a" }, { item_name => "item-b" } ], autocomplete_section => "standard"), "Successfully added multiple items in a batch";
ok constructor_io->remove(item_name => "item-a", autocomplete_section => "standard"), "Successfully removed item";
ok constructor_io->remove(item_name => "item-b", autocomplete_section => "standard"), "Successfully removed item";
