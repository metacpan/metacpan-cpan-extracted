#!/usr/bin/perl

use strict;
use warnings;

package WWW::Shopify::Model::Item;
use DateTime;
use WWW::Shopify::Query;
use WWW::Shopify::Field;
use WWW::Shopify::Field::String;

=head1 NAME

Item - Main superclass for all the shopify objects.

=cut

=head1 DESCRIPTION

Items are the main super class for all Shopify objects. This class holds glue code that ties the schemas (WWW::Shopify::Model::Product, for example), which only hold definitions about how the Shopify API works, and WWW::Shopify, which is the acutal method for calling Shopify's interface.

These objects can be used in many ways; they boil down to one of three states.

=over 4

=item DBIx::Class Object: The item has been mapped to a DBIx::Class schema and can be stored in a relational database.

=item WWW::Shopify::Model Object: The item is in an intemediate state, suitable for querying, perusing and manipulating.

=item JSON-Like Hash: The item is similar to the WWW::Shopify::Model, but lacks all-non canonical shopify references, and is ready to be encode_json'd before being sent off to Shopify.

=back

=cut

=head1 METHODS

Most of these methods you shouldn't have to mess with, most of them are used to describe the objects appropriately so that testing mock frameworks and database can be created with ease.

=cut

use Exporter 'import';
our @EXPORT = qw(generate_accessor);

=head2 new($%params)

Generates a new intermediate stage (WWW::Shopify::Model::...) object.

=cut

use Scalar::Util qw(weaken);

sub new { 
	my $self = (defined $_[1]) ? $_[1] : {};
	weaken($self->{associated_parent}) if $self->{associated_parent};
	return bless $self, $_[0];
}

=head2 parent($package)

Does this package have a parent?

=cut

sub parent { return undef; }
sub is_item { return 1; }

=head2 is_shop($package)

Convenience method telling us if we're a WWW::Shopify::Model::Shop.

=cut

sub is_shop { return undef; }

=head2 singular($package)

Returns the text representing the singular form of this package. (WWW::Shopify::Model::Order->singular eq "order").

=cut

# Returns the singular form of the object. Usually the name of the file.
# Is like this, because we want to be able to call this on the package as well as an object in it.
sub singular {
	# If we have a package instead of an instantiated object.
	if (!ref($_[0])) {
		die $_[0] unless $_[0] =~ m/(\:\:)?(\w+)$/;
		my $name = $2;
		$name =~ s/([a-z])([A-Z])/$1_$2/g;
		return (lc $name);
	}
	# Here, we have an object, so run this function again with the package name.
	return singular(ref($_[0]));
}

# Specifies in a text-friendly manner the FULL specific name of this package.
sub singular_fully_qualified { 
	if (!ref($_[0])) {
		die $_[0] unless $_[0] =~ m/Model::([:\w]+)$/;
		my $name = lc($1);
		$name =~ s/\:\:/-/g;
		return $name;
	}
	# Here, we have an object, so run this function again with the package name.
	return singular_fully_qualified(ref($_[0]));
}

=head2 plural($package)

Returns the text representing the plural form of this package. (WWW::Shopify::Model::Address->plural eq "addresses").

=cut

sub plural { return $_[0]->singular() . "s"; }

# Sigh. Yet again let's just violate conventions on a single resource, necessitating yet more methods.
# I'm looking at you, fulfillment event.
sub url_singular { return $_[0]->singular; }
sub url_plural { return $_[0]->plural; }

sub needs_login { return undef; }
sub needs_form_encoding_get_all { return undef; }
sub needs_form_encoding_get { return undef; }
sub needs_form_encoding_create { return undef; }
sub needs_form_encoding_update { return undef; }
sub needs_form_encoding_delete { return undef; }

=head2 needs_plus($package)

Returns whether or not a Shopify+ account is required to use this resource.

=cut

sub needs_plus { return undef; }

# List of fields that should be filled automatically on creation.
sub is_nested { return undef; }
sub identifier { return ("id"); }

# Counts the ::. Is helpful in a bunch of ways.
sub nested_level {
	my ($package) = @_;
	my $level = -2;
	while ($package =~ m/::/g) {
		++$level;
	}
	return $level;
}


# I cannot fucking believe I'm doing this. Everything can be counted.
# Oh, except themes. We don't count those. For some arbitrary reason.

=head2 countable($package), gettable($package), creatable($package), updatable($package), deletable($package), searchable($package)

Determines whether or not this package can perform these main actions. 1 for yes, undef for no.

=cut

sub countable { return 1; }
sub gettable { return 1; }
# Whether or not we can get it as a single entity, by ID.
sub singlable { return $_[0]->gettable; }
sub creatable { return 1; }
sub updatable { my @fields = $_[0]->update_fields; return int(@fields) > 0; }
sub deletable { return 1; }
sub searchable { return undef; }

=head2 actions($package)

Returns an array of special actions that this package can perform (for orders, they can open, close, and cancel).

=cut

sub actions { return qw(); }
use List::Util qw(first);
sub can_action { return defined first { $_ eq $_[1] } $_[0]->actions; }
sub can_open { return $_[0]->can_action("open"); }
sub can_activate { return $_[0]->can_action("activate"); }
sub can_deactivate { return $_[0]->can_action("deactivate"); }
sub can_enable { return $_[0]->can_action("enable"); }
sub can_disable { return $_[0]->can_action("disable"); }
sub can_close { return $_[0]->can_action("close"); }
sub can_cancel { return $_[0]->can_action("cancel"); }
sub can_account_activation_url { return $_[0]->can_action("account_activation_url"); }

=head2 create_method($package), update_method($package), delete_method($package)

Shopify occasionally arbitrarily changes their update/create methods from POST and PUT around. Sometimes it makes them the same. These say which method is used where, but generally the convention is:

=over 4

=item CREATE => POST

=item UPDATE => PUT

=item DELETE => DELETE

=back

But not always.

=cut

# I CANNOT FUCKING BELIEVE I AM DOING THIS; WHAT THE FUCK SHOPIFY. WHY!? WHY MAKE IT DIFFERENT ARBITRARILY!?
sub create_method { return "POST"; }
sub update_method { return "PUT"; }
sub delete_method { return "DELETE"; }

=head2 queries($package)

Returns a hash of WWW::Shopify::Query objects which describe you what kind of filters you can run on this package. (Limit, since_id, created_at_min, etc...)

=cut

sub queries { return {}; }

=head2 unique_fields($package)

An array of fields which have to be unique in this package (WWW::Shopify::Model::Customer's email, for example)

=cut

sub unique_fields { return qw(); }

=head2 get_fields($package)

Usually every field in a class, but not always; this returns an array of keys that tells you which fields will come back when you perform a normal get request.

=cut

sub get_fields { return keys(%{$_[0]->fields}); }

=head2 creation_minimal($package)

Returns an array of fields that are required before you send an object off to be created on Shopify.

=cut

sub creation_minimal { return (); }

=head2 creation_filled($package)

Returns an array of fields that you should be getting back filled with data when the object is created on Shopify.

=cut

sub creation_filled { return qw(id); }

=head2 update_fields($package)

Returns an array of fields that you can update when an object is already created.

=cut

sub update_fields { return qw(); }

=head2 update_filled($package)

Returns an array of fields that will be changed/filled when an object is updated.

=cut

sub update_filled { return qw(); }


=head2 throws_webhooks($package), throws_create_webhooks($package), throws_update_webhooks($package), throws_delete_webhooks($package)

Tells you whether or not the object throws webhooks for a living.

=cut

sub throws_webhooks { return undef; }
sub throws_create_webhooks { return $_[0]->throws_webhooks; }
sub throws_update_webhooks { return $_[0]->throws_webhooks; }
sub throws_delete_webhooks { return $_[0]->throws_webhooks; }

# Oh fucking WOW. WHAT THE FUCK. Variants, of course, delete directly with their id, and modify with it.
# Metafields delete with their id, but modify through their parent. They also get through their parents.
# Variants of course, get through their id directly. I'm at a loss for words. Why!? Article are different, yet again.

=head2 get_all_through_parent($package), get_through_parent($package), create_through_parent($package), update_through_parent($package), delete_through_parent($package)

Occasionally, Shopify decides they wanna change up their normal API conventions, and decides to throw us a curve ball, and change up whether or not certain objects have to be accessed through their parent objects /product/3242134/variants/342342.json vs. /variants/342342.json

These tell you which objects have to go through their parent, and which don't. It tends to be rather arbitrary.

=cut

sub get_all_through_parent { return defined $_[0]->parent; }
sub get_through_parent { return defined $_[0]->parent; }
sub count_through_parent { return $_[0]->get_all_through_parent; }
sub create_through_parent { return defined $_[0]->parent; }
sub update_through_parent { return defined $_[0]->parent; } 
sub delete_through_parent { return defined $_[0]->parent; }
sub activate_through_parent { return defined $_[0]->parent; }
sub deactivate_through_parent { return defined $_[0]->parent; }
sub open_through_parent { return defined $_[0]->parent; }
sub close_through_parent { return defined $_[0]->parent; }
sub cancel_through_parent { return defined $_[0]->parent; }
sub enable_through_parent { return defined $_[0]->parent; }
sub disable_through_parent { return defined $_[0]->parent; }
sub account_activation_url_through_parent { return defined $_[0]->parent; }

=head2 max_per_page

Tells you how many you can grab in a single page.

=cut

sub max_per_page { return 250; }

=head2 default_per_page

Tells you how many entries you'll get by default.

=cut

sub default_per_page { return 50; }

=head2 included_in_parent

Tells you whether a sub-object is included by defualt when you get an object as a sub-object. Most cases is 1.

=cut

sub included_in_parent { return 1; }

=head2 field($package, $name), fields($package)

Returns a WWW::Shopify::Field::... which describes the specified field, or returns a hash containing all fields.

=cut

sub fields { }
sub field { my ($package, $name) = @_; return $package->fields->{$name}; }

=head2 associate($self)

Returns the WWW::Shopify object that created/updated/deleted this object last.

=cut

sub associate { $_[0]->{associated_sa} = $_[1] if $_[1]; return $_[0]->{associated_sa}; }

=head2 associate_parent($self)

Returns the parent associated with this object. If we're a variant, it'll return the parent product (if it had access to it at one point; it usually does). Weak reference.

=cut


use Scalar::Util qw(weaken);
sub associated_parent { 
	if (defined $_[1]) { 
		$_[0]->{associated_parent} = $_[1];
		weaken($_[0]->{associated_parent});
	}
	return $_[0]->{associated_parent};
}

sub has_metafields { return defined $_[0]->field('metafields'); }

=head2 metafields($self)

Returns the metafields associated with this item. If they haven't been gotten before, a request is made, and they're cahced inside the object.

If you change a metafield, and later want to access it through a copy of the object, and this copy already has looked at the metafields, you'll get a stale copy.

If this is the case, call the method below.

=cut

use Data::Dumper;
sub metafields {
	my $sa = $_[0]->associate;
	if (!defined $_[0]->{metafields}) {
		die new WWW::Shopify::Exception("You cannot call metafields on an unassociated item.") unless $sa;
		$_[0]->{metafields} = [$sa->get_all('Metafield', { parent => $_[0] })];
	}
	return $_[0]->{metafields} unless wantarray;
	return @{$_[0]->{metafields}};
}

=head2 refesh_metafields($self)

Returns the metafields associated with item, but ALWAYS performs a get request.

=cut

sub refresh_metafields {
	delete $_[0]->{metafields} if exists $_[0]->{metafields};
	return $_[0]->metafields;
}

=head2 add_metafield($self, $metafield)

Takes a WWW::Shopify::Model::Metafield object. 

=cut

sub add_metafield {
	my ($self, $metafield) = @_; 
	my $sa = $_[0]->associate;
	die new WWW::Shopify::Exception("You cannot add metafields on an unassociated item.") unless $sa;
	$metafield->associated_parent($self);
	return $sa->create($metafield);
}

=head2 from_json($package, $json_hash, [$associated])

Returns a WWW::Shopify::Model::... intermediate object from a hash that's been decoded from a JSON object (i.e. normal shopify object in the API docs, decoded using JSON qw(decode_json); ). Does a bunch of nice conversions, like putting DateTime objects in the proper places, and associate each individual obejct with a reference to its parent and to the WWW::Shopify object that created it.

=cut

sub from_json {
	my ($package, $json, $associated) = @_;

	sub decodeForRef { 
		my ($self, $json, $ref, $associated) = @_;
		for (keys(%{$ref})) {
			if ($ref->{$_}->is_relation()) {
				my $package = $ref->{$_}->relation();
				if ($ref->{$_}->is_many()) {
					# This may not be necesasry, but this is such fundamental code I don't want to mess with it.
					next unless exists $json->{$package->plural()} || exists $json->{$_};
					my @objects;
					my $index = exists $json->{$package->plural()} ? $package->plural : $_;
					@objects = defined $json->{$index} ? @{$json->{$index}} : ();
					$self->{$_} = [map {
						my $o = $package->from_json($_, $associated);
						$o->associated_parent($self);
						$o;
					} @objects];
				}
				elsif ($ref->{$_}->is_one && $ref->{$_}->is_own) {
					next unless (exists $json->{$_});
					$self->{$_} = $package->from_json($json->{$_}, $associated);
					$self->{$_}->associated_parent($self) if $self->{$_};
				}
				elsif ($ref->{$_}->is_one) {
					$self->{$_} = $json->{$_} if exists $json->{$_};
				}
				else {
					die "Relationship specified must be either many, or one in $package.";
				}
			}
			else {
				$self->{$_} = $ref->{$_}->from_shopify($json->{$_}) if exists $json->{$_};
			}
		}
	}
	return undef unless $json;

	my $self = $package->new();
	$self->associate($associated) if ($associated);

	$self->decodeForRef($json, $self->fields, $associated);
	return $self;
}

=head2 to_json($self)

Returns a hash that's ready to be converted in to a JSON string using encode_json from the JSON package.

=cut

sub to_json($) {
	my ($self) = @_;
	my $fields = $self->fields();
	my $final = {};
	foreach my $key (keys(%$self)) {
		next unless exists $fields->{$key};
		if ($fields->{$key}->is_relation()) {
			if ($fields->{$key}->is_many()) {
				# Since metafields don't come prepackaged, we don't get them. Unless we've already got them.
				next if $key eq "metafields" && !$_[0]->{metafields};
				my @results = $self->$key();
				if (int(@results)) {
					$final->{$key} = [map { $_->to_json() } @results];
				}
				else {
					$final->{$key} = [] if exists $self->{$key};
				}
			}
			if ($fields->{$key}->is_one() && $fields->{$key}->is_reference()) {
				if (defined $self->$key()) {
					# This is inconsistent; this if is a stop-gap measure.
					# Getting directly from teh database seems to make this automatically an id.
					if (ref($self->$key())) {
						$final->{$key} = $self->$key()->id();
					}
					else {
						$final->{$key} = $self->$key();
					}
				}
				else {
					$final->{$key} = undef if exists $self->{$key};
				}
			}
			$final->{$key} = ($self->$key ? $self->$key->to_json() : undef) if (exists $self->{$key} && $fields->{$key}->is_one() && $fields->{$key}->is_own());
		}
		else {
			$final->{$key} = $fields->{$key}->to_shopify($self->$key) if exists $self->{$key};
		}
	}
	return $final;
}

# Quick n' dirty clone method.
sub clone {
	my ($self) = @_;
	return ref($self)->from_json($self->to_json);
}

sub generate_accessors {
	return join("\n", 
		(map { "__PACKAGE__->queries->{$_}->name('$_');" } keys(%{$_[0]->queries})),
		(map { "__PACKAGE__->fields->{$_}->name('$_');" } keys(%{$_[0]->fields})),
		(map { "sub $_ { \$_[0]->{$_} = \$_[1] if defined \$_[1]; return undef unless defined \$_[0]->{$_}; return \@{\$_[0]->{$_}} if wantarray; return \$_[0]->{$_}; }" } grep { $_ ne "metafields" && $_[0]->field($_)->is_relation && $_[0]->field($_)->is_many } keys(%{$_[0]->fields})),
		(map { "sub $_ { \$_[0]->{$_} = \$_[1] if defined \$_[1]; return \$_[0]->{$_}; }" } grep { $_ ne "metafields" && (!$_[0]->field($_)->is_relation || !$_[0]->field($_)->is_many) } keys(%{$_[0]->fields})),
		(map { "sub $_ { my \$sa = \$_[0]->associate; die \"Can't call a special action on an unassociated item.\" unless \$sa; return \$sa->$_(\$_[0]); }" } $_[0]->actions)
	); 
}

sub read_scope { return undef; }
sub write_scope { return undef; }

=head1 SEE ALSO

L<WWW::Shopify>

=head1 AUTHOR

Adam Harrison

=head1 LICENSE

See LICENSE in the main directory.

=cut

1
