#!/usr/local/bin/perl

#	@(#)Show.cgi	1.2	06/11/97
#
#	Show.cgi - display the text of triggers, stored procs, views,
#		   and defaults in html format.
#
#	Copyright (c) 1997, Michael Peppler
#		All rights reserved.
#



use strict;
use Sybase::DBlib;
use SybWWW;

use CGI;

my $query = new CGI;

print $query->header;
print $query->start_html(-title => "Show a Sybase Object");

my $server   = $query->param('server');
my $database = $query->param('database');

my $state = $query->param('__state__') || 0;

if(!$database) {
    error("Please supply the <b>database</b> parameter.<p>");
}

my $dbh = new Sybase::DBlib "sa", undef, $server;
($dbh->dbuse($database) == SUCCEED) || error("The database <b>$database</b> deosn't exist");


SWITCH_STATE: while(1) {
    ($state == 0) && do {
	my($values, $labels) = getObjects();
	print "<h1>Show a Sybase objects definition:</h1>\n";
	print "<p><p>Please select an object:<p>\n";
	print $query->start_form;
	print $query->scrolling_list(-name=>'object',
				     '-values'=>$values,
				     -labels=>$labels,
				     -size=>10);
	
	$query->param(-name=>'__state__', '-values'=>1);
	print $query->hidden(-name=>'__state__');
	print $query->hidden(-name=>'database');
	print $query->hidden(-name=>'server');

	print $query->submit;
	print $query->end_form;

	last SWITCH_STATE;
    };

    ($state == 1) && do {
	print "<h1>Show a Sybase object's definition:</h1>\n";

	my $objId = $query->param('object');
	my $html = getText($objId);
	print $html;
	

	last SWITCH_STATE;
    };
}

print $query->end_html;
exit(0);
    

sub getObjects {
    $dbh->dbcmd("
select	distinct 'obj' = o.name, 'user' = u.name, o.id, o.type
from	dbo.sysobjects o, dbo.sysusers u, dbo.sysprocedures p
where	u.uid = o.uid and o.id = p.id and p.status & 4096 != 4096
order by o.name
");

    $dbh->dbsqlexec; $dbh->dbresults;
    my %dat;
    my @values;
    my %labels;
    my $value;
    while(%dat = $dbh->dbnextrow(TRUE)) {
	$value = "$dat{id} - $dat{type}";
	push(@values, $value);
	$labels{$value} = "$dat{user}.$dat{obj}";
    }

    (\@values, \%labels);
}

sub getText {
    my $objId = shift;

    $objId =~ s/[\D\-\s]+$//;
    $dbh->dbcmd ("select text from dbo.syscomments where id = $objId");
    $dbh->dbsqlexec; $dbh->dbresults;
	
    my $html = '';
    my $text;
    while(($text) = $dbh->dbnextrow) {
	$html .= $text;
    }
    TsqlToHtml($html);
}

sub TsqlToHtml {
    my $html = shift;
    $html =~ s/\n/<br>\n/g;

    $html =~ s/\b(as|begin|between|declare|delete|drop|else|end|exec|exists|go|if|insert|procedure|return|set|update|values|from|select|where|and|or|create|order by)\b/<b>$1<\/b>/ig;
    $html =~ s/\b(tinyint|smallint|int|char|varchar|datetime|smalldatetime|money|smallmoney|numeric|decimal|text|binary|varbinary|image)\b/<i>$1<\/i>/gi;

    $html =~ s/\t/\&nbsp;\&nbsp;\&nbsp;\&nbsp;/g;
    $html =~ s/ /\&nbsp;/sg;

    $html;
}



sub error {
    print "<h1>Error!</h1>\n";
    print @_;
    print $query->end_html;
    exit(0);
}
