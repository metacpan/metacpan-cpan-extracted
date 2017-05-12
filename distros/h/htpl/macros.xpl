<?xml version="1.0" ?>
<!DOCTYPE XPL>
<HTPL>
<__MACRO NAME="SQL">
	<__PRE>use HTML::HTPL::Db;</__PRE>
	<__MACRO NAME="SCOPE">
		<__MACRO NAME="BEGIN" MAX="0">
			<__SET VALUE="$__htpl_db_%id%_%random%"
				VAR="dbobj"/>
			<__EXPORT SCOPE="" VAR="dbobj"/>
		</__MACRO>
		<__MACRO NAME="GOTO" MAX="1" MIN="1">
			<__SET VALUE="$%1%"
				VAR="dbobj"/>
			<__EXPORT SCOPE="" VAR="dbobj"/>
		</__MACRO>
		<__MACRO MIN="1" MAX="3" NAME="CONNECT">
			<__INCLUDE>SQL SCOPE RETRIEVE</__INCLUDE>
			<__DO>my %$dbobj% = 
			HTML::HTPL::Db->new("%1%", "%2%", "%3%");
		</__DO></__MACRO>
	<__MACRO PRIVATE="1" NAME="RETRIEVE">
		<__IMPORT SCOPE="" VAR="dbobj"/>
		<__INCLUDE ASSERT="!%$dbobj%">SQL SCOPE BEGIN</__INCLUDE>
	</__MACRO>
	<__MACRO MIN="2" NAME="CURSOR"><__INCLUDE>SQL SCOPE RETRIEVE</__INCLUDE>
		<__DO>
$%1% = %$dbobj%->cursor(&amp;HTML::HTPL::Db'parse_sql("%2*%"));
		</__DO></__MACRO>
        <__MACRO MIN="1" NAME="EXEC"><__INCLUDE>SQL SCOPE RETRIEVE</__INCLUDE>
                <__DO>
%$dbobj%->execsql(&amp;HTML::HTPL::Db'parse_sql("%1*%"));</__DO></__MACRO>
	<__MACRO NAME="EMULATE" MIN="1">
		<__INCLUDE>SQL SCOPE RETRIEVE</__INCLUDE>
		<__DO>$HTML::HTPL::save_sql_scope = $HTML::HTPL::htpl_db_obj;
			$HTML::HTPL::htpl_db_obj = %$dbobj%;
		</__DO>
		<__INCLUDE>SQL %1*%</__INCLUDE>
		<__DO>%$dbobj% = $HTML::HTPL::htpl_db_obj;
			$HTML::HTPL::htpl_db_obj = $HTML::HTPL::save_sql_scope;
			undef $HTML::HTPL::save_sql_scope;</__DO></__MACRO>
	</__MACRO>
	<__MACRO MIN="1" MAX="3" NAME="CONNECT">$HTML::HTPL::htpl_db_obj = HTML::HTPL::Db->new("%1%", "%2%", "%3%");</__MACRO>
	<__MACRO MIN="1" MAX="3" NAME="MYSQL"><__ALIAS>SQL CONNECT DBI:mysql:%1% %2*%</__ALIAS></__MACRO>
	<__MACRO MIN="1" MAX="1" NAME="MSQL"><__ALIAS>SQL CONNECT DBI:mSQL:%1%</__ALIAS></__MACRO>
	<__MACRO MIN="1" MAX="1" NAME="XBASE"><__ALIAS>SQL CONNECT DBI:XBase:%1%</__ALIAS></__MACRO>
	<__MACRO MIN="1" NAME="POSTGRESQL"><__ALIAS>SQL CONNECT DBI:Pg:dbname=%1%</__ALIAS></__MACRO>
	<__MACRO NAME="POSTGRES"><__ALIAS>SQL POSTGRESQL %1*%</__ALIAS></__MACRO>

        <__MACRO MIN="1" NAME="EXEC">$HTML::HTPL::htpl_db_obj->execsql(&amp;HTML::HTPL::Db'parse_sql("%1*%"));</__MACRO>
	<__MACRO NAME="EXECUTE"><__ALIAS>SQL EXEC %1*%</__ALIAS></__MACRO>
	<__MACRO NAME="DECLARE">$HTML::HTPL::Sys::query_pool{"%1%"} ||= $HTML::HTPL::htpl_db_obj->prepare("%2*%");</__MACRO>
	<__MACRO MIN="2" NAME="CURSOR">$%1% = $HTML::HTPL::htpl_db_obj->cursor(&amp;HTML::HTPL::Db'parse_sql("%2*%"));</__MACRO>
	<__MACRO NAME="SEARCH"><__ALIAS>SQL CURSOR %1*%</__ALIAS></__MACRO>
	<__MACRO NAME="IMMEDIATE"><__DO>{ my $imm;</__DO>
		<__INCLUDE>SQL CURSOR imm %1*%</__INCLUDE>
		<__INCLUDE>FETCHIT imm</__INCLUDE>
		<__DO>}</__DO>
	</__MACRO>
	<__MACRO MIN="2" NAME="PROJECT"><__DO>{ my $imm;</__DO>
                <__INCLUDE>SQL CURSOR imm %2*%</__INCLUDE>
                <__INCLUDE>PROJECT imm %1% %1%</__INCLUDE>
		<__DO>}</__DO>
	</__MACRO>

	<__MACRO NAME="INSERT">$HTML::HTPL::htpl_db_obj->add("%1%", qw(%2*%));</__MACRO>
	<__MACRO NAME="ADD"><__ALIAS>SQL INSERT %1*%</__ALIAS></__MACRO>

	<__MACRO NAME="UPDATE">$HTML::HTPL::htpl_db_obj->update("%1%", qw(%2*%));</__MACRO>
	<__MACRO NAME="MODIFY"><__ALIAS>SQL UPDATE %1*%</__ALIAS></__MACRO>
	<__MACRO NAME="DELETE">$HTML::HTPL::htpl_db_obj->delete("%1%, qw(%2*%));</__MACRO>
	<__MACRO NAME="ERASE"><__ALIAS>SQL ERASE %1*%</__ALIAS></__MACRO>
	<__MACRO MIN="2" MAX="2" NAME="BATCH">$HTML::HTPL::htpl_db_obj->batch_insert("%1%", $%2%);</__MACRO>

	<__MACRO NAME="QUERY">$%1% = $HTML::HTPL::htpl_db_obj->query("%2%", qw(%3*%));</__MACRO>
	<__MACRO MIN="2" NAME="APPEND">
		<__INCLUDE>SQL CURSOR __htpl__temp__ %2*%</__INCLUDE>
		<__INCLUDE>MERGE %1% __htpl__temp__</__INCLUDE>
		<__DO>undef $__htpl__temp__;</__DO>
	</__MACRO>
</__MACRO>

<__MACRO NAME="LDAP">
	<__PRE>use HTML::HTPL::LDAP;</__PRE>
	<__MACRO MIN="1" MAX="4" NAME="INIT">$HTML::HTPL::htpl_dir_obj = new
              HTML::HTPL::LDAP(qw(%1*%));</__MACRO>
        <__MACRO MIN="1" SCOPE="1" NAME="SEARCH"><__INCLUDE>LDAP DOSEARCH %1*%</__INCLUDE>
                <__DO>$%1% = $HTML::HTPL::ldap_query;</__DO></__MACRO>
	<__MACRO PRIVATE="1" MANDATORY="filter,base" PARAMS="1" NAME="DOSEARCH">
		$HTML::HTPL::ldap_query =
			$HTML::HTPL::htpl_dir_obj->search(
			$tags{'FILTER'}, $tags{'BASE'}, $tags{'SCOPE'},
                        $tags{'ATTR'} . $tags{'ATTRS'} .
			$tags{'ATTRIBUTES'}, $tags{'SIZE'} .
			$tags{'LIMIT'} . $tags{'SIZELIMIT'}, $tags{'KEY'}
			. $tags{'SORTKEY'});
	</__MACRO>
	<__MACRO MIN="2" NAME="ADD">$HTML::HTPL::htpl_dir_obj->add("%1%", "%2*");</__MACRO>
	<__MACRO MIN="2" NAME="MODIFY">$HTML::HTPL::htpl_dir_obj->modify("%1%", "%2*");</__MACRO>
	<__MACRO MIN="1" MAX="1" NAME="DELETE">$HTML::HTPL::htpl_dir_obj->modify("%1%");</__MACRO>
 </__MACRO>

<__MACRO NAME="MEM">
	<__PRE>use HTML::HTPL::Mem;
use HTML::HTPL::Db;</__PRE>
	<__MACRO NAME="CURSOR">$%1% = HTML::HTPL::Mem'cursor(&amp;HTML::HTPL::Db'parse_sql("%2*%"));</__MACRO>
	<__MACRO NAME="SEARCH"><__ALIAS>MEM CURSOR %1*%</__ALIAS></__MACRO>
	<__MACRO NAME="IMMEDIATE"><__DO>{ my $imm;</__DO>
		<__INCLUDE>MEM CURSOR imm %1*%</__INCLUDE>
		<__INCLUDE>FETCHIT imm</__INCLUDE>
		<__DO>}</__DO>
	</__MACRO>
	<__MACRO NAME="PROJECT"><__DO>{ my $imm;</__DO>
                <__INCLUDE>MEM CURSOR imm %2*%</__INCLUDE>
                <__INCLUDE>PROJECT imm %1% %1%</__INCLUDE>
		<__DO>}</__DO>
	</__MACRO>
</__MACRO>

<__MACRO NAME="DIR">
	<__PRE>use HTML::HTPL::Glob;</__PRE>
	<__MACRO MIN="3" MAX="3" NAME="FILES">
		<__DO>$%1% = &amp;HTML::HTPL::Glob'files("%2%", "%3%");</__DO>
	</__MACRO>
	<__MACRO MIN="3" MAX="3" NAME="SUBS">
		<__DO>$%1% = &amp;HTML::HTPL::Glob'dirs("%2%", "%3%");</__DO>
	</__MACRO>
	<__MACRO MIN="3" MAX="3" NAME="TREE">
		<__DO>$%1% = &amp;HTML::HTPL::Glob'tree("%2%", "%3%");</__DO>
	</__MACRO>
</__MACRO>

<__MACRO NAME="TEXT">
        <__MACRO NOOP="1" PRIVATE="1" NAME="PRECSV"><__PRE>use HTML::HTPL::CSV;</__PRE></__MACRO>
	<__MACRO MIN="2" NAME="CSV"><__INCLUDE>TEXT PRECSV</__INCLUDE>
	<__DO MAX="2">$%1% = &amp;HTML::HTPL::CSV'opencsv("%2%");</__DO>
	<__DO MIN="3">$%1% = &amp;HTML::HTPL::CSV'opencsv("%2%", "%3%", qw(%4*%));</__DO></__MACRO>

	<__MACRO MIN="3" NAME="FLAT"><__PRE>use HTML::HTPL::Flat;</__PRE>
	$%1% = &amp;HTML::HTPL::Flat'openflat("%2%", qw(%3*%));</__MACRO>

        <__MACRO MIN="4" NAME="CUBE"><__INCLUDE>TEXT PRECSV</__INCLUDE>
	<__DO>$%1% = &amp;HTML::HTPL::CSV'opencsv("%2%", ["%3%", "%4%"],
qw(%5*%));</__DO></__MACRO>


	<__MACRO NOOP="1" PRIVATE="1" NAME="PREFIXED"><__PRE>use HTML::HTPL::Fixed;</__PRE></__MACRO>
	<__MACRO MIN="3" NAME="FIXED"><__INCLUDE>TEXT PREFIXED</__INCLUDE>
	<__DO>$%1% = &amp;HTML::HTPL::Fixed'openfixed("%2%", qw(%3*%));</__DO></__MACRO>
	<__MACRO MIN="3" NAME="RECORDS"><__INCLUDE>TEXT PREFIXED</__INCLUDE>
	<__DO>$%1% = &amp;HTML::HTPL::Fixed'openfixed("%2%", \"IBM", qw(%3*%));</__DO></__MACRO>

	<__MACRO MIN="2" MAX="2" NAME="READ">$%1% = &amp;readfile("%2%");</__MACRO>

	<__MACRO AREA="1" SCOPE="1" NAME="TEMPLATE"><__PRE>use Template;</__PRE>
	<__FWD MIN="1" MAX="1">my $__htpl_params = \%%%1%;
	&amp;begintransaction;</__FWD>
	<__REV>{ my $text = &amp;endtransaction;
		 my $temp = new Template({ 'INCLUDE_PATH' => $ORIG_DIR,
			'INTERPOLATE' => 1, 'EVAL_PERL' => 1});
		$temp->process(\$text, $__htpl_params); }</__REV>
	</__MACRO>

</__MACRO>

<__MACRO MIN="1" NAME="LOAD">die "Unknown query" unless $HTML::HTPL::Sys::query_pool{"%1%"};
$%1% = $HTML::HTPL::Sys::query_pool{"%1%"}->load(qw(%2*%));</__MACRO>

<__MACRO AREA="1" NAME="FETCH"><__FWD MIN="1" MAX="1" PUSH="fetch">$%1%->rewind if ($%1%);
while ($%1% &amp;&amp; !$%1%->eof &amp;&amp; $%1%->fetch) {</__FWD>
<__REV MAX="0"><__ALIAS>LOOP</__ALIAS></__REV>
</__MACRO>
<__MACRO MIN="1" MAX="1" NAME="FETCHIT">$%1%->fetch;</__MACRO>
<__MACRO MIN="1" MAX="1" NAME="FETCHITORBREAK">last unless ($%1%->fetch);</__MACRO>
<__MACRO MIN="2" MAX="2" NAME="FETCHCOLS">foreach %2% (%1%->cols) {</__MACRO>
<__MACRO MIN="3" MAX="3" NAME="FETCHCELL">$%3% = $%1%->get("%2%");</__MACRO>
<__MACRO MIN="3" NAME="PROJECT">@%2% = $%1%->project(qw(%3*%));</__MACRO>
<__MACRO NAME="FILTER">$%2% = $%1%->filter(sub {%2*%});</__MACRO>

<__MACRO AREA="1" NAME="IFNULL"><__FWD MIN="1" MAX="1" PUSH="if-then">if (!$%1% || $%1%->none) {</__FWD>
<__REV MAX="0"><__ALIAS>ENDIF</__ALIAS></__REV>
</__MACRO>
<__MACRO AREA="1" NAME="IFNOTNULL"><__FWD MIN="1" MAX="1" PUSH="if-then">unless (!$%1% || $%1%->none) {</__FWD>
<__REV MAX="0"><__ALIAS>ENDIF</__ALIAS></__REV>
</__MACRO>

<__MACRO AREA="1" NAME="IF"><__FWD MIN="1" PUSH="if-then">if (%1*%) {</__FWD>
<__REV MAX="0"><__ALIAS>ENDIF</__ALIAS></__REV>
</__MACRO>

<__MACRO AREA="1" BLOCK="for" NAME="FOR">
<__FWD MIN="1" MAX="4">
<__DO MAX="1">foreach (1 .. %1%) {</__DO>
<__DO MIN="2" MAX="2">foreach $%1% (1 .. %2%) {</__DO>
<__DO MIN="3" MAX="3">foreach $%1% (%2% .. %3%) {</__DO>
<__DO MIN="4" MAX="4">for ($%1% = %2%; $%1% &lt;= %3%; $%1% += %4%) {</__DO>
</__FWD>
<__REV>}</__REV>
</__MACRO>

<__MACRO AREA="1" BLOCK="foreach" NAME="FOREACH">
<__FWD MIN="2">foreach $%1% (qw(%2*%)) {</__FWD>
<__REV>}</__REV>
</__MACRO>

<__MACRO POP="for,foreach" NAME="NEXT">}</__MACRO>
<__MACRO BROTHER="for,foreach" NAME="BREAK">last;</__MACRO>
<__MACRO BROTHER="for,foreach" NAME="CONTINUE">next;</__MACRO>

<__MACRO MAX="0" POP="fetch" NAME="LOOP">}</__MACRO>
<__MACRO MAX="0" POP="if-then, if-then-else" NAME="ENDIF">}</__MACRO>
<__MACRO MAX="0" NAME="ELSE"><__POP>if-then</__POP>
<__PUSH>if-then-else</__PUSH>
<__DO>} else {</__DO></__MACRO>

<__MACRO NAME="BREAK">last;</__MACRO>
<__MACRO NAME="CONTINUE">next;</__MACRO>

<__MACRO NAME="FILTER">$%2% = $%1%->filter(sub {%3*%;});</__MACRO>

<__MACRO NAME="OUT"><__MACRO PRIVATE="1" NAME="TAG">print &amp;outhtmltag("%1%", %2%);</__MACRO></__MACRO>

<__MACRO NAME="IMG">
	<__MACRO PARAMS="1" MANDATORY="SRC" SCOPE="1" NAME="RND">
<__DO>my @ims = split(/,\s*/, $tags{'SRC'}); my $f = $ims[int(rand() * ($#ims + 1))];
		$tags{'SRC'} = $f; </__DO>
		<__INCLUDE>OUT TAG IMG %%tags</__INCLUDE>
	</__MACRO>
</__MACRO>

<__MACRO NAME="SWITCH">
	<__MACRO AREA="1" BLOCK="switch" SCOPE="1" NAME="CASE">
		<__FWD><__DO>my %%__htpl_cases, @__htpl_cases_scope;
my $__htpl_cases_defopt, $__htpl_cases_default, $__htpl_cases_choose,
$__htpl_case_last = 0; 
		$__htpl_cases_choose = eval("%1*%"); 
		{</__DO></__FWD>
		<__REV>}; my $__htpl_proc = $__htpl_cases{$__htpl_cases_choose}
				|| $__htpl_cases_default;
			&amp;$__htpl_proc if (ref($__htpl_proc) =~ /CODE/);
		</__REV>
	</__MACRO>
	<__MACRO AREA="1" BLOCK="random-switch" SCOPE="1" NAME="RND">
	<__FWD><__INCLUDE>SWITCH CASE</__INCLUDE></__FWD>
	<__REV><__DO>}; my @__htpl_case_keys = keys %%__htpl_cases;
        my $__htpl_rcase = int(rand(@__htpl_case_keys));
	$__htpl_cases_choose = $__htpl_case_keys[$__htpl_rcase]; {</__DO>
	<__INCLUDE DIR="REV">SWITCH CASE</__INCLUDE></__REV>
	</__MACRO>	
</__MACRO>

<__MACRO BROTHER="switch" NAME="CASE">
<__DO>}; @__htpl_cases_scope = (%1*%);
       @__htpl_cases_scope =
         defined($__htpl_case_last) ? ($__htpl_case_last + 1) : ()
         unless (@__htpl_cases_scope);
      @__htpl_cases_scope = ( '__' . ++$__htpl_cases_defopt)
        unless (@__htpl_cases_scope &amp;&amp;
        !@__htpl_cases{@__htpl_cases_scope});
</__DO>
<__DO MIN="1">$__htpl_case_last = (!$#__htpl_cases_scope &amp;&amp;
$__htpl_cases_scope[0] =~ /^\d+$/) ? $__htpl_cases_scope[0] : undef; 
</__DO>
<__DO MAX="0">$__htpl_case_last++;</__DO>
<__DO>@__htpl_cases{@__htpl_cases_scope} = revmap \@__htpl_cases_scope,
sub {</__DO></__MACRO> 
<__MACRO BROTHER="switch" MAX="0" NAME="DEFAULT">}; 
$__htpl_cases_default = sub
{</__MACRO>


<__MACRO NAME="TIME">
	<__MACRO NAME="MODIFIED">print scalar(localtime(&amp;lastmodified()));</__MACRO>
	<__MACRO NAME="NOW">print scalar(localtime);</__MACRO>
</__MACRO>

<__MACRO NAME="COUNTER">print &amp;increasefile("%1%");</__MACRO>

<__MACRO NAME="END">
<__ALIAS DIR="REV">%1*%</__ALIAS>
</__MACRO>

<__MACRO AREA="1" SCOPE="1" NAME="TRY"><__FWD PUSH="try">
my $__htpl__try__sub = sub {
</__FWD>
<__REV POP="catch"><__DO>};
$@ = undef; 
eval '&amp;$__htpl__try__sub;';
if ($@) {
	foreach (keys %%__htpl_handler) {
		my $v = $__htpl_handler{$_};
		if ($@ =~ /$_/ &amp;&amp; ref($v) =~ /CODE/) {
			&amp;$v($@);
			goto __htpl_try_lbl%id%;
		} 
	} 
        if (ref($__htpl_default_handler) =~ /CODE/) {
		&amp;$__htpl_default_handler;
		goto __htpl_try_lbl%id%;
	}
	die $@;
__htpl_try_lbl%id%:
} 
</__DO></__REV>
</__MACRO>
<__MACRO BROTHER="try,catch" CHANGE="catch" NAME="CATCH"><__DO>};
</__DO>
<__DO MAX="0">$__htpl_default_handler = sub {$_ = shift; </__DO>
<__DO MIN="1">$__htpl_handler{"%1*%"} = sub {$_ = shift; </__DO>
</__MACRO>
<__MACRO NAME="THROW">
%#line %line% %page%
die "%1*%";
%#line %rlineplus1% %script%
</__MACRO>

<__MACRO BLOCK="mail" AREA="1" SCOPE="1" NAME="MAIL">
	<__FWD PARAMS="1" MANDATORY="FROM,TO,SUBJECT">
	<__DO>
		my %%mailtags = %%tags;
		my %%params = %%{$mailtags{'params'}};
		&amp;begintransaction();
	</__DO>
	</__FWD>
	<__REV>
		$message = &amp;endtransaction();
		$message = &amp;subhash($message, '#', %%params)
			if ($mailtags{'params'});
		delete $mailtags{'params'};
		&amp;sendmail('Msg' => $message, %%mailtags);
	</__REV>
</__MACRO>

<__MACRO NAME="PUBLISH">&amp;publish(%%$%1%);</__MACRO>
<__MACRO NAME="NET">
	<__PRE>use HTML::HTPL::Client;</__PRE>
	<__MACRO MIN="1" MAX="3" NAME="SETUP">$htpl_net_obj = HTML::HTPL::Client->setup("%1%", "%2%", "%3%");</__MACRO>
	<__MACRO MIN="2" MAX="3" NAME="GET">$%1% = $htpl_net_obj->get("%2%", "%3%");</__MACRO>
</__MACRO>
<__MACRO BLOCK="procedure" AREA="1" NAME="PROC">
	<__FWD MIN="1"><__DO>sub %1% (%?$-1%) {</__DO>
		<__DO MIN="2">my (%2!%) = @_;</__DO>
       </__FWD>
	<__REV>
}
	</__REV>
</__MACRO>

<__MACRO BLOCK="method" AREA="1" BROTHER="class" NAME="METHOD">
	<__FWD MIN="1">
                <__DO>
#CLSUTILS OTHER
                sub __shadow__%1% {
SYNC
</__DO>
		<__DO MIN="2">my (%2!%) = @_;</__DO>
       </__FWD>
	<__REV>}</__REV>
</__MACRO>
<__MACRO AREA="1" BLOCK="class" NAME="CLASS">
<__FWD MIN="1">
	<__BLOCK ASSERT="%1:2%">
	<__DO>
	package %1:1%;
	@ISA = split(/:/, "%1%");
	shift @ISA;
        package %1:1%::__shadow__;
        @ISA = map { "${_}::__shadow__"; } @%1:1%::ISA;

	</__DO>
	<__SET VALUE="%1:1%" VAR="cls"/>
	</__BLOCK>
	<__BLOCK ASSERT="! %1:2%">
	<__DO>
	package %1%;
	</__DO>
	<__SET VALUE="%1%" VAR="cls"/>
	</__BLOCK>
	<__DO>
	use HTML::HTPL::Munge qw(%2*%);
	</__DO>
	<__DO>	sub set {
	my $self = shift;
	my %%hash = @_;
	foreach (keys %%hash) {
		$self->{$_} = $hash{$_};
	}
}

#CLSUTILS OTHER

sub __shadow__clone {
	require Clone;
	Clone::clone($self);
}

</__DO>
</__FWD>
<__REV NOOP="1"/>
</__MACRO>

<__MACRO PRIVATE="1" NAME="CLSUTILS">
	<__MACRO NAME="MINE"><__INCLUDE>CLSUTILS IMP</__INCLUDE>
	<__DO>package %$cls%;</__DO></__MACRO>
	<__MACRO NAME="OTHER"><__INCLUDE>CLSUTILS IMP</__INCLUDE>
        <__DO>package %$cls%::__shadow__;</__DO></__MACRO>
	<__MACRO NAME="IMP"><__IMPORT SCOPE="class" VAR="cls"/></__MACRO>
</__MACRO>

<__MACRO AREA="1" BLOCK="contsructor" BROTHER="class" NAME="CONSTRUCTOR">
	<__FWD>
<__IMPORT SCOPE="class" VAR="constructor"/>
<__CROAK ASSERT="%$constructor%">Only one constructor per class! Previous at %$constructor%</__CROAK>
<__SET VALUE="%line%" VAR="constructor"/>
<__EXPORT SCOPE="class" VAR="constructor"/>
<__DO>
#CLSUTILS MINE
sub new {
	%$cls%::__shadow__::new(@_);
}
#CLSUTILS OTHER
sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	unshift(@_, $self);
SYNC
	</__DO>
	<__DO MIN="1">
	my (%1!%) = @_;</__DO></__FWD>
	<__REV>    $self;
}</__REV>
</__MACRO>
<__MACRO AREA="1" BLOCK="destructor" BROTHER="class" NAME="DESTRUCTOR">
<__FWD MAX="0">
<__IMPORT SCOPE="class" VAR="destructor"/>
<__CROAK ASSERT="%$destructor%">Only one destructor per class! Previous at %$destructor%</__CROAK>
<__SET VALUE="%line%" VAR="destructor"/>
<__EXPORT SCOPE="class" VAR="destructor"/>
<__DO>
#CLSUTILS MINE	
	sub DESTROY {
SYNC
	</__DO>
</__FWD>
	<__REV>}</__REV>
</__MACRO>
<__MACRO MIN="3" SCOPE="1" NAME="GRAPH"><__PRE>use HTML::HTPL::Graph;</__PRE>
<__DO>
	my $g = new HTML::HTPL::Graph;
	$g->set('data' => [$%1%->project("%2%")]);
	$g->set('labels' => [$%1%->project("%3%")]);
</__DO>
<__DO MIN="4">
	$g->set('width' => %4%);
</__DO>
<__DO MIN="5">
	$g->set('cols' => %5%);
</__DO>
<__DO MIN="6">
	$g->set('legend' => [split(/:/, "%6*%")]);
</__DO>
<__DO>
	print $g->ashtml;
</__DO></__MACRO>

<__MACRO MIN="1" NAME="CALL">&amp;%1%(%2, *%);</__MACRO>

<__MACRO MIN="1" NAME="COPY">&amp;include(qw(%1*%));</__MACRO>

<__MACRO NAME="PTS"><__PRE>use RPC::PlClient;</__PRE>
<__MACRO MIN="2" MAX="3" SCOPE="1" NAME="SET">
my @t = split(/:/, "%1%");
push(@t, $HTML::HTPL::Config::htpl_pts_port);

$HTML::HTPL::pts_obj = new RPC::PlClient(
             peeraddr => $t[0],
             peerport => $t[1],
             user => "%2%",
             password => "%3%",
             application => "pts",
             version => 1.0);
</__MACRO>
<__MACRO MIN="2" NAME="CALL">$%1% = $HTML::HTPL::pts_obj->Call("%1%", qw(%3*%));</__MACRO>
<__MACRO MIN="2" NAME="CREATE">$%1% = $HTML::HTPL::pts_obj->ClientObject("%2%", "new",
                      qw(%3*%));</__MACRO>
<__MACRO MIN="3" MAX="3" NAME="POOL">$%1% = $HTML::HTPL::pts_obj->ClientObject("%2%", 
	"getObject", "%3%");</__MACRO>
</__MACRO>

<__MACRO AREA="1" NAME="REM" BLOCK="rem"><__FWD>&amp;begintransaction;</__FWD>
<__REV>&amp;endtransaction;</__REV></__MACRO>

<__MACRO NAME="DEFINE" AREA="1" BLOCK="define">
<__FWD MIN="1" MAX="1">
<__SET VALUE="%1%" VAR="var"/>
<__DO>&amp;begintransaction;</__DO></__FWD>
<__REV>
$%$var% = &amp;endtransaction; 
</__REV>
</__MACRO>
<__MACRO NAME="DIE">
&amp;htdie("%1*%");
</__MACRO>

<__MACRO NAME="SERVBOXEN" PRIVATE="1">
<__MACRO NAME="DOIT" MIN="2" MAX="2">
&amp;html_selectbox({'name' => "%1%"}, $%1%->project(sub {
($_->getcol(0), $_->getcol(%2%));
}));
</__MACRO>
<__MACRO NAME="DECIDE" MIN="2">
<__INCLUDE MIN="3">%2*%</__INCLUDE>
<__INCLUDE MIN="3">SERVBOXEN DOIT %4% %1%</__INCLUDE>
<__INCLUDE MAX="2">SERVBOXEN DOIT %2% %1%</__INCLUDE>
</__MACRO>
</__MACRO>

<__MACRO NAME="LISTBOX" SCOPE="1">
<__ALIAS>SERVBOXEN DECIDE 1 %1*%</__ALIAS>
</__MACRO>
<__MACRO NAME="COMBOBOX" SCOPE="1">
<__ALIAS>SERVBOXEN DECIDE 0 %1*%</__ALIAS>
</__MACRO>

<__MACRO NAME="ASSERT" MIN="1">
die "Assertion failed: (%-1*%)" unless (%1*%);
</__MACRO>
<__MACRO NAME="REDIRECT" MIN="1" MAX="1">&amp;redirect("%1%");</__MACRO>
<__MACRO NAME="CONNECTION" MIN="1">
        <__DO>
        *HTML::HTPL::htpl_db_obj = \$%1%;
        </__DO>
        <__INCLUDE MIN="3">SQL %2*%</__INCLUDE>
</__MACRO>
<__MACRO NAME="AUTH_CREATE">
use HTML::HTPL::ACL;
HTML::HTPL::ACL::CreateDDL($HTML::HTPL::htpl_db_obj->{'dbh'});
</__MACRO>
	
<__MACRO NAME="AUTH">
        <__PRE>use HTML::HTPL::ACL;
	$HTML::HTPL::acl = new
		HTML::HTPL::ACL($HTML::HTPL::htpl_db_obj->{'dbh'});</__PRE>
        <__MACRO NAME="LOGIN" MIN="2" MAX="2">
                $HTML::HTPL::acl->Login("%1%", "%2%");
        </__MACRO>
        <__MACRO NAME="IFLOGIN" MIN="2" MAX="2">
                <__INCLUDE>AUTH LOGIN %1*%</__INCLUDE>
                <__INCLUDE>AUTH IFLOGGED</__INCLUDE>
        </__MACRO>
        <__MACRO NAME="REALM" MIN="1" MAX="1">
                $HTML::HTPL::authorized = undef;
                $REALM = "%1%";
                if ($session{'username'}) {
                        $HTML::HTPL::authorized =
$HTML::HTPL::acl->{'acl'}->IsAuthorized($session{'username'}, $REALM);
                }
        </__MACRO>
        <__MACRO NAME="IFLOGGED" AREA="1">
                <__FWD MAX="0" PUSH="if-then">if
	($session{'username'}) {</__FWD>
                <__REV><__ALIAS>ENDIF</__ALIAS></__REV>
        </__MACRO>
        <__MACRO NAME="IFNOTLOGGED" AREA="1">
                <__FWD MAX="0" PUSH="if-then">unless
	($session{'username'}) {</__FWD>
                <__REV><__ALIAS>ENDIF</__ALIAS></__REV>
        </__MACRO>
        <__MACRO NAME="IFAUTHORIZED" AREA="1">
                <__FWD MAX="0" PUSH="if-then">if
	($HTML::HTPL::authorized) {</__FWD>
                <__REV><__ALIAS>ENDIF</__ALIAS></__REV>
        </__MACRO>
        <__MACRO NAME="IFUNAUTHORIZED" AREA="1">
                <__FWD MAX="0" PUSH="if-then">unless
	($HTML::HTPL::authorized) {</__FWD>
                <__REV><__ALIAS>ENDIF</__ALIAS></__REV>
        </__MACRO>
        <__MACRO NAME="ADDUSER" MIN="2" MAX="3">
                <__DO MAX="2">$HTML::HTPL::acl->AddUser("%1%", "%2%");</__DO>
                <__DO MIN="3" ASSERT="%1% - 'crypted'">$HTML::HTPL::acl->AddUser("%1%", "%2%", 1);</__DO>
                <__CROAK MIN="3" ASSERT="%1% !- 'crypted'">Must use two arguments or 'crypted' as first argument</__CROAK>
        </__MACRO>
</__MACRO>
<__MACRO NAME="EXIT">exit;</__MACRO>
<__MACRO NAME="REWIND">&amp;rewind;</__MACRO>
<__MACRO NAME="INIT" AREA="1" BLOCK="init">
        <__FWD ONCE="1">sub InitDoc {</__FWD>
        <__REV>}</__REV>
</__MACRO>
<__MACRO NAME="CLEANUP" AREA="1" BLOCK="clean">
        <__FWD ONCE="1">sub CleanDoc {</__FWD>
        <__REV>}</__REV>
</__MACRO>
<__MACRO NAME="REQ_SYMBOL" PRIVATE="1" NOOP="1">
	<__PRE>use Symbol;</__PRE>
</__MACRO>
<__MACRO NAME="FILE" BLOCK="file" AREA="1">
	<__FWD MIN="1" MAX="1"><__INCLUDE>REQ_SYMBOL</__INCLUDE>
		push(@HTML::HTPL::file_saves, select);
		$HTML::HTPL::new_file = gensym;
		open($HTML::HTPL::new_file, ">%1%");
		select $HTML::HTPL::new_file;
	</__FWD>
	<__REV>
		$HTML::HTPL::new_file = select;	
		select pop @HTML::HTPL::file_saves;
		close($HTML::HTPL::new_file);
		undef $HTML::HTPL::new_file;
		undef @HTML::HTPL::file_saves unless @HTML::HTPL::file_saves;
	</__REV>
</__MACRO>
<__MACRO NAME="DISPOSE" MIN="1">
foreach (%1!%) {
	undef %$_;
	undef $_;
}
</__MACRO>
<__MACRO NAME="MERGE" MIN="2">
foreach (%2!%) {
	$%1%->append($_);
}
</__MACRO>
</HTPL>
