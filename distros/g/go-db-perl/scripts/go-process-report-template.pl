#!/usr/bin/perl

use strict;
use Data::Stag;
use DBIx::DBStag;

my $db;
while ($ARGV[0] =~ /^\-/) {
    my $opt = shift;
    if ($opt eq '-d') {
        $db = shift;
    }
}
my $sdbh = DBIx::DBStag->connect($db);
my $dbh = $sdbh->dbh;

my $f = shift @ARGV;

my $handler = ReportHandler->new;
my $struct = Data::Stag->parse(-file=>$f);
$handler->{struct} = $struct;
my $stag = Data::Stag->parse(-file=>$f, -handler=>$handler);
print $stag->xml;

exit 0;

package ReportHandler;

use base qw(Data::Stag::BaseHandler);

my $rownum = 0;
sub e_expand {
    my $self = shift;
    my $node = shift;
    my $sql_view = $node->find_view;
    my $name = $sql_view;
    my $sql;
    if (!$sql_view) {
        $sql_view = $node->get('.');
        $sql_view =~ s/\n/ /g;
        $sql = $sql_view;
        $name = $node->find_name;
    }
    else {
        $sql = "SELECT * FROM $sql_view";
    }
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    foreach (@{$sth->{NAME}}) {
        # this appear to be necessary..
    }
    my $rows = $sth->fetchall_arrayref();
    open(F,">$name.txt");
    foreach (@$rows) {
        print F join("\t",@$_),"\n";
    }
    close(F);
    $rownum=0;
    my $tbl = [table=>[hdrrow($sth->{NAME}),
                       (map {tblrow($_)} @$rows)]];
    return [div=>[['@'=>[[class=>'view']]],
                  [h3=>$name],
                  [a=>[['@'=>[[href=>"$name.txt"]]],['.'=>'download']]],
                  $tbl]];
#    return [span=>[
#                   [span=>[['@'=>[[class=>'label']]],['.'=>$sql_view]]],
#                   $tbl]];
}

sub e_h2 {
    my $self = shift;
    my $node = shift;
    return [h2=>[['@'=>[[id=>$node->data]]],['.'=>$node->data]]];
}

sub e_index {
    my $self = shift;
    my $node = shift;
    my $struct = $self->{struct};
    my @h2s = $struct->find_h2;
    return [ul=>[
                map {
                    [li=>[[a=>[['@'=>[[href=>"#".$_]]],['.'=>$_]]]]]
                } @h2s
            ]];
}

sub rowclass {
    $rownum = ($rownum+1) % 2;
    return ('odd_row','even_row')[$rownum];
    
}

sub tblrow {
    my $colvals = shift;
    return ['tr' => [ ['@'=>[[class=>rowclass()]]], map { $_ = sprintf("%.1e",$_) if /\d+e\-\d+/; [td=>$_] } @$colvals ]];
}

sub hdrrow {
    my $colvals = shift;
    return ['tr' => [ map { s/_/ /g; [th=>$_] } @$colvals ]];
}

