# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Workflow-XPDL.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
use Data::Dumper;
BEGIN { use_ok('Workflow::XPDL') };

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $oo_xpdl = Workflow::XPDL->new(xml_file => 't/workflow.xml');

my $is_valid_workflow_result = $oo_xpdl->is_valid_workflow('1');
ok($is_valid_workflow_result eq 0, 'is_valid_workflow');

my (%headerresult) = $oo_xpdl->header_info();
my %headerexpected =  (
        'Created' => '6/18/2002 5:27:17 PM',
        'Vendor' => 'XYZ, Inc',
        'XPDLVersion' => '0.09'
    );
is_deeply(\%headerresult, \%headerexpected);

$oo_xpdl->workflow_id('1');

my @impl_result = $oo_xpdl->get_imp_details('58');
my @impl_expected = [ 'No', '', '' ];
is_deeply(\@impl_result, \@impl_expected, 'implementations_1');

@impl_result = $oo_xpdl->get_imp_details('17');
@impl_expected = [ 'Tool', 'transformData', 'APPLICATION' ];
is_deeply(\@impl_result, \@impl_expected, 'implementations_2');

@impl_result = $oo_xpdl->get_imp_details('11');
@impl_expected = [ 'SubFlow', '2', 'ASYNCHR' ];
is_deeply(\@impl_result, \@impl_expected, 'implementations_3');

@impl_result = $oo_xpdl->get_imp_details('12');
@impl_expected = [ 'NULL', '', '' ];
is_deeply(\@impl_result, \@impl_expected, 'implementations_4');

$oo_xpdl->application_id('transformData');
my %app_data_result = $oo_xpdl->get_app_datatypes('transformData');
my %app_data_expected = (
        'orderInfo' => ['2', 'OUT', 'DeclaredType', 'Order'],
        'orderStringIn' => ['1', 'IN', 'BasicType', 'STRING'] 
    );
is_deeply(\%app_data_result, \%app_data_expected, 'datatypes1');


my %transition_result = $oo_xpdl->get_transition_ids('1');
my %transition_expected = ( 
  '22' => {
    'transition_to_id' => '12',
    'transition_condition' => 'status == "Valid Data"'
  },
  'trans_exist' => 'TRUE',
  '23' => {
    'transition_to_id' => '39',
    'transition_condition' => 'status == "Invalid Data"'
  },
  'restriction_type' => 'XOR',
);

is_deeply(\%transition_result, \%transition_expected, 'check_transitions_1');

%transition_result = $oo_xpdl->get_transition_ids('5');
%transition_expected = ( 
  'trans_exist' => 'TRUE',
  '20' => {
    'transition_to_id' => '17',
    'transition_condition' => 'NULL'
  },
  'restriction_type' => 'NULL',
);
is_deeply(\%transition_result, \%transition_expected, 'check_transitions_2');

%transition_result = $oo_xpdl->get_transition_ids('6');
%transition_expected = ( 
  'trans_exist' => 'FALSE'
);
is_deeply(\%transition_result, \%transition_expected, 'check_transitions_3');



