package Workflow::Wfmc;

use 5.008003;
use strict;
use warnings;
use Data::Dumper;
use XML::Simple qw(XMLin XMLout);

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration        use Workflow::Wfmc ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01e';

my $PACKAGE = __PACKAGE__;
our @LOGOPT;
my %LOGFLAG = (
        'emerg'    => 0,
        'crit'     => 0,
        'error'    => 0,
        'warn'     => 0,
        'notice'   => 0,
        'info'     => 0,
        'debug'    => 0,
);     # apache logging levels
my $INITIALIZED = 0;
my $CONFIG;
my $MYSELF;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new {
        my $invocant = shift;
        my $class = ref($invocant) || $invocant;
        my $self = {};
        if (defined $_[0] && defined $_[1] && shift eq 'Id') {
                $self->{Id}               = shift;
                $self->{DataFields}       = undef; # DataFields are variables used in workflow
                $self->{FormalParameters} = undef; # FormalParameters are variables used in workflow
        }
        else
        {
                die "(die): Lack of Id in subroutine new of $PACKAGE"
        }
        $MYSELF = $self;
        bless ($self,$class);
        return $self;
}
#sub DESTROY
#{
#        my $invocant = shift;
#        print STDERR "(debug): Destroying object of $PACKAGE\n";
#        print STDERR "(debug): Argh. Life was sweet.\n";
#}

sub Id
{
        my $invocant = shift;
        $invocant->logger->debug("Entering subroutine Id of $PACKAGE");
        $invocant->logger->debug("Leaving subroutine Id of $PACKAGE");
        (@_) ? return shift : return $invocant->{Id};
}

sub workflow {
        my $invocant = shift;
        my ($wfps,$wfp_id) = (shift,shift);
        my $wfp = $wfps->{'WorkflowProcess'}->[$wfp_id-1];
        my $wfp_pheader  = $wfp->{'ProcessHeader'};
        my $wfp_fparam   = $wfp->{'FormalParameters'};
        my $wfp_dataf    = $wfp->{'DataFields'};
        my $wfp_part     = $wfp->{'Partitions'};
        my $wfp_app      = $wfp->{'Applications'};
        my $wfp_act      = $wfp->{'Activities'};
        my $wfp_trans    = $wfp->{'Transitions'};
        #print Dumper($wfp_trans);
        return $invocant;
}

sub debug
{
        my $invocant = shift;
        return $invocant unless($LOGFLAG{'debug'});
        if(@_)
        {
                my @lines = split("\n",shift);
                my $n = 0;
                my $length = $#lines + 1;
                foreach my $line (@lines)
                {
                        $n++;
                        print STDERR "(debug)\t($n/$length):\t$line\n" ;
                }
        }
        else
        {
                print STDERR "(debug)\t(1/1):\tLack of content in subroutine debug of $PACKAGE";
        }
        return $invocant;
}
;
sub warn
{
        my $invocant = shift;
        return $invocant unless($LOGFLAG{'warn'});
        if(@_)
        {
                my @lines = split("\n",shift);
                my $n = 0;
                my $length = $#lines + 1;
                foreach my $line (@lines)
                {
                        $n++;
                        print STDERR "(warn)\t($n/$length):\t$line\n" ;
                }
        }
        else
        {
                print STDERR "(warn)\t(1/1):\tLack of content in subroutine warn of $PACKAGE";
        }
        return $invocant;
}
;
sub error
{
        my $invocant = shift;
        #return $invocant unless($LOGFLAG{'error'});
        if(@_)
        {
                my @lines = split("\n",shift);
                my $n = 0;
                my $length = $#lines + 1;
                foreach my $line (@lines)
                {
                        $n++;
                        print STDERR "(error)\t($n/$length):\t$line\n" ;
                }
                if(my $vie = $invocant->error_notify_via)
                {
                        if ($vie =~ /\bemail\b/)
                        {
                                my $body = join('',@lines);
                                my $subject = 'STM error message';
                                $invocant->sendmail($subject,$body);
                        }
                        if ($vie =~ /\bjabber\b/)
                        {
                                my $body = join('',@lines);
                                my $subject = 'STM error message';
                                $invocant->sendjabber($subject,$body);
                        }
                }

        }
        else
        {
                print STDERR "(error)\t(1/1):\tLack of content in subroutine error of $PACKAGE";
        }
        return $invocant;
}
;

sub info
{
        my $invocant = shift;
        return $invocant unless($LOGFLAG{'info'});
        if(@_)
        {
                my @lines = split("\n",shift);
                my $n = 0;
                my $length = $#lines + 1;
                foreach my $line (@lines)
                {
                        $n++;
                        print STDERR "(info)\t($n/$length):\t$line\n" ;
                }
        }
        else
        {
                print STDERR "(info)\t(1/1):\tLack of content in subroutine info of $PACKAGE";
        }
        return $invocant;
}
sub notice
{
        my $invocant = shift;
        return $invocant unless($LOGFLAG{'notice'});
        if(@_)
        {
                my @lines = split("\n",shift);
                my $n = 0;
                my $length = $#lines + 1;
                foreach my $line (@lines)
                {
                        $n++;
                        print STDERR "(notice)\t($n/$length):\t$line\n" ;
                }
        }
        else
        {
                print STDERR "(notice)\t(1/1):\tLack of content in subroutine notice of $PACKAGE";
        }
        return $invocant;
}
sub emerg
{
        my $invocant = shift;
        return $invocant unless($LOGFLAG{'emerg'});
        if(@_)
        {
                my @lines = split("\n",shift);
                my $n = 0;
                my $length = $#lines + 1;
                foreach my $line (@lines)
                {
                        $n++;
                        print STDERR "(emerg)\t($n/$length):\t$line\n" ;
                }
        }
        else
        {
                print STDERR "(emerg)\t(1/1):\tLack of content in subroutine emerg of $PACKAGE";
        }
        return $invocant;
}
sub crit
{
        my $invocant = shift;
        return $invocant unless($LOGFLAG{'crit'});
        if(@_)
        {
                my @lines = split("\n",shift);
                my $n = 0;
                my $length = $#lines + 1;
                foreach my $line (@lines)
                {
                        $n++;
                        print STDERR "(crit)\t($n/$length):\t$line\n" ;
                }
        }
        else
        {
                print STDERR "(crit)\t(1/1):\tLack of content in subroutine crit of $PACKAGE";
        }
        return $invocant;
}

sub logger           # also a initializer ;-)
{
        my $invocant = shift;
        unless($INITIALIZED)
        {
                foreach my $n (@LOGOPT)
                {
                        $LOGFLAG{$n} = 1;
                }
                $INITIALIZED = 1;
        }
        return $invocant;
}


sub load_conf
{
        use XML::XPath;
        my $invocant = shift;
        $invocant->logger->debug("Entering subroutine load_conf of $PACKAGE");
        my ($file,$nodeset);
        if(@_)
        {
                $file = shift;
                die "(die): Configuration file $file does not exit or empty of $PACKAGE" unless( -s $file);
                $invocant->logger->debug("Config file name $file passed");
                $CONFIG = XML::XPath->new(filename => $file );
                $invocant->logger->debug("XML::XPath object created");
                $nodeset = $CONFIG->find('/'); # find all paragraphs
                $invocant->logger->debug("Finding config root node");
                foreach my $node ($nodeset->get_nodelist)
                {
                        $invocant->logger->debug(XML::XPath::XMLParser::as_string($node));
                }
                $invocant->logger->debug("Config file $file loaded");
        }
        else
        {
                die "(die): Lack of copnfiguration file name in subroutine load_conf of $PACKAGE";
        }
        $invocant->logger->debug("Leaving subroutine load_conf of $PACKAGE");
        return $CONFIG;
}

sub init_data_fields # intialize DataFields (with values if possible) using the workflow configuration file
{
        my ($invocant,$wfp_id) = (shift,shift);
        $invocant->logger->debug("Entering subroutine init_data_fields of $PACKAGE");
        my $xml = $invocant->get_wfp_element($wfp_id,'DataFields');
        my $perl = XMLin($xml);
        my $df = $perl->{'DataField'};
        my @df;
        my $datafields;
        eval{@df = @$df;};
        push @df, $df if($@);
        foreach(@df){
                if(defined $_->{'InitialValue'}){
                        $invocant->{DataFields}->{$_->{'Id'}} = $_->{'InitialValue'};
                }else{
                        $invocant->{DataFields}->{$_->{'Id'}} = '';
                }
        }
        $invocant->logger->debug("Leaving subroutine init_data_fields of $PACKAGE");
        return $invocant->{DataFields};
}

sub data_fields # set elements in DataFields and retrun a pointer to the DataFields
{
        my ($invocant,$df) = (shift,shift);
        $invocant->logger->debug("Entering subroutine data_fields of $PACKAGE");
        if(defined $df){
                my %df = %$df;
                my @chiave = keys(%df);
                foreach(@chiave){
                        $invocant->{DataFields}->{$_} = $df->{$_};
                }
        }
        $invocant->logger->debug("Leaving subroutine data_fields of $PACKAGE");
        return $invocant->{DataFields};
}


# This method generates PERL code to call some library (PERL class). Produces something like
# use Kai::Order::Simple;
# Kai::Order::Simple::checkData('orderInfo'=>'Blah',);
sub get_perl_by_method{ # only accept strings as import data
        my ($invocant,$cls,$mtd,$param) = @_;
        #print $_,"\n" foreach(@param);exit;
        $invocant->logger->debug("Entering subroutine parser of $PACKAGE");
        my $perl = "use $cls\;\n";
        if(defined $mtd){
	        $perl .= $cls.'::';
	        $perl .= $mtd.'({';
        }
        foreach(@$param){
                $perl .= $_;
                $perl .= q{,};
        }
        $perl .= "})\;\n";
        $invocant->logger->debug("Leaving subroutine get_perl_by_method of $PACKAGE");
        $perl;
}


sub get_activity_by_id{ # Return the Activity (identified by activity ID) subnode of the workflow configuration file
        my ($invocant,$wfp_id,$act_id) = @_;
        $invocant->logger->debug("Entering subroutine get_activity_by_id of $PACKAGE");
        my $nodeset = $CONFIG->find(q|/Package/WorkflowProcesses/WorkflowProcess[@Id='|.$wfp_id.q|']/Activities/Activity[@Id='|.$act_id.q|']|); # find all paragraphs
        foreach my $node ($nodeset->get_nodelist)
        {
                $invocant->logger->debug("Leaving subroutine get_activity_by_id of $PACKAGE");
                return XML::XPath::XMLParser::as_string($node);
        }
}

sub get_dest_act_id{ # Return the Transaction (identified by 'From') subnodes of the workflow configuration file
        my ($invocant,$wfp_id,$act_id) = @_;
        $invocant->logger->debug("Entering subroutine get_activity_by_id of $PACKAGE");
        my $nodeset = $CONFIG->find(q|/Package/WorkflowProcesses/WorkflowProcess[@Id='|.$wfp_id.q|']/Transitions/Transition[@From='|.$act_id.q|']|); # find all paragraphs
        my @res;
        foreach my $node ($nodeset->get_nodelist)
        {
                push @res, XML::XPath::XMLParser::as_string($node);
        }
        $invocant->logger->debug("Leaving subroutine get_activity_by_id of $PACKAGE");
        \@res;
}

sub get_perl_by_act_id{ # Return PERL code to call for a given Activity ID
        use XML::Simple qw|XMLin XMLout|;
        my ($invocant,$order_class,$wfp_id,$init_act_id) = @_;
        $invocant->logger->debug("Entering subroutine get_activity_by_id of $PACKAGE");
        my $act_xml = $invocant->get_activity_by_id($wfp_id,$init_act_id);
        my $act_perl = XMLin($act_xml);
        my $method = $act_perl->{'Implementation'}->{'Tool'}->{'Id'};
        my $params = $act_perl->{'Implementation'}->{'Tool'}->{'ActualParameters'}->{'ActualParameter'};
        my (@p,@params);
        eval{@p = @$params;};
        my $p;
        if($@){
                if (defined $params){
	                $invocant->{DataFields}->{$params} =~ s/'/\\'/g ;
	                $p =qq|'$params'=>'$invocant->{DataFields}->{$params}'|;
	                push @params,$p;
                }
        }else{
                foreach(@p){
                        $invocant->{DataFields}->{$_} =~ s/'/\\'/g;
                        my $p = qq|'$_'=>'$invocant->{DataFields}->{$_}'|;
                        push @params,$p;
                }
        }
        my $perl = $invocant->get_perl_by_method($order_class,$method,\@params); # get the perl code
        $invocant->logger->debug("Leaving subroutine get_perl_by_act_id of $PACKAGE");
        $perl;
}


sub get_conditions # Produces a hash from the Transaction (identified by 'From') subnodes of the workflow configuration file
{
        my ($invocant,$wfp_id,$init_act_id) = @_;
        $invocant->logger->debug("Entering subroutine get_conditions of $PACKAGE");
        my $dest_act_id = $invocant->get_dest_act_id($wfp_id,$init_act_id); # get the XML leafs specifying 'From' ID
        my @cond_hash;
        my @operators = ('==','!=');
        foreach (@$dest_act_id)
        {
                my $perl = XMLin($_);
                my $dest = $perl->{'To'};
                my $cond = $perl->{'Condition'};
                if(ref $cond){ # OTHERWISE, EXCEPTION
                        push @cond_hash, {
                                'param' => '',
                                'value' => '',
                                'dest'  => $dest,
                                'op'    => $cond->{'Type'},                           # OTHERWISE, EXCEPTION
                        };
                }elsif($cond){ # var==, var!=
                        foreach my $op (@operators){
                                my @cond = split($op,$cond);
                                $cond[0] =~ s/\s//g;                                  # paramter name without white spaces
				if(defined $cond[1]){
	                                $cond[1] = $1 if($cond[1] =~ m/^\s*\"(.*)\"\s*$/g);
	                                push @cond_hash, {
	                                        'param' => $cond[0],
	                                        'value' => $cond[1],                  # undef if == is not in condition
	                                        'dest'  => $dest,
	                                        'op'    => $op,
	                                };
                                };
                        }
                }else{ # unconditioned dest
                        push @cond_hash, {
                                'param' => '',
                                'value' => '',                                        # undef if == is not in condition
                                'dest'  => $dest,
                                'op'    => '',
                        };
                }
        }
        $invocant->logger->debug("Leaving subroutine get_conditions of $PACKAGE");
        \@cond_hash;
}

sub get_dest_id # This method is the first to be called by an application.
#For a given activity ID and a set of corresponding paramters produce the next activity ID
{
        my ($invocant,
        $lib,                  # 'Kai::Order::Simple'
        $wfp_id,               # 1
        $wfp_name,             # 'EOrder'
        $wf,$wf_param,         # setup paramters
        # specify starting states for each workflow. Used by SubFlow only
        $init_act_id,          # setup paramter, {'EOrder' => [1],'FillOrder' => [1],'CreditCheck' => [1],}
        $init_act_id_scalar    # concret starting ID, e.g., 10
        ) = @_;
        $invocant->logger->debug("Entering subroutine get_dest_id of $PACKAGE");
        my $xml = $invocant->get_act_element($wfp_id->{$wfp_name},$init_act_id_scalar);
        my $perl = XMLin($xml);
        my %perl = %$perl;
        my @chiave = keys(%perl);
        my ($restriction,$action,$boolean,@refid);                                # in case that TransitionRestrictions exist
        my $dest_unrest;
        if(grep(/TransitionRestrictions/,@chiave)){
                my $restr = $perl->{'TransitionRestrictions'}->{'TransitionRestriction'};
                if(ref $restr->{'Split'}){
                        $action = 'Split';
                }else{
                        $action = 'Join';
                }
                if($restr->{$action}->{'Type'} eq 'XOR'){
                        $boolean = 'XOR';
                }else{
                        $boolean = 'AND';
                }
                my $ref_id = $restr->{$action}->{'TransitionRefs'}->{'TransitionRef'};
                if($ref_id){
                        my @ref_id;
                        eval{ @ref_id = @$ref_id;};
                        push @ref_id, $ref_id if($@);
                        push @refid, $_->{'Id'} foreach(@ref_id);
                        $restriction = 1;
                }else{
                        $restriction = 0;
                }
        }else{$restriction = 0;}
        # if there is an implementation, we should call a method which can cause a change in the DataFields
        if(grep(/Implementation/,@chiave)){
                print "Implementation step\n";
                my $subflow = $invocant->get_subflow($wfp_id->{$wfp_name},$init_act_id_scalar);
                unless($subflow){
                        my $code = $invocant->get_perl_by_act_id($lib->{$wfp_name},$wfp_id->{$wfp_name},$init_act_id_scalar);
                        my $params_new = eval($code);                                        # exe the perl code
                        $invocant->formal_parameters({'EXCEPTION' => {'SYSTEM' => $!,}}) if($@);
                        $invocant->data_fields($params_new)if(ref $params_new);         # update $invocant->{DataFields}
                        $dest_unrest = $invocant->get_dest_from_transitions($wfp_id->{$wfp_name},$init_act_id_scalar); # dest list from transitions
                        # if no restriction on transition then go to Transition node
                        unless($restriction){ # lack of restriction: the dest list from transitions are the dest
                                $invocant->logger->debug("Leaving subroutine get_dest_id of $PACKAGE");
                                return $dest_unrest;
                        }else{ # with restrictions
                                $invocant->logger->debug("Leaving subroutine get_dest_id of $PACKAGE");
                                return $invocant->get_dest_id_with_restrictions($wfp_id->{$wfp_name},$boolean,\@refid,$dest_unrest);
                        }
                }else{      # subprocess
                        # get WF ID
                        #my $wf_id;        #TODO
                        #my $wfp_name = $invocant->get_wfpname_by_id($wf_id);
                        #my $out = $wf->{$wfp_name}->start_workflow($wfp_id->{$wfp_name},$wf_param,$init_act_id,$wfp_name);
                        return {}; # no support to Subprocess
                }
        }else{ # Route
                my $code = $invocant->get_perl_by_act_id($lib->{$wfp_name},$wfp_id->{$wfp_name},$init_act_id_scalar);
                my $params_new = eval($code);                                        # exe the perl code
                $invocant->formal_parameters({'EXCEPTION' => {'SYSTEM' => $!,}}) if($@);
                $invocant->data_fields($params_new)if(ref $params_new);         # update $invocant->{DataFields}
                $dest_unrest = $invocant->get_dest_from_transitions($wfp_id->{$wfp_name},$init_act_id_scalar); # dest list from transitions
                if($restriction){ # with restriction
                        print "Route step\n";
                        $invocant->logger->debug("Leaving subroutine get_dest_id of $PACKAGE");
                        return $invocant->get_dest_id_with_restrictions($wfp_id->{$wfp_name},$boolean,\@refid,$dest_unrest);
                }else{
                        $invocant->logger->debug("Leaving subroutine get_dest_id of $PACKAGE");
                        return {}; # with Route and without Restriction is wrong
                }
                #TODO
        }
}


sub get_dest_from_transitions # Return an array of raw destination IDs from the Transitions identified by a 'From' ID
{
        my ($invocant,$wfp_id,$init_act_id) = @_;
        $invocant->logger->debug("Entering subroutine get_dest_from_transitions of $PACKAGE");
        my @dest;
        my $cond = $invocant->get_conditions($wfp_id,$init_act_id);
        foreach(@$cond){
                if($_->{'op'} eq '=='){
                        if( $invocant->{DataFields}->{$_->{'param'}} eq $_->{'value'}){
                                push @dest, $_->{'dest'};
                        }
                }
                if($_->{'op'} eq '!='){
                        if( $invocant->{DataFields}->{$_->{'param'}} ne $_->{'value'}){
                                push @dest, $_->{'dest'};
                        }
                }
        }
        foreach(@$cond){
                if($_->{'op'} eq 'OTHERWISE'){                                      # TODO: 'EXCEPTION' not supported yet
                        push @dest, $_->{'dest'};
                }
        }
        foreach(@$cond){
                if($_->{'op'} eq ''){
                        push @dest, $_->{'dest'};
                }
        }
        $invocant->logger->debug("Leaving subroutine get_dest_from_transitions of $PACKAGE");
        return \@dest;
}

sub get_dest_id_with_restrictions # Controls a list of Transition reference IDs ($refid) and a list of raw destination IDs
# to produce the correct destination IDs
{
        my ($invocant,$wfp_id,$boolean,$refid,$dest_unrest) = @_;
        $invocant->logger->debug("Entering subroutine get_dest_id_with_restrictions of $PACKAGE");
        my @dest;
        foreach(@$refid){
                my $xml = $invocant->get_transition($wfp_id,$_);      # get dest id & condition by transition ref
                if($xml){
                    my $perl = XMLin($xml);
                    my $to = $perl->{'To'};
                    push @dest, $to if(grep(/^$to$/,@$dest_unrest));    # valid only if restriction id in unrestricted list
                    return \@dest if($boolean eq 'XOR' && @dest);        # TODO: return the first ID for 'XOR'
                }
        }
        $invocant->logger->debug("Leaving subroutine get_dest_id_with_restrictions of $PACKAGE");
        return \@dest;                                                        # return all for 'AND'
}

sub get_wfp_element
# Produces the WorkflowProcess (specified by workflow name) subnode of workflow configuration file, used by sub init_data_fields
{
        my ($invocant,$wfp_id,$subnode) = @_;
        $invocant->logger->debug("Entering subroutine get_wfp_element of  $PACKAGE");
        my $nodeset = $CONFIG->find(q|/Package/WorkflowProcesses/WorkflowProcess[@Id='|.$wfp_id.q|']/|.$subnode); # find all paragraphs
        foreach my $node ($nodeset->get_nodelist)
        {
                $invocant->logger->debug("Leaving subroutine get_wfp_element of $PACKAGE");
                return XML::XPath::XMLParser::as_string($node);
        }
}

sub get_act_element
# Produces the Activity (specified by workflow name and Activity ID) subnode of workflow configuration file, used by sub get_act_id
{
        my ($invocant,$wfp_id,$id,) = @_;
        $invocant->logger->debug("Entering subroutine get_act_element of  $PACKAGE");
        my $nodeset = $CONFIG->find(q|/Package/WorkflowProcesses/WorkflowProcess[@Id='|.$wfp_id.q|']/Activities/Activity[@Id='|.$id.q|']|); # find all paragraphs
        foreach my $node ($nodeset->get_nodelist)
        {
                $invocant->logger->debug("Leaving subroutine get_act_element of $PACKAGE");
                return XML::XPath::XMLParser::as_string($node);
        }
}

sub get_transition
# Produces the Transition (specified by workflow name and Transition ID) subnode of workflow configuration file, used by sub get_dest_id_with_restrictions
{
        my ($invocant,$wfp_id,$id,) = @_;
        $invocant->logger->debug("Entering subroutine get_transitions of  $PACKAGE");
        my $nodeset = $CONFIG->find(q|/Package/WorkflowProcesses/WorkflowProcess[@Id='|.$wfp_id.q|']/Transitions/Transition[@Id='|.$id.q|']|); # find all paragraphs
        foreach my $node ($nodeset->get_nodelist)
        {
                $invocant->logger->debug("Leaving subroutine get_transitions of $PACKAGE");
                return XML::XPath::XMLParser::as_string($node);
        }
}

sub get_subflow
# Produces the Subflow (specified by workflow name and Activity ID) subnode of workflow configuration file, used by sub get_dest_id
{
        my ($invocant,$wfp_id,$init_act_id,) = @_;
        $invocant->logger->debug("Entering subroutine get_transitions of  $PACKAGE");
        my $nodeset = $CONFIG->find(q|/Package/WorkflowProcesses/WorkflowProcess[@Id='|.$wfp_id.q|']/Activities/Activity[@Id='|.$init_act_id.q|']/Implementation/SubFlow|); # find all SubFlows
        foreach my $node ($nodeset->get_nodelist)
        {
                $invocant->logger->debug("Leaving subroutine get_transitions of $PACKAGE");
                return XML::XPath::XMLParser::as_string($node);
        }
}

sub start_workflow {
        my ($invocant,
        $wfp_id,                   # 1
        $wf_param,$init_act_id,    # setup parameters
        $wf_name                   # 'EOrder'
        ) = @_;
        $invocant->formal_parameters($wf_param->{$wfp_id->{$wf_name}}->{'IN'});
        my @init_act_id;
        eval{ @init_act_id = @{$init_act_id->{$wf_name}};};
        push @init_act_id, $init_act_id->{$wf_name} if($@);
        while(1){
                my @dest_act_id = ();
                foreach(@init_act_id) {
                        my $dest_act_id = $wf_param->{$wfp_id->{$wf_name}}->{'ACTION'}->{$_}->([$_],[]);
                        goto USCITA unless($dest_act_id);         # exist if no destinition
                        eval{@dest_act_id = @$dest_act_id;};
                        goto USCITA if($@);                       # exit if no destinition
                        if($#dest_act_id > 0) {                   # multiple dest id
                                print "The next activity IDs are @dest_act_id\n\n";
                        }else{                                    # single dest id
                                print "The next activity ID is @dest_act_id\n\n";
                        }
                        if(@dest_act_id){
                                @init_act_id = @dest_act_id;      # start from arrival
                        }else{
                                print "Process end point reached.\n";
                                goto USCITA;                      # exist if dest ID is 0
                        }
                }
        }
        USCITA:
        return $wf_param->{$wfp_id->{$wf_name}}->{'OUT'};
}


sub formal_parameters # set elements in FormalParameters and retrun a pointer to the FormalParameters
{
        my ($invocant,$fp) = (shift,shift);
        $invocant->logger->debug("Entering subroutine formal_parameters of $PACKAGE");
        if(defined $fp){
                my %fp = %$fp;
                my @chiave = keys(%fp);
                foreach(@chiave){
                        $invocant->{FormalParameters}->{$_} = $fp->{$_};
                }
        }
        $invocant->logger->debug("Leaving subroutine formal_parameters of $PACKAGE");
        return $invocant->{FormalParameters};
}
sub get_wfpname_by_id
# Produces the Transition (specified by workflow name and Transition ID) subnode of workflow configuration file, used by sub get_dest_id_with_restrictions
{
        my ($invocant,$wfp_id) = @_;
        $invocant->logger->debug("Entering subroutine get_transitions of  $PACKAGE");
        my $nodeset = $CONFIG->find(q|/Package/WorkflowProcesses/WorkflowProcess[@Id='|.$wfp_id.q|']|); # find all paragraphs
        my $xml;
        foreach my $node ($nodeset->get_nodelist)
        {
                $invocant->logger->debug("Leaving subroutine get_transitions of $PACKAGE");
                $xml = XML::XPath::XMLParser::as_string($node);
                last;
        }
        my $perl = XMLin($xml);
        return $perl->{'Name'};
}
1;
__END__

=head1 NAME

Workflow::Wfmc - A lightweight Workflow Engine in PERL based on XPDL 2.0

=head1 SYNOPSIS

  use Workflow::Wfmc;


=head1 DESCRIPTION

This is an partial implementation of XML Process Definition Language (XPDL) Version 2 (see Web page of Workflow Management Coalition - http://www.wfmc.org). It supports input and output parameters for a workflow, routing, call-back functions and conditions. It does not support sub-processes and exceptions at the moment. You can run 'perl t/Workflow-Wfmc.t -t "PO"' or 'perl t/Workflow-Wfmc.t -t "Credit"' to see how it works. The workflow configuration file "workflow.xml" can be created with some visual tools (e.g., SAP Workflow Editor). The sample package "Workflow::Wfmc::Test::Order" contains dummy call-back functions. As a matter of fact, the executable program itself could be generated from the workflow configuration file, which is something that the author would like to complete in a successive release. To test it, you should prepare your workflow configuration file and the packages that contain call-back functions first and then generate an executable program following the example of t/Workflow-Wfmc.t.

=head2 EXPORT

None by default.



=head1 AUTHOR

Kai Li E<lt>kaili@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kai Li

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut