package WebService::Autotask;
use strict;
use warnings;

use SOAP::Lite;
use XML::LibXML;
use Scalar::Util qw(blessed);
use MIME::Base64;
use Encode;

use vars qw($VERSION);
$VERSION = '1.1';

my @VALID_OPS = qw(
	Equals NotEqual GreaterThan LessThan GreaterThanOrEquals LessThanOrEquals 
	BeginsWith EndsWith Contains IsNull IsNotNull IsThisDay Like NotLike 
	SoundsLike
);

my @VALID_CONDITIONS = qw(AND OR);

=head1 NAME 

WebService::Autotask - Interface to the Autotask webservices API.

=head1 SYNOPSIS

  my $at = WebService::Autotask->new({
    username => 'user@autotask.account.com',
    password => 'some_password'
  });

  my $list = $at->query({
    entity => 'Account',
    query => [
      {
        name => 'AccountName',
        expressions => [{op => 'BeginsWith', value => 'b'}]
      },
    ]
  });

  $list->[0]->{AccountName} = 'New Account Name';

  $at->update(@$list);

  $list = $at->create(
    bless({
      AccountName => "Testing Account Name",
      Phone => "800-555-1234",
      AccountType => 1,
      OwnerResourceID => 123456,
    }, 'Account')
  );

=head1 DESCRIPTION

"WebService::Autotask" is a module that provides an interface to the Autotask webservices
API. Using this method and your Autotask login credentials you can access and
manage your Autotask items using this interface. You should read the Autotask
API documentation prior to using this module.

Note: all input is assumed to be UTF-8.

=head1 CONSTRUCTOR 

=head2 new

Create a new WebService::Autotask SOAP interface object. This takes a hash
references with the following arguments:

=over 4

=item B<username>

The username to use when logging into the Autotask system

=item B<password>

The password to use when logging into the Autotask system.

=item B<proxy>

If you know which proxy server you are to use then you may supply it here. By 
default one of the proxies is used and then the correct proxy is determined
after logging in. If the default proxy is not correct the correct proxy will 
then be logged into automatically. This option should not be required.

=back

=cut

sub new {
	my ($package, $args, $proxies) = @_;

	# Set a default proxy to use.
	$args->{proxy} = 'https://webservices.autotask.net/atservices/1.5/atws.asmx' if (!exists($args->{proxy}));
	die "No username provided in call to new()" if (!$args->{username});
	die "No password provided in call to new()" if (!$args->{password});

	# Use the URI module to get the domain name.
	my $site = $args->{proxy};
	$site =~ s/^https?:\/\///;
	$site =~ s/\/.*$//;

	# Create an empty hashref for the proxies arg if we don't already have one
	# defined.
	$proxies = {};

	my $soap = SOAP::Lite
		->uri('http://autotask.net/ATWS/v1_5/')
		->on_action(sub { return join('', @_)})
		->proxy($args->{proxy},
			credentials => [
				"$site:443", $site, $args->{username} => $args->{password}
			]);
	my $self = {
		at_soap => $soap,
		valid_entities => {},
		picklist_values => {},
		error => ''
	};

	# Check that we are using the right proxy.
	my $res = $soap->getZoneInfo(SOAP::Data->value($args->{username})->name('UserName'))->result;
	if ($res->{Error} || $res->{ErrorCode}) {
		die "Could not find correct Autotask Proxy for user: " . $args->{username} . "\n";
	}
	# See if our proxy matches the one provided.
	if ($args->{proxy} ne $res->{URL}) {
		if (exists($proxies->{$res->{URL}})) {
			die "Infinite recursion detected. We have already tried the proxy " . $res->{URL} . " but have been directed to it again";
		}
		$proxies->{$args->{proxy}} = 1;
		$args->{proxy} = $res->{URL};
		return $package->new($args, $proxies);
	}

	# Get a list of all the entity types available.
	$res = $soap->GetEntityInfo->result;
	if (!exists($res->{EntityInfo}) || ref($res->{EntityInfo}) ne 'ARRAY') {
		die "Unable to get a list of valid Entities from the Autotask server";
	}
	foreach my $ent (@{$res->{EntityInfo}}) {
		$self->{valid_entities}->{$ent->{Name}} = $ent;
	}

	return bless($self, $package);
}

=head1 METHODS

=head2 query(%args)

Generic query method to query the Autotask system for entity data. This takes
a hash ref as its argument. If an error occurs while trying to parse the given
arguments or creating the associated QueryXML query this method will die with
an appropriate error. Returns either the single matching entry as a hash 
reference, or an array of hash references when more than one result is returned.
The following keys are allowed:

=over 4

=item B<entity>

The name of the entity you want to query for.

=item B<query>

An array reference of fields and conditions that are used to construct the
query XML. See below for the definition of a field and a condition.

=over 4

=item B<field>

A field is a hash reference that contains the following entries

=over 4

=item B<name>

The name of the field to be querying.

=item B<udf>

Boolean value to indicate if this field is a user defined field or not. Only
one UDF field is allowed per query, by default if ommited this is set to
false.

=item B<expressions>

An array of hash references for the expressions to apply to this field. The
keys for this hash refernce are:

=over 4

=item B<op>

The operator to use. One of: Equals, NotEqual, GreaterThan, LessThan,
GreaterThanOrEquals, LessThanOrEquals, BeginsWith, EndsWith, Contains, IsNull,
IsNotNull, IsThisDay, Like, NotLike or SoundsLike. If not in this list an
error will be issued.

=item B<value>

The appropriate value to go with the given operator.

=back

=back

=item B<condition>

A condition block that allows you define a more complex query. Each condition
element is a hash reference with the following fields:

=over 4

=item B<operator>

The condition operator to be used. If no operator value is given AND is assumed. 
Valid operators are: AND and OR.

=item B<elements>

Each condition contains a list of field and/or expression elements. These have
already been defined above.

=back

=back

An example of a valid query woudl be:

 query => [
 	{
 		name => 'AccountName',
 		expressions => [{op => 'Equals', value => 'New Account'}]
	},
	{
		operator => 'OR',
		elements => [
			{
				name => 'FirstName',
				expressions => [
					{op => 'BeginsWith', value => 'A'},
					{op => 'EndsWith', value => 'S'}
				]
			},
			{
				name => 'LastName',
				expressions => [
					{op => 'BeginsWith', value => 'A'},
					{op => 'EndsWith', value => 'S'}
				]
			}
		]
	}
 ]

This will find all accounts with the AccountName of New Account that also
have either a FirstName or a LastName that begins with an A and ends with an
S.

=back

=cut

sub query {
	my ($self, $args) = @_;

	# Validate that we have the right arguments.
	$self->_validate_entity_argument($args->{entity}, 'query');
	die "Missing query argument in call to query" 
		if (!exists($args->{query}) || !$args->{query});

	# Get the entity information if we don't already have it.
	$self->_load_entity_field_info($args->{entity});

	# We need to generate the QueryXML from the Query argument.
	my $query = $self->_create_query_xml($args->{entity}, $args->{query});
	
	my $soap = $self->{at_soap};
	my $res = $soap->query(SOAP::Data->value($query)->name('sXML'))->result;

	if ($res->{Errors} || $res->{ReturnCode} ne '1') {
		# There were errors. Grab the errors and set $@ to their textual values.
		$self->_set_error($res->{Errors}->{ATWSError});
		return undef;
	}

	return _get_entity_results($res);
}

sub _create_query_xml {
	my ($self, $entity, $query) = @_;

	my $doc = XML::LibXML::Document->new();
	my $xml = $doc->createElement('queryxml');
	$doc->setDocumentElement($xml);

	my $elem = $doc->createElement('entity');
	$elem->appendChild($doc->createTextNode($entity));
	$xml->appendChild($elem);
	my $q_elem = $doc->createElement('query');

	# Figure out the query values.
	foreach my $item (@$query) {
		# Is this a field or a condition?
		if (exists($item->{name})) {
			# We have a field.
			$q_elem->appendChild($self->_parse_field($entity, $doc, $item));
		}
		elsif (exists($item->{elements})) {
			# We have a condition.
			$q_elem->appendChild($self->_parse_condition($entity, $doc, $item));
		}
		else {
			# We have an invalid element.
			die "Found an invalid element in query element";
		}
	}

	$xml->appendChild($q_elem);
	return $xml->toString();
}

sub _parse_condition {
	my ($self, $entity, $doc, $condition) = @_;

	my $c_elem = $doc->createElement('condition');
	if ($condition->{operator}) {
		die $condition->{operator} . " is not a valid operator for a condition"
			if (!grep {$_ eq $condition->{operator}} @VALID_CONDITIONS);
		$c_elem->setAttribute('operator', $condition->{operator});
	}

	# Now add each element found in the condition.
	foreach my $item (@{$condition->{elements}}) {
		# Is this a field or a condition?
		if (exists($item->{name})) {
			# We have a field.
			$c_elem->appendChild($self->_parse_field($entity, $doc, $item));
		}
		elsif (exists($item->{elements})) {
			# We have a condition.
			$c_elem->appendChild($self->_parse_condition($entity, $doc, $item));
		}
		else {
			# We have an invalid element.
			die "Found an invalid element in query element";
		}
	}

	return $c_elem;
}

sub _parse_field {
	my ($self, $entity, $doc, $field) = @_;

	# Check to see that this entity actually has a field with this name.
	die "Invalid query field " . $field->{name} . " for entity $entity"
		if (!$self->{valid_entities}->{$entity}->{fields}->{$field->{name}}->{IsQueryable});
	my $f_elem = $doc->createElement('field');
	if ($self->{valid_entities}->{$entity}->{fields}->{$field->{name}}->{IsUDF}) {
		$f_elem->setAttribute('udf', 'true');
	}
	$f_elem->appendChild($doc->createTextNode($field->{name}));

	# Go through the expressions.
	foreach my $item (@{$field->{expressions}}) {
		die "Invalid op " . $item->{op} . " in expression"
			if (!grep {$_ eq $item->{op}} @VALID_OPS);
		my $exp = $doc->createElement('expression');
		$exp->setAttribute('op', $item->{op});
		$exp->appendChild($doc->createTextNode($item->{value}));
		$f_elem->appendChild($exp);
	}

	return $f_elem;
}

sub _load_entity_field_info {
	my ($self, $entity) = @_;

	# If we have already loaded information for thsi entity, don't do it a
	# second time.
	if ($self->{valid_entities}->{$entity}->{fields}) {
		return;
	}

	my $soap = $self->{at_soap};

	# Now load the fields.
	my $res = $soap->GetFieldInfo(SOAP::Data->name('psObjectType')->value($entity))->result;
	foreach my $field (@{$res->{Field}}) {
		$self->{valid_entities}->{$entity}->{fields}->{$field->{Name}} = $field;
	}

	# Now load the user derfined fields.
	$res = $soap->getUDFInfo(SOAP::Data->name('psTable')->value($entity))->result;
	if ($res && ref($res) eq 'HASH' && exists($res->{Field}) && ref($res->{Field}) eq 'ARRAY') {
		foreach my $field (@{$res->{Field}}) {
			$self->{valid_entities}->{$entity}->{fields}->{$field->{Name}} = $field;
			$self->{valid_entities}->{$entity}->{fields}->{$field->{Name}}->{IsUDF} = 'true';
		}
	}

	return;
}

sub _get_entity_results {
	my ($result) = @_;
	
	# Make sure we have results to return.
	if (!exists($result->{EntityResults}) || ref($result->{EntityResults}) ne 'HASH' || !exists($result->{EntityResults}->{Entity})) {
		return ();
	}

	my $ents = $result->{EntityResults}->{Entity};

	# Return the actual array instead of an array ref if we got one.
	if (ref($ents) eq 'ARRAY') {
		return (@$ents);
	}

	# Return the item to be assigned as an array.
	return($ents);
}

=head2 update(@entities)

Update the given entities. Entites will be verified prior to submitted to
verify that they can be updated, any fields that are not updatable will 
be ignored. Each object reference needs to be blessed with the entity type
that it is (Account, Contact, etc). Returns the list of entites that were
updated successfully. If an error occurs $@ will be set and undef is returned.
See the section on Entity format for more details on how to format entities to
be accepted by this method.

=cut

sub update {
	my ($self, @entities) = @_;

	die "Missing entity argument in call to query" if (!@entities);

	# Validate that we have the right arguments.
	my @list;
	foreach my $ent (@entities) {
		$self->_validate_entity_argument($ent, 'update');

		# Get the entity information if we don't already have it.
		$self->_load_entity_field_info(blessed($ent));

		# Verify all fields provided are valid.
		$self->_validate_fields($ent);

		push(@list, _entity_as_soap_data($ent));
	}

	my $soap = $self->{at_soap};
	my $res = $soap->update(SOAP::Data->name('Entities')->value(\SOAP::Data->name('array' => @list)))->result;

	if ($res->{Errors} || $res->{ReturnCode} ne '1') {
		# There were errors. Grab the errors and set $@ to their textual values.
		$self->_set_error($res->{Errors}->{ATWSError});
		return undef;
	}

	return _get_entity_results($res);
}

=head2 create(@entities)

Create the given entities. Entites will be verified prior to submitted to
verify that they can be created, any fields that are not creatable will 
be ignored on creation. Each object reference needs to be blessed with the
entity type it is (Account, Contact, etc). Returns the list of entites that
were created successfully. If an error occurs $@ will be set and undef is 
returned. See the section on Entity format for more details on how to format
entities to be accepted by this method.

=cut

sub create {
	my ($self, @entities) = @_;

	die "Missing entity argument in call to query" if (!@entities);

	# Validate that we have the right arguments.
	my @list;
	foreach my $ent (@entities) {
		$self->_validate_entity_argument($ent, 'create');

		# Get the entity information if we don't already have it.
		$self->_load_entity_field_info(blessed($ent));

		# Verify all fields provided are valid.
		$self->_validate_fields($ent);

		push(@list, _entity_as_soap_data($ent));
	}

	my $soap = $self->{at_soap};
	my $res = $soap->create(SOAP::Data->name('Entities')->value(\SOAP::Data->name('array' => @list)))->result;

	if ($res->{Errors} || $res->{ReturnCode} ne '1') {
		# There were errors. Grab the errors and set $@ to their textual values.
		$self->_set_error($res->{Errors}->{ATWSError});
		return undef;
	}

	return _get_entity_results($res);
}

=head2 get_picklist_options($entity, $field)

Return a hash that contains the ID values and options for a picklist field
item. If the field is not a picklist field then an empty hash will be
retruned. The hash is formated with the labels as keys and the values as the
values.

=cut

sub get_picklist_options {
	my ($self, $entity, $field) = @_;

	# See if we have this item cached.
	if (!exists($self->{picklist_values}->{$entity})) {
		$self->{picklist_values}->{$entity} = {};
	}
	if (!exists($self->{picklist_values}->{$entity}->{$field})) {
		# first get the entity information.
		$self->_load_entity_field_info($entity);

		# Next find the field inside this entity.
		my $data = $self->{valid_entities}->{$entity}->{fields}->{$field};

		if (!exists($data->{PicklistValues}) || ref($data->{PicklistValues}) ne 'HASH' || 
			 !exists($data->{PicklistValues}->{PickListValue}) || ref($data->{PicklistValues}->{PickListValue}) ne 'ARRAY') {
			return ();
		}

		my %pick_list;
		foreach my $value (@{$data->{PicklistValues}->{PickListValue}}) {
			$pick_list{$value->{Label}} = $value->{Value};
		}

		$self->{picklist_values}->{$entity}->{$field} = \%pick_list;
	}

	return %{$self->{picklist_values}->{$entity}->{$field}};
}

=head2 create_attachment($attach)

Create a new attachment. Takes a hashref containing Data (the raw data of
the attachment) and Info, which contains the AttachmentInfo. Returns the
new attachment ID on success.

=cut

sub create_attachment {
	my ($self, $attach) = @_;

	# Get the entity information if we don't already have it.
	my $atb = "Attachment";
	my $ati = $atb . "Info";
	$self->_load_entity_field_info($ati);

	# Collect the Info fields
	my $e_info = $self->{valid_entities}->{$ati};
	my @inf;
	foreach my $f_name (keys %{$$attach{Info}}) {
		die "Field $f_name is not a valid field for $ati"
			if (!$e_info->{fields}->{$f_name});
		push @inf, SOAP::Data->name($f_name => $$attach{Info}{$f_name});
	}

	my $data = decode("utf8", $$attach{Data});
	my $res = $self->{at_soap}->CreateAttachment(
	    SOAP::Data->name("attachment" => \SOAP::Data->value(
		SOAP::Data->name(Info => \SOAP::Data->value(@inf))->attr({'xsi:type' => $ati}),
		SOAP::Data->name('Data')->value($data)->type('base64Binary'),
	    ))->attr({'xsi:type' => $atb})); 
	return $res->valueof('//CreateAttachmentResponse/CreateAttachmentResult');
}

=head2 get_attachment($id)

Fetch an attachment; the only argument is the attachment ID. Returns a
hashref of attachment Data and Info, or undef if the specified attachment
doesn't exist or if there is an error.

=cut

sub get_attachment {
	my ($self, $id) = @_;

	# The result is either a hashref with Data and Info or undef
	my $res = $self->{at_soap}->GetAttachment(SOAP::Data->name('attachmentId')->value($id))->result;
	if ($res && %$res && $$res{Data}) {
		# Go ahead and decode it
		$$res{Data} = decode_base64($$res{Data});
	}
	return $res;
}

=head2 delete_attachment($id)

Delete an attachment; the only argument is the attachment ID. Returns true on
success or sets the error string on failure.

=cut

sub delete_attachment {
	my ($self, $id) = @_;

	my $res = $self->{at_soap}->DeleteAttachment(SOAP::Data->name('attachmentId')->value($id))->result;
	if ($res) {
		$self->_set_error($res);
		return 0;
	}
	return 1;
}

=head1 ENTITY FORMAT

The follow section details how to format a variable that contains entity
informaiton. Entites are required for creating and updating items in the
Autotask database.

An entity is a blessed hash reference. It is bless with the name of the type
of entity that it is (Account, Contract, Contact, etc). They keys of the hash
are the field names found in the Autotask entity object. The values are the
corresponding values to be used.

A special key is used for all user defined fields (UserDefinedFields). This
entry contains a hash reference containing one key UserDefinedField. This is
in turn an array reference containing each user defined field. The user
defined field entry looks simliar to this:

  {
    UserDefinedField => [
      {
        Name => "UserDefinedField1",
        Value => "Value for Field"
      },
      {
        Name => "SecondUDF",
        Value => "Value for SecondUDF"
      }
    ]
  }

When used together the entire structure looks something simliar to this:

  bless({
    FieldName1 => "Value for FieldName1",
    Field2 => "Value for Field2",
    UserDefinedFields => {
      UserDefinedField => [
        {
          Name => "UserDefinedField1",
          Value => "Value for Field"
        },
        {
          Name => "SecondUDF",
          Value => "Value for SecondUDF"
        }
      ]
    }
  }, 'EntityName')

Obviously the above is just an example. You will need to look at the actual
fields that are allowed for each Autotask entity. The user defined fields also
will depend on how your instance of Autotask has been configured.

=cut

sub _entity_as_soap_data {
	my ($entity) = @_;

	my @fields = ();
	
	foreach my $f_name (sort(keys(%$entity))) {
		my $field;
		if ($f_name eq 'UserDefinedFields') {
			$field = _udf_as_soap_data($entity->{$f_name});
		} else {
			# Assume non-ASCII is UTF-8
			my $data = decode("utf8", $entity->{$f_name});
			$field = SOAP::Data->name($f_name => $data);
			# SOAP::Lite will treat as binary if UTF-8
			$field->type("string") if ($data ne $entity->{$f_name});
		}
		push @fields, $field;
	}
	
	return SOAP::Data->name(Entity => \SOAP::Data->value(@fields))->attr({'xsi:type' => ref($entity)});
}

sub _udf_as_soap_data {
	my ($udfs) = @_;

	my @fields = ();

	foreach my $field (@{$udfs->{UserDefinedField}}) {
		# Assume non-ASCII is UTF-8
		my $data = decode("utf8", $field);
		my $val = SOAP::Data->value($data);
		# SOAP::Lite will treat as binary if UTF-8
		$data->type("string") if ($data ne $field);
		push(@fields, SOAP::Data->name(UserDefinedField => $val));
	}

	return SOAP::Data->name(UserDefinedFields => \SOAP::Data->value(@fields));
}


sub _set_error {
	my ($self, $errs) = @_;

	$self->{error} = '';

	if (ref($errs) eq 'HASH') {
		$errs = [ $errs ];
	}

	if (ref($errs) eq 'ARRAY') {
		foreach my $err (@$errs) {
			$self->{error} .= "ATWSError: " . $err->{Message} . "\n";
		}
	}

	if (!$self->{error}) {
		$self->{error}= "An unspecified error occured. This usually is due to bad SOAP formating based on the data passed into this method";
	}

	$self->{error} =~ s/\n$//;
}

sub _validate_entity_argument {
	my ($self, $entity, $type) = @_;

	my $flag;
	if ($type eq 'query') {
		$flag = 'CanQuery';
	}
	elsif ($type eq 'create') {
		$flag = 'CanCreate';
	}
	elsif ($type eq 'update') {
		$flag = 'CanUpdate';
	}

	my $e_type = blessed($entity);
	if (!$e_type) {
		if (ref($entity) eq '') {
			# Our entity is actually a type string.
			$e_type = $entity;
		}
		else {
			die "Entity has not been blessed";
		}
	}

	# Are we allowed to query this entity?
	if (!$e_type) {
		die "Missing entity argument in call to $type" 
	}
	elsif ( !grep {$_ eq $e_type} keys(%{$self->{valid_entities}}) ) {
		die "$e_type is not a valid entity. Valid entities are: " . 
				join(', ', keys(%{$self->{valid_entities}}))
	}
	elsif ($self->{valid_entities}->{$e_type}->{$flag} eq 'false') {
		die "Not allowed to $type $e_type" 
	}

	return 1;
}

sub _validate_fields {
	my ($self, $ent) = @_;

	my $type = blessed($ent);
	my $e_info = $self->{valid_entities}->{$type};

	foreach my $f_name (keys(%$ent)) {
		if ($f_name eq 'UserDefinedFields') {
			# Special case field. Look at the actual user defined fields.
			foreach my $udf (@{$ent->{$f_name}->{UserDefinedField}}) {
				die "Field " . $udf->{Name} . " is not a valid $type entity user defined field"
					if (!$e_info->{fields}->{$udf->{Name}});
			}
		}
		else {
			die "Field $f_name is not a valid field for $type entity"
				if (!$e_info->{fields}->{$f_name});
		}
	}

	return 1;
}

=head1 DEPENDENCIES

L<SOAP::Lite>, L<MIME::Base64>

=head1 AUTHOR

Derek Wueppelmann (derek@roaringpenguin.com)

Attachment, UTF-8 support added by Chris Adams (cmadams@hiwaay.net)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Roaring Penguin Software, Inc.

Attachment, UTF-8 support Copyright (c) 2013 HiWAAY Information Services, Inc.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Autotask (tm) is a trademark of Autotask.

=cut

1;
