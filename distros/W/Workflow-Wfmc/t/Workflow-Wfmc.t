# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Workflow-Wfmc.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Workflow::Wfmc') };

#########################

use strict;
use warnings;
use XML::Simple qw|XMLin XMLout|;
use Data::Dumper;
use XML::XPath::XMLParser;
use Workflow::Wfmc;                                       # my workflow class
use Getopt::Long;
####################### Usage instruction ##########################
our ($opt_help,$opt_file,$opt_conf,$opt_ordertype,$opt_ordern,$opt_actno,$opt_total);
my $num_arg = $#ARGV;
Getopt::Long::Configure("bundling");
GetOptions("file|f=s", "conf|c=s","ordertype|t=s","ordern|n=s","actno|a=s","total|l=s", "help|?");
#if ($num_arg < 0 || defined($opt_help)) {
if (0) { # substitute this line withe the above when run directly
   printf <<'END';
Usage: Runable.pm [OPTIONS]
Exchange orders between nodes and update DB.
  -f,  --file="/path/to/order.xml"                      order file path
  -c,  --conf="C:/kai/PERL/Kai-Workflow/workflow.xml"   configuration file path
  -t,  --ordertype="PO"                                 order type "PO" or "Credit"
  -n,  --ordern="EP100"                                 order number, e.g., "EP100"
  -a,  --actno="10100126"                               account number, e.g., "EP100"
  -l,  --total="200"                                    total amount in EURO, e.g., 120
       --help                                           display this help and exit
END
   exit(0);
}

####### START: arguments #######
my $order_file  = defined($opt_file)         ? $opt_file         :'./lib/Workflow/Wfmc/Test/sample_order.xml'; # defaults to Kai's setup
my $conf_file   = defined($opt_conf)         ? $opt_conf         :'./lib/Workflow/Wfmc/Test/workflow.xml'; # defaults to Kai's setup
my $order_type  = defined($opt_ordertype)    ? $opt_ordertype    :'PO';         # defaults to Kai's setup
my $order_ordern= defined($opt_ordern)       ? $opt_ordern       :'EP100';      # defaults to Kai's setup
my $order_actno = defined($opt_actno)        ? $opt_actno        :'10100126';   # defaults to Kai's setup
my $order_total = defined($opt_total)        ? $opt_total        :'200';        # defaults to Kai's setup
####### END: arguments #########
open(IN,"<$order_file");
my $doc = do{local $/;<IN>;};                                                        # slurp an approvable
close(IN);
my $init_act_id = {                                                                # specify starting states for each workflow
        'EOrder'      => [1],
        'FillOrder'   => [1],
        'CreditCheck' => [1],
};
my $wfp_id = {                                                                        # These are the workflow process IDs
        'EOrder'      => "1",
        'FillOrder'   => "2",
        'CreditCheck' => "3",
};
my $cust_lib =                                                                        # list customized libraries used to handle call-backs
{
        'EOrder'          =>'Workflow::Wfmc::Test::Order',                                # class to handle EOrder workflow
        'FillOrder'       =>'Workflow::Wfmc::Test::Order',                                # class to handle FillOrder workflow
        'CreditCheck'     =>'Workflow::Wfmc::Test::Order',                                # class to handle Credit workflow
};
my $wf = {                                                                        # create workflow objects first
        'EOrder'      => new Workflow::Wfmc('Id' => $wfp_id->{'EOrder'}),
        'FillOrder'   => new Workflow::Wfmc('Id' => $wfp_id->{'FillOrder'}),
        'CreditCheck' => new Workflow::Wfmc('Id' => $wfp_id->{'CreditCheck'}),
};
$wf->{'EOrder'}       ->load_conf($conf_file);                                      # load the workflow config file
$wf->{'FillOrder'}    ->load_conf($conf_file);                                      # load the workflow config file
$wf->{'CreditCheck'}  ->load_conf($conf_file);                                      # load the workflow config file
my $data_fields = {                                                                # initialize the process variables: data fields
        'EOrder'      => $wf->{'EOrder'}     ->init_data_fields($wfp_id->{'EOrder'}),
        'FillOrder'   => $wf->{'FillOrder'}  ->init_data_fields($wfp_id->{'FillOrder'}),
        'CreditCheck' => $wf->{'CreditCheck'}->init_data_fields($wfp_id->{'CreditCheck'}),
};
# The following pointer contains the entire workflow configuration, including call-back functions (ACTION)
# Attention: The following paramter refers to itself when calling sub get_dest_id()
my $wf_param = {};                                                                # initialize the process input/output parametrs,
$wf_param = {                                                                        # process exceptions and call-back functions (actions)
        $wfp_id->{'EOrder'} =>                                                         # workflow ID
        {
                'IN' =>
                {
                        'orderString' => 'AAA',                                 # FormalParameters of workflow
                },
                'OUT' =>
                {
                        'returnMessage' => '',                                  # FormalParameters of workflow
                },
                'EXCEPTION' =>                                                  # defined by Kai
                {
                        'SYSTEM' =>
                        {
                        },
                        'APPLICATION' =>
                        {
                        },
                },
                'ACTION' =>                                                     # call-back functions (Activity/Implementation/Tool)
                {
                        '0' => sub
                        {
                                print "The activity number '0' is under construction...\n";
                                return {};
                        },
                        '1'  => sub
                        {
                                $data_fields  = $wf->{'EOrder'}->data_fields({'orderInfo' => $doc,});
                                return &init2dest(shift,shift,'EOrder');

                        },
                        '6' => sub
                        {
                                print "All done. Existing...\n";
                                return {};
                        },
                        '8' => sub
                        {
                                print "The activity number '8' is under construction...\n";
                                return {};
                        },
                        '9' => sub
                        {
                                return &init2dest(shift,shift,'EOrder');
                        },
                        '10' => sub
                        {
                                print "Subprocess \"Checking Credit\" reached.\n";
                                print "The activity number '10' is under construction...\n";
                                return {};
                        },
                        '11' => sub
                        {
                                print "The activity number '11' is under construction...\n";
                                return {};
                        },
                        '12' => sub
                        {
                                $data_fields->{'EOrder'}  = $wf->{'EOrder'}->data_fields({'orderType' => $order_type,});# modify $DATAFIELDS, 'Credit' or 'PO'
                                return &init2dest(shift,shift,'EOrder');
                        },
                        '32' => sub
                        {
                                $data_fields->{'EOrder'}  = $wf->{'EOrder'}->data_fields({'orderInfo' => $doc,'orderNumber' => $order_ordern,});# modify $DATAFIELDS
                                return &init2dest(shift,shift,'EOrder');
                        },
                        '39' => sub
                        {
                                $data_fields->{'EOrder'}  = $wf->{'EOrder'}->data_fields({'orderNumber' => $order_ordern,});# modify $DATAFIELDS
                                return &init2dest(shift,shift,'EOrder');
                        },
                        '41' => sub
                        {
                                $data_fields->{'EOrder'}  = $wf->{'EOrder'}->data_fields({'orderInfo.AccountNumber' => $order_actno,'orderInfo.ToltalAmount' => $order_total});# modify $DATAFIELDS, 'Credit' or 'PO'
                                return &init2dest(shift,shift,'EOrder');
                        },
                        '56' => sub
                        {
                                print "The activity number '56' is under construction...\n";
                                return {};
                        },
                },
        },
        $wfp_id->{'FillOrder'} =>                                                  # workflow ID
        {
                'IN' =>
                {
                        'orderString' => 'BBB',
                },
                'OUT' =>
                {
                        'returnMessage' => '',
                },
                'EXCEPTION' =>
                {
                        'SYSTEM' =>
                        {
                        },
                        'APPLICATION' =>
                        {
                        },
                },
                'ACTION' =>
                {
                        '0' => sub
                        {
                                print "The activity number is under construction...\n";
                                return {};
                        },
                        '1'  => sub
                        {
                                $data_fields  = $wf->{'FillOrder'}->data_fields({'orderInfo' => $doc,});# modify $DATAFIELDS
                                return &init2dest(shift,shift,'FillOrder');
                        },
                },
        },
        $wfp_id->{'CreditCheck'} =>                                                  # workflow ID
        {
                'IN' =>
                {
                        'orderString' => 'CCC',
                },
                'OUT' =>
                {
                        'returnMessage' => '',
                },
                'EXCEPTION' =>
                {
                        'SYSTEM' =>
                        {
                        },
                        'APPLICATION' =>
                        {
                        },
                },
                'ACTION' =>
                {
                        '0' => sub
                        {
                                print "The activity number is under construction...\n";
                                return {};
                        },
                        '1'  => sub
                        {
                                $data_fields  = $wf->{'CreditCheck'}->data_fields({'orderInfo' => $doc,});# modify $DATAFIELDS
                                return &init2dest(shift,shift,'CreditCheck');

                        },
                },
        },

};


######### Finished definition, starting workflow engine #########################
print "The starting activity ID is $init_act_id->{'EOrder'}->[0]\n\n";
my $out = $wf->{'EOrder'}->start_workflow($wfp_id,$wf_param,$init_act_id,'EOrder');
ok($out, "end");

sub init2dest
{
        my ($init_act_id,$dest_act_id,$wfp_name) = (shift,shift,shift);
        my @dest_act_id;
        eval{@dest_act_id = @$dest_act_id;};
        @dest_act_id = () if($@);
        # modify $DATAFIELDS in the following way: slurping a purchase order
        # for a given activity ID and a set of corresponding paramters produce the next activity ID
        foreach(@$init_act_id){                                # TODO: using thread to make parallel calculations
                my $dest_id = $wf->{$wfp_name}->get_dest_id($cust_lib,$wfp_id,$wfp_name,$wf,$wf_param,$init_act_id,$_);
                push @dest_act_id, @$dest_id;                # and acumulate new destination IDs
        }
        return \@dest_act_id;
}

