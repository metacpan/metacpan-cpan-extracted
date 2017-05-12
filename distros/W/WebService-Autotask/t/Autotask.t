use strict;
use warnings;

no warnings qw(redefine);

package Autotask::Test;
use base qw(Test::Class);
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use WebService::Autotask;
use XML::LibXML;

sub make_mock_object {
	my $mo = Test::MockObject->new();

	# Mock the methods that are called during construction.
	$mo->mock('uri' => sub {
			my ($self, $uri) = @_;
			return $self;
		});
	$mo->mock('on_action' => sub {
			my ($self, $action) = @_;
			return $self;
		});
	$mo->mock('proxy' => sub {
			my ($self, $proxy, %args) = @_;

			my $username = $args{credentials}->[2];
			my $password = $args{credentials}->[3];
			if ($username eq 'username' && $password ne 'password') {
				die "401 Access	Denied: Invalid Username	or Password.";
			}
			return $self;
		});
	$mo->mock('result' => sub {
			my ($self) = @_;

			return $self->{'result'};
		});
	$mo->mock('create_error' => sub {
			my ($self, $err) = @_;

			$self->{result} = {
				ErrorCode => -1,
				ReturnCode => -1,
				Errors => {
					ATWSError => {
						Message => $err
					}
				}
			};

			return $self;
		});
	$mo->mock('set_account' => sub {
			my ($self) = @_;

			$self->{result} = {
				ReturnCode => 1,
				EntityResults => {
					Entity => [
						bless({
							'CreateDate' => '2009-01-28T11:58:40.0000000-05:00',
							'AccountName' => 'Testing Company Name',
							'AccountType' => '1',
							'id' => '123456',
							'UserDefinedFields' => {
								'UserDefinedField' => [
									{
										'Name' => 'Email List'
									},
									{
										'Name' => 'Number of Employees'
									},
								]
							},
							'Phone' => '(800) 555-1234',
						}, 'Account')
					]
				}
			};

			return $self;
		});

	# Mock the methods that are going to be used during the actual running of
	# the WebService::Autotask module. If arguments are to be passed these methods should
	# validate the arguments and then return valid values.
	#  getZoneInfo(username)
	$mo->mock('getZoneInfo' => sub {
			my ($self, $arg) = @_;

			if (!$arg->isa('SOAP::Data') || !$arg->name() eq 'UserName' || !ref($arg->value()) eq '') {
				# Set and return an error.
				return $self->create_error("Invalid argument in call to getZoneInfo");
			}
			if ($arg->value() ne 'username') {
				return $self->create_error("Could not find correct Autotask Proxy for user: " . $arg->value);
			}

			$self->{result} = {
				URL => 'https://webservicesg1.autotask.net/ATServices/1.4/atws.asmx',
				ErrorCode => 0
			};

			return $self;
		});
	#  GetEntityInfo()
	$mo->mock('GetEntityInfo' => sub {
			my ($self) = @_;

			$self->{result} = {
				EntityInfo => [
					{
						'CanCreate' => 'true',
						'CanDelete' => 'false',
						'CanUpdate' => 'true',
						'HasUserDefinedFields' => 'true',
						'CanQuery' => 'true',
						'Name' => 'Account'
					},
					{
						'CanCreate' => 'false',
						'CanDelete' => 'false',
						'CanUpdate' => 'false',
						'HasUserDefinedFields' => 'true',
						'CanQuery' => 'false',
						'Name' => 'Contact'
					}
				],
			};

			return $self;
		});
	#  GetFieldInfo(SOAP::Data object)
	$mo->mock('GetFieldInfo' => sub {
			my ($self, $arg) = @_;

			# Validate the argument passed in.
			if (!$arg->isa('SOAP::Data') || !$arg->name() eq 'psObjectType' || !ref($arg->value()) eq '') {
				# Set and return an error.
				return $self->create_error("Invalid argument in call to GetFieldInfo");
			}

			$self->{result} = {
				'Field' => [
					{
						'IsReadOnly' => 'true',
						'Label' => 'Account ID',
						'ReferenceEntityType' => '',
						'IsQueryable' => 'true',
						'PicklistParentValueField' => '',
						'Length' => '0',
						'Type' => 'long',
						'IsPickList' => 'false',
						'Name' => 'id',
						'IsRequired' => 'true',
						'IsReference' => 'false'
					},
					{
						'IsReadOnly' => 'false',
						'Label' => 'Account Name',
						'ReferenceEntityType' => '',
						'IsQueryable' => 'true',
						'PicklistParentValueField' => '',
						'Length' => '100',
						'Type' => 'string',
						'IsPickList' => 'false',
						'Name' => 'AccountName',
						'IsRequired' => 'true',
						'IsReference' => 'false'
					},
					{
						'IsReadOnly' => 'false',
						'Label' => 'Phone',
						'ReferenceEntityType' => '',
						'IsQueryable' => 'true',
						'PicklistParentValueField' => '',
						'Length' => '25',
						'Type' => 'string',
						'IsPickList' => 'false',
						'Name' => 'Phone',
						'IsRequired' => 'true',
						'IsReference' => 'false'
					},
					{
						'PicklistValues' => {
							'PickListValue' => [
								{
									'Value' => '1',
									'SortOrder' => '1',
									'IsDefaultValue' => 'false',
									'parentValue' => '',
									'Label' => 'Customer'
								},
								{
									'Value' => '2',
									'SortOrder' => '2',
									'IsDefaultValue' => 'false',
									'parentValue' => '',
									'Label' => 'Lead'
								},
							]
						},
						'IsReadOnly' => 'false',
						'Label' => 'Account Type',
						'ReferenceEntityType' => '',
						'IsQueryable' => 'true',
						'PicklistParentValueField' => '',
						'Length' => '0',
						'Type' => 'short',
						'IsPickList' => 'true',
						'Name' => 'AccountType',
						'IsRequired' => 'true',
						'IsReference' => 'false'
					},
					{
						'IsReadOnly' => 'true',
						'Label' => 'Create Date',
						'ReferenceEntityType' => '',
						'IsQueryable' => 'true',
						'PicklistParentValueField' => '',
						'Length' => '0',
						'Type' => 'datetime',
						'IsPickList' => 'false',
						'Name' => 'CreateDate',
						'IsRequired' => 'false',
						'IsReference' => 'false'
					},
				]
			};

			return $self;
		});
	#  getUDFInfo(SOAP::Data object)
	$mo->mock('getUDFInfo' => sub {
			my ($self, $arg) = @_;

			# Validate the argument passed in.
			if (!$arg->isa('SOAP::Data') || !$arg->name() eq 'psTable' || !ref($arg->value()) eq '') {
				# Set and return an error.
				return $self->create_error("Invalid argument in call to GetFieldInfo");
			}

			$self->{result} = {
				'Field' => [
					{
						'IsReadOnly' => 'false',
						'Label' => 'Email List',
						'IsQueryable' => 'true',
						'Length' => '1024',
						'Type' => 'string',
						'DefaultValue' => '',
						'IsPickList' => 'false',
						'Name' => 'Email List',
						'IsRequired' => 'false',
						'IsReference' => 'false'
					},
					{
						'IsReadOnly' => 'false',
						'Label' => 'Number of Employees',
						'IsQueryable' => 'true',
						'Length' => '0',
						'Type' => 'double',
						'DefaultValue' => '',
						'IsPickList' => 'false',
						'Name' => 'Number of Employees',
						'IsRequired' => 'false',
						'IsReference' => 'false'
					}
				]
			};

			return $self;
		});
	#  query(SOAP::Data object)
	$mo->mock('query' => sub {
			my ($self, $arg) = @_;

			# Validate the input argument.
			if (!$arg->isa('SOAP::Data') || !$arg->name() eq 'sXML' || ref($arg->value()) ne '') {
				# Set and return an error.
				return $self->create_error("Invalid argument in call to query");
			}

			return $self->set_account();
		});
	#  update(SOAP::Data object)
	$mo->mock('update' => sub {
			my ($self, $arg) = @_;

			# Validate the input argument.
			if (!$arg->isa('SOAP::Data') || !$arg->name() eq 'Entites' || !ref($arg->value()) eq 'ARRAY') {
				# Set and return an error.
				return $self->create_error("Invalid argument in call to update");
			}

			return $self->set_account();
		});
	#  create(SOAP::Data object)
	$mo->mock('create'=> sub {
			my ($self, $arg) = @_;

			# Validate the input argument.
			if (!$arg->isa('SOAP::Data') || !$arg->name() eq 'Entities' || !ref($arg->value()) eq 'ARRAY') {
				# Set and return an error.
				return $self->create_error("Invalid argument in call to create");
			}

			return $self->set_account();
		});

	return $mo;
}

# Now override the SOAP::Lite methods.
*SOAP::Lite::uri = sub {
	return make_mock_object(@_);
};
*SOAP::Lite::on_action = sub {
	return make_mock_object(@_);
};
*SOAP::Lite::proxy = sub {
	return make_mock_object(@_);
};

# Run the tests
Test::Class->runtests;

sub t00_test_at_object_creation : Test(20) {
	my ($self) = @_;

	my $at;

	# First one should fail.
	eval{ $at = WebService::Autotask->new() };
	like($@, qr/No username provided in call to new/, "Missing Username in Autotask creation");

	# Adding a username will still fail.
	eval{ $at = WebService::Autotask->new({username => "username"}) };
	like($@, qr/No password provided in call to new/, "Missing password in Autotask creation");

	eval{ $at = WebService::Autotask->new({username => "username", password => "fake"}) };
	like($@, qr/401 Access\s+Denied/, "Username or password were incorrect");

	eval{ $at = WebService::Autotask->new({username => "invalid", password => "password"}) };
	like($@, qr/Could not find correct Autotask Proxy for user: invalid/, "User does not exist");

	eval{ $at = WebService::Autotask->new({username => 'username', password => 'password'}) };
	is(ref($at), 'WebService::Autotask', "Got valid WebService::Autotask object");

	# Validate the object.
	ok($at->isa('WebService::Autotask'), "Returned object is an WebService::Autotask object");
	is(ref($at->{valid_entities}), 'HASH', "object's valid_entites is a hash");

	my $entities = $at->{valid_entities};
	is(scalar(keys(%$entities)), 2, "Only two valid entities found");
	is(ref($entities->{Account}), 'HASH', 'Found Account Entity');
	my $ent = $entities->{Account};
	is($ent->{CanCreate}, 'true', "Can Create Accounts");
	is($ent->{CanUpdate}, 'true', "Can Update Accounts");
	is($ent->{CanDelete}, 'false', "Can't Delete Accounts");
	is($ent->{CanQuery}, 'true', "Can Query Accounts");
	is($ent->{HasUserDefinedFields}, 'true', "Account has user defined fields.");

	is(ref($entities->{Contact}), 'HASH', 'Found Contact Entity');
	$ent = $entities->{Contact};
	is($ent->{CanCreate}, 'false', "Can Create Contacts");
	is($ent->{CanUpdate}, 'false', "Can Update Contacts");
	is($ent->{CanDelete}, 'false', "Can't Delete Contacts");
	is($ent->{CanQuery}, 'false', "Can Query Contacts");
	is($ent->{HasUserDefinedFields}, 'true', "Contact has user defined fields.");
}

sub t01_test_udf_conversion_to_soap : Test(17) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});
	
	# Create the UDF reference.
	my $udf = {
		UserDefinedField => [
			{
				Name => 'Email List',
				Value => 'email@example.com'
			},
			{
				Name => 'Number of Employees',
				Value => 5
			}
		]
	};

	# Now we want to convert this.
	my $sd = WebService::Autotask::_udf_as_soap_data($udf);

	# Check that we got a soap object back.
	ok($sd->isa('SOAP::Data'), "We got a SOAP::Data object back");

	# Verify the contents of this SOAP::Data object.
	is($sd->name, "UserDefinedFields", "Top level element is UserDefinedFields");
	is(ref($sd->value), 'REF', "Top level element contains a REF");

	# Container
	my $elem = ${$sd->value};
	ok($elem->isa('SOAP::Data'), "Container is a reference to a SOAP:Data object");
	my @itms = $elem->value;
	is(scalar(@itms), 2, "Two UDF items found");

	# First Item.
	my $itm = $itms[0];
	ok($itm->isa('SOAP::Data'), "First element is a SOAP::Data object");
	is($itm->name, 'UserDefinedField', "Element is a UserDefinedField");
	ok($itm->value->isa('SOAP::Data'), "Element value is a SOAP::Data object");
	is(ref($itm->value->value), 'HASH', "Value is a HASH");
	is($itm->value->value->{Name}, "Email List", "Found Email List item");
	is($itm->value->value->{Value}, 'email@example.com', 'Found Email List value email@example.com');

	# Second Item
	$itm = $itms[1];
	ok($itm->isa('SOAP::Data'), "First element is a SOAP::Data object");
	is($itm->name, 'UserDefinedField', "Element is a UserDefinedField");
	ok($itm->value->isa('SOAP::Data'), "Element value is a SOAP::Data object");
	is(ref($itm->value->value), 'HASH', "Value is a HASH");
	is($itm->value->value->{Name}, "Number of Employees", "Found Number of Employees item");
	is($itm->value->value->{Value}, '5', 'Found Number of Employees value 5');
}

sub t02_test_entity_object_conversion_to_soap : Test(22) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});
	
	# Create the entity reference.
	my $ent = {
		id => '12345',
		AccountName => 'Testing Name',
		Phone => '800-555-1234',
		AccountType => '1',
		CreateDate => '2010-01-01',
		UserDefinedFields => {
			UserDefinedField => [
				{
					Name => 'Email List',
					Value => 'email@example.com'
				},
				{
					Name => 'Number of Employees',
					Value => 5
				}
			]
		}
	};

	# Now we want to convert this.
	my $sd = WebService::Autotask::_entity_as_soap_data($ent);

	# Check that we got a soap object back.
	ok($sd->isa('SOAP::Data'), "We got a SOAP::Data object back");

	# Verify the contents of this SOAP::Data object.
	is($sd->name, "Entity", "Top level element is Entity");
	is(ref($sd->value), 'REF', "Top level element contains a REF");

	# Container
	my @itms = ${$sd->value}->value;
	is(scalar(@itms), 6, "Six Fields found");

	# First Item.
	my $itm = $itms[0];
	ok($itm->isa('SOAP::Data'), "First element is a SOAP::Data object");
	is($itm->name, 'AccountName', "Element is a AccountName");
	is($itm->value, 'Testing Name',  "AccountName is 'Testing Name'");
	# Second Item.
	$itm = $itms[1];
	ok($itm->isa('SOAP::Data'), "First element is a SOAP::Data object");
	is($itm->name, 'AccountType', "Element is a AccountType");
	is($itm->value, '1',  "AccountType is '1'");
	# Third Item.
	$itm = $itms[2];
	ok($itm->isa('SOAP::Data'), "First element is a SOAP::Data object");
	is($itm->name, 'CreateDate', "Element is a CreateDate");
	is($itm->value, '2010-01-01',  "CreateDate is '2010-01-01'");
	# Fourth Item.
	$itm = $itms[3];
	ok($itm->isa('SOAP::Data'), "First element is a SOAP::Data object");
	is($itm->name, 'Phone', "Element is a Phone");
	is($itm->value, '800-555-1234',  "Phone is '800-555-1234'");
	# Fifth Item
	$itm = $itms[4];
	ok($itm->isa('SOAP::Data'), "First element is a SOAP::Data object");
	is($itm->name, 'UserDefinedFields', "Element is a UserDefinedFields.");
	is(ref($itm->value), 'REF', "UserDefinedFields is a REF");
	#  The internals of this element has already a test written for it.
	$itm = $itms[5];
	ok($itm->isa('SOAP::Data'), "First element is a SOAP::Data object");
	is($itm->name, 'id', "Element is a id");
	is($itm->value, '12345',  "id is '12345'");
}

sub t03_test_error_setting : Test(3) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});

	# Test without any error provided.
	$at->_set_error();
	is($at->{error}, "An unspecified error occured. This usually is due to bad SOAP formating based on the data passed into this method",
		"Error set correclty when none specified");
	
	# Test when only one error provided.
	my $errs = {
		Message => "Test Error Message"
	};
	$at->_set_error($errs);
	is($at->{error}, "ATWSError: Test Error Message", "One error message set correctly");

	# Test when multiple errors provided.
	$errs = [
		{
			Message => "Test Error 1"
		},
		{
			Message => "Test Error 2"
		}
	];
	$at->_set_error($errs);
	is($at->{error}, "ATWSError: Test Error 1\nATWSError: Test Error 2", "Two error messages set correctly");
}

sub t04_test_loading_entity_field_info : Test(37) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});

	# Get the entity field info.
	$at->_load_entity_field_info('Account');
	my $fields = $at->{valid_entities}->{Account}->{fields};
	ok($fields, 'The fields for Account have been set');
	is(ref($fields), 'HASH', "The fields are a hash ref");

	# Validate the fields that should be there.
	is(scalar(keys(%$fields)), 7, 'There are 7 fields found');	
	# Do a deep analysis of one regular field.
	my $field = $fields->{AccountName};
	ok($field, "AccountName field exists");
	is(ref($field), 'HASH', "AccountName field is a hash");
	is($field->{IsReadOnly}, 'false', "AccountName IsReadOnly is false");
	is($field->{Label}, 'Account Name', "AccountName Label is Account Name");
	is($field->{IsQueryable}, 'true', "AccountName IsQueryable is true");
	is($field->{ReferenceEntityType}, '', "AccountName ReferenceEntityType is ''");
	is($field->{PicklistParentValueField}, '', "AccountName PicklistParentValueField is ''");
	is($field->{Length}, '100', "AccountName Length is '100'");
	is($field->{Type}, 'string', "AccountName Type is 'string'");
	is($field->{IsPickList}, 'false', "AccountName IsPickList is false");
	is($field->{IsReference}, 'false', "AccountName IsReference is false");
	is($field->{IsRequired}, 'true', "AccountName IsRequired is true");
	
	# Do a deep analysis of one UDF.
	$field = $fields->{'Email List'};
	ok($field, "Email List field exists");
	is(ref($field), 'HASH', "Email List field is a hash");
	is($field->{IsReadOnly}, 'false', "Email List IsReadOnly is false");
	is($field->{Label}, 'Email List', "Email List Label is Email List");
	is($field->{IsQueryable}, 'true', "Email List IsQueryable is true");
	is($field->{ReferenceEntityType}, undef, "Email List ReferenceEntityType is ''");
	is($field->{PicklistParentValueField}, undef, "Email List PicklistParentValueField is ''");
	is($field->{Length}, '1024', "Email List Length is '100'");
	is($field->{Type}, 'string', "Email List Type is 'string'");
	is($field->{IsPickList}, 'false', "Email List IsPickList is false");
	is($field->{IsReference}, 'false', "Email List IsReference is false");
	is($field->{IsRequired}, 'false', "Email List IsRequired is true");

	# Make sure the rest of the fields are there.
	$field = $fields->{'Number of Employees'};
	ok($field, "Number of Employees field exists");
	is(ref($field), 'HASH', "Number of Employees field is a hash");
	$field = $fields->{id};
	ok($field, "id field exists");
	is(ref($field), 'HASH', "id field is a hash");
	$field = $fields->{Phone};
	ok($field, "Phone field exists");
	is(ref($field), 'HASH', "Phone field is a hash");
	$field = $fields->{AccountType};
	ok($field, "AccountType field exists");
	is(ref($field), 'HASH', "AccountType field is a hash");
	$field = $fields->{CreateDate};
	ok($field, "CreateDate field exists");
	is(ref($field), 'HASH', "CreateDate field is a hash");
}

sub t05_test_parsing_queryxml_field : Test(4) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});
	$at->_load_entity_field_info('Account');

	my $xml;
	my $doc = XML::LibXML::Document->new();
	$doc->setDocumentElement($doc->createElement('queryxml'));

	# Try a field that doesn't exist.
	my $field = {
		name => 'InvalidField',
		expressions => []
	};
	eval {$xml = $at->_parse_field('Account', $doc, $field)->toString()};
	like($@, qr/Invalid query field InvalidField for entity Account/, "Used an invalid field");

	# Try with an invalid operation.
	$field = {
		name => 'AccountName', 
		expressions => [
			{
				op => 'NoOp',
				value => 'Nothing'
			}
		]
	};
	eval {$xml = $at->_parse_field('Account', $doc, $field)->toString()};
	like($@, qr/Invalid op NoOp in expression/, "Used an invalid operation");

	# Try a basic operation.
	$field = {
		name => 'AccountName', 
		expressions => [
			{
				op => 'BeginsWith',
				value => 'b'
			}
		]
	};
	eval {$xml = $at->_parse_field('Account', $doc, $field)->toString()};
	is($xml, '<field>AccountName<expression op="BeginsWith">b</expression></field>', "Simple field expression created");

	# Try with two operations.
	$field = {
		name => 'AccountName', 
		expressions => [
			{
				op => 'BeginsWith',
				value => 'b'
			},
			{
				op => 'EndsWith',
				value => 'a'
			}
		]
	};
	eval {$xml = $at->_parse_field('Account', $doc, $field)->toString()};
	is($xml, '<field>AccountName<expression op="BeginsWith">b</expression><expression op="EndsWith">a</expression></field>', "Double expression field created");
}

sub t06_test_parsing_queryxml_condition : Test(4) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});
	$at->_load_entity_field_info('Account');

	my $xml;
	my $doc = XML::LibXML::Document->new();
	$doc->setDocumentElement($doc->createElement('queryxml'));

	# Try an operator that doesn't exist.
	my $cond = {
		operator => 'NONE',
		elements => []
	};
	eval {$xml = $at->_parse_condition('Account', $doc, $cond)->toString()};
	like($@, qr/NONE is not a valid operator for a condition/, "Used an invalid operator");

	# Try a condition without an operator
	$cond = {
		elements => [
			{
				name => 'AccountName',
				expressions => [
					{
						op => 'BeginsWith',
						value => 'b'
					}
				]
			}
		]
	};
	eval {$xml = $at->_parse_condition('Account', $doc, $cond)->toString()};
	is($xml, '<condition><field>AccountName<expression op="BeginsWith">b</expression></field></condition>', "Operatorless condition created");

	# Try a simple condition with only a field.
	$cond = {
		operator => 'OR',
		elements => [
			{
				name => 'AccountName',
				expressions => [
					{
						op => 'BeginsWith',
						value => 'b'
					}
				]
			}
		]
	};
	eval {$xml = $at->_parse_condition('Account', $doc, $cond)->toString()};
	is($xml, '<condition operator="OR"><field>AccountName<expression op="BeginsWith">b</expression></field></condition>', "Simple condition created");

	# Try a complex nested condition.
	$cond = {
		operator => 'OR',
		elements => [
			{
				operator => 'AND',
				elements => [
					{
						name => 'AccountName',
						expressions => [
							{
								op => 'BeginsWith',
								value => 'b'
							}
						]
					}
				]
			}
		]
	};
	eval {$xml = $at->_parse_condition('Account', $doc, $cond)->toString()};
	is($xml, '<condition operator="OR"><condition operator="AND"><field>AccountName<expression op="BeginsWith">b</expression></field></condition></condition>', "Simple condition created");
}

sub t07_test_creating_query_xml : Test(1) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});
	$at->_load_entity_field_info('Account');

	my $xml;

	# Create the QueryXML.
	my $query = [
		{
			name => 'AccountName',
			expressions => [
				{
					op => 'BeginsWith',
					value => 'c'
				}
			]
		},
		{
			operator => 'OR',
			elements => [
				{
					operator => 'AND',
					elements => [
						{
							name => 'AccountName',
							expressions => [
								{
									op => 'BeginsWith',
									value => 'b'
								}
							]
						}
					]
				}
			]
		}
	];
	eval {$xml = $at->_create_query_xml('Account', $query)};
	is($xml, '<queryxml><entity>Account</entity><query><field>AccountName<expression op="BeginsWith">c</expression></field><condition operator="OR"><condition operator="AND"><field>AccountName<expression op="BeginsWith">b</expression></field></condition></condition></query></queryxml>', "QueryXML Cretaed correctly") or diag($@);
}

sub t08_test_entity_validation : Test(12) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});

	# Test the different error conditions:
	eval {$at->_validate_entity_argument('', 'query')};
	like($@, qr/Missing entity argument in call to query/, "Got missing entity argument using an empty string");
	eval {$at->_validate_entity_argument({}, 'query')};
	like($@, qr/Entity has not been blessed/, "Got unblessed enttiy error using an unblessed hashref");
	eval {$at->_validate_entity_argument('Invalid', 'query')};
	like($@, qr/Invalid is not a valid entity/, "Got invalid entity with a string value for the entity name");
	eval {$at->_validate_entity_argument(bless({}, 'Invalid'), 'query')};
	like($@, qr/Invalid is not a valid entity/, "Got invalid entity with a blessed hash for the entity");
	eval {$at->_validate_entity_argument('Contact', 'query')};
	like($@, qr/Not allowed to query Contact/, "Got correct error messag when trying to query a Contact using a string value");
	eval {$at->_validate_entity_argument(bless({}, 'Contact'), 'query')};
	like($@, qr/Not allowed to query Contact/, "Got correct error messag when trying to query a Contact using a blessed hashref");


	# Finally test success cases:
	ok($at->_validate_entity_argument('Account', 'query'), "Querying Account successful.");
	ok($at->_validate_entity_argument('Account', 'create'), "Creating Account successful.");
	ok($at->_validate_entity_argument('Account', 'update'), "Updating Account successful.");
	ok($at->_validate_entity_argument(bless({}, 'Account'), 'query'), "Querying Account successful.");
	ok($at->_validate_entity_argument(bless({}, 'Account'), 'create'), "Creating Account successful.");
	ok($at->_validate_entity_argument(bless({}, 'Account'), 'update'), "Updating Account successful.");
}

sub t09_test_field_validation : Test(3) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});
	$at->_load_entity_field_info('Account');

	eval{
		$at->_validate_fields(bless({
			Invalid => ''
		}, 'Account'));
	};
	like($@, qr/Field Invalid is not a valid field for Account/, "Got invalid field error for field Invalid");
	eval{
		$at->_validate_fields(bless({
			UserDefinedFields => {
				UserDefinedField => [{Name => 'Invalid'}]
			}
		}, 'Account'));
	};
	like($@, qr/Field Invalid is not a valid Account entity user defined field/, "Got invalid field error for user defined field Invalid");
	
	ok($at->_validate_fields(bless({
			AccountName => 'Name', 
			UserDefinedFields => {
				UserDefinedField => [{Name => 'Email List'}]
			}
		}, 'Account')), "Provided fields validate correctly");
}

sub t10_test_query : Test(5) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});

	# Try with missing arguments.
	eval{$at->query()};
	like($@, qr/Missing entity argument in call to query/, "Missing entity argument");
	eval{$at->query({entity => 'Account'})};
	like($@, qr/Missing query argument in call to query/, "Missing query argument");
	eval{$at->query({entity => 'Missing', query =>[]})};
	like($@, qr/Missing is not a valid entity. Valid entities are:/, "Missing a valid entity");

	eval{$at->query({entity => "Contact", query => []})};
	like($@, qr/Not allowed to query Contact/, "Not allowed to query entity Contact");

	my @accts = $at->query({
		entity => 'Account',
		query => [
			{
				name => 'AccountName',
				expressions => [{op => 'BeginsWith', value => 'b'}]
			},
		]
	});
	is($accts[0]->{AccountName}, "Testing Company Name", "Got Testing Company Name") or diag($@);
}

sub t11_test_update : Test(7) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});

	# Try with missing arguments.
	eval{$at->update()};
	like($@, qr/Missing entity argument in call to query/, "Missing entity argument");
	eval{$at->update({})};
	like($@, qr/Entity has not been blessed/, "Unblessed entity failed.");
	eval{$at->update(bless({}, 'Missing'))};
	like($@, qr/Missing is not a valid entity. Valid entities are:/, "Missing a valid entity");

	eval{$at->update(bless({}, 'Contact'))};
	like($@, qr/Not allowed to update Contact/, "Not allowed to update entity Contact");

	# Bad field
	my $acct = bless({
			BadField => 'value'
		}, 'Account');
	eval{$at->update($acct)};
	like($@, qr/Field BadField is not a valid field for Account entity/, "Using a bad field failed");

	# Bad UDF
	$acct = bless({
			UserDefinedFields => {
				UserDefinedField => [
					{
						Name => 'BadUDF', 
						value => 'value'
					}
				]
			}
		}, 'Account');
	eval{$at->update($acct)};
	like($@, qr/Field BadUDF is not a valid Account entity user defined field/, "Using a bad UDF failed");

	$acct = bless({
			AccountName => 'Testing Company Name'
		}, 'Account');
	my @accts = $at->update($acct);
	is($accts[0]->{AccountName}, "Testing Company Name", "Got Testing Company Name") or diag($@);
}

sub t12_test_create : Test(7) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});

	# Try with missing arguments.
	eval{$at->create()};
	like($@, qr/Missing entity argument in call to query/, "Missing entity argument");
	eval{$at->create({})};
	like($@, qr/Entity has not been blessed/, "Unblessed entity failed.");
	eval{$at->create(bless({}, 'Missing'))};
	like($@, qr/Missing is not a valid entity. Valid entities are:/, "Missing a valid entity");

	eval{$at->create(bless({}, 'Contact'))};
	like($@, qr/Not allowed to create Contact/, "Not allowed to create entity Contact");

	# Bad field
	my $acct = bless({
			BadField => 'value'
		}, 'Account');
	eval{$at->create($acct)};
	like($@, qr/Field BadField is not a valid field for Account entity/, "Using a bad field failed");

	# Bad UDF
	$acct = bless({
			UserDefinedFields => {
				UserDefinedField => [
					{
						Name => 'BadUDF', 
						value => 'value'
					}
				]
			}
		}, 'Account');
	eval{$at->create($acct)};
	like($@, qr/Field BadUDF is not a valid Account entity user defined field/, "Using a bad UDF failed");

	$acct = bless({
			AccountName => 'Testing Company Name'
		}, 'Account');
	my @accts = $at->create($acct);
	is($accts[0]->{AccountName}, "Testing Company Name", "Got Testing Company Name") or diag($@);
}

sub t13_test_get_picklist_options : Test(3) {
	my ($self) = @_;

	my $at = WebService::Autotask->new({username => 'username', password => 'password'});

	# Test that we pull a cached result.
	$at->{picklist_values}->{'Account'} = {
		field => { item => 1}
	};

	my %list = $at->get_picklist_options('Account', 'field');
	is($list{item}, 1, "Got correct cached picklist");

	# Remove cached entry.
	delete($at->{picklist_values}->{'Account'});

	%list = $at->get_picklist_options('Account', 'AccountType');
	is($list{Customer}, 1, "Got correct customer id");
	is($list{Lead}, 2, "Got correct lead id");
}

1;
