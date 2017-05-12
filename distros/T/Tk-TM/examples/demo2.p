#!perl -w

use Tk::TM::wApp;
use DBI;
#$Tk::TM::Common::Debug =1;
#$Tk::TM::Lang::Lang ='ru';

my $mw  =new Tk::TM::wApp();

$mw->setscr(0,'Drivers',\&Drivers);
$mw->setscr(1,'Data Sources',\&DataSources);
$mw->setscr(2,'Login',\&Login, {-edit=>1});
$mw->setscr(3,'Tables',\&Tables);
$mw->setscr(4,'Description',\&Descriptions);
$mw->setscr(4,'Data - SQL & Widget Generator',\&DataSQG);
$mw->setscr(4,'Data - Simple SQL',\&DataSQL);
$mw->setscr(4,'Data - Simplest',\&DataSimplest);
$mw->setscr(0,'Exit!',sub{Tk::exit});
$mw->Start();

Tk::MainLoop;



sub Drivers {
 #print "Drivers(",join(',',@_),")\n";
 my ($self, $cmd, $opt, $mst) =@_;
 return(1) if $cmd =~/stop/;

 my $wgt=$self->{-wgscr}->tmTable(
          -rowcount=>10
         ,-colspecs=>[['Name','Entry']]
         )->pack;

 my $do;
 if (!$self->{-dos}) {
    $do =new Tk::TM::DataObject();
    $self->{-dos} =[$do];
 }
 else {
    $do =$self->{-dos}->[0];
 }

 $do->set(-wgtbl=>$wgt
         ,-mdedt=>0
         ,-cbdbRead=>sub{
                      foreach my $v (DBI->available_drivers) {
                        $_[0]->dsRowFeed([$v]);
                      }; 1
                     }
         );
 
 $do->Retrieve('#reread')
}



sub DataSources {
 #print "DataSources(",join(',',@_),")\n";
 my ($self, $cmd, $opt, $row, $fld, $wg, $dta, $new) =(shift, shift, @_);

 if    ($cmd eq 'stop')   {
       return(1)
 }
 elsif ($cmd eq 'start')  {

       my $wgt=$self->{-wgscr}->tmTable(
            -rowcount=>10
           ,-colspecs=>[['Name','Entry']]
           )->pack;

       my $do;
       if (!$self->{-dos}) {
          $do =new Tk::TM::DataObject();
          $self->{-dos} =[$do];
       }
       else {
          $do =$self->{-dos}->[0];
       }

       my $rwm =$row->{-dos}->[0]->dsRowDta();
       $do->{-parm}->{dsn} =$rwm->[0];
       $self->{-title} =$do->{-parm}->{dsn};

       $do->set(-wgtbl=>$wgt
           #   ,-mdedt=>0
               ,-cbcmd=>\&DataSources
               );
       $do->Retrieve('#reread')
 }
 elsif ($cmd eq 'dbRead') {
       if ($self->{-parm}->{dsn} =~/XBase/i) {$self->dsRowFeed(['DBI:XBase:.'])}
       foreach my $v (DBI->data_sources($self->{-parm}->{dsn})) {
         $self->dsRowFeed([$v]);
       }; 1
 }
 else  {return $self->doDefault($cmd, @_)}
 }



sub Login {
 my ($self, $cmd, $opt, $mst) =@_;

 if ($cmd =~/start/) {
    $self->{-parm}->{-dsn} =$mst->{-do}->dsRowDta()->[0];
 }

 Tk::TM::wApp::DBILogin($self, $cmd, $opt, $mst)
}



sub Tables {
 #print "Tables(",join(',',@_),")\n";
 my ($self, $cmd, $opt, $mst) =@_;
 return(1) if $cmd =~/stop/;

 my $wgt=$self->{-wgscr}->tmTable(
          -rowcount=>10
         ,-colspecs=>[['Qualifier','Entry']
                     ,['Owner'    ,'Entry']
                     ,['Name'     ,'Entry']
                     ,['Remarks'  ,'Entry']]
         )->pack;

 my $do;
 if (!$self->{-dos}) {
    $do =new Tk::TM::DataObject();
    $self->{-dos} =[$do];
 }
 else {
    $do =$self->{-dos}->[0];
 }

 $do->set(-wgtbl=>$wgt
#         ,-mdedt=>0
          ,-cbdbRead=>sub{
              $_[0]->dsRowFeedAll($_[0]->DBICmd('table_info')->fetchall_arrayref)
            }
         );
 
 $do->Retrieve('#reread')
}



sub DataSQG {
 #print "DataSQG(",join(',',@_),")\n";
 my ($self, $cmd, $opt, $mst) =@_;
 return(1) if $cmd =~/stop/;

 my $do;
 if (!$self->{-dos}) {
    $do =new Tk::TM::DataObject(-mdedt=>1);
    $self->{-dos} =[$do];
 }
 else {
    $do =$self->{-dos}->[0];
 }

 my $rwm =$mst->{-dos}->[0]->dsRowDta();
 my $tbl =(defined($rwm->[1]) ? $rwm->[1] .'.' : '') .($rwm->[2] ||'');

 if ($tbl && (!$do->{-sqgfd} || $tbl ne $do->{-sqgsf})) {
    $do->DBIDesc("select * from $tbl");
    $do->{-sqgfd} =[];
    for (my $i =0; $i <=$#{@{$do->{-dbfds}}}; $i++) {
        push @{$do->{-sqgfd}},
          ['cru' .($i<5 ? 'pktb' : 'b'), undef, $do->{-dbfds}->[$i]->{NAME},undef,undef,undef,$do->{-dbfds}->[$i]->{NAME},undef,undef,'Entry'];
        last if $i >8;
    }
    $do->{-sqgsf} =$tbl;
    $do->{-sqgsj} =undef;
    $do->{-sqgsc} =undef;
    $do->{-sqgso} =undef;
    $self->{-title} =$tbl;
 }


 $do->set(-sqgscr=>$self->{-wgscr})->pack;

 $do->Retrieve('#reread')
}


sub DataSQL {
 #print "DataSQL(",join(',',@_),")\n";
 my ($self, $cmd, $opt, $mst) =@_;
 return(1) if $cmd =~/stop/;

 my $do;
 if (!$self->{-dos}) {
    $do =new Tk::TM::DataObject(-mdedt=>0);
    $self->{-dos} =[$do];
 }
 else {
    $do =$self->{-dos}->[0];
 }

 my $rwm =$mst->{-dos}->[0]->dsRowDta();
 my $tbl =(defined($rwm->[1]) ? $rwm->[1] .'.' : '') .($rwm->[2] ||'');

 if ($tbl && (!$do->{-sqlsel} || $tbl ne $self->{-title})) {
    $do->set(-sqlsel=>"select * from $tbl");
    $do->DBIDesc($do->{-sqlsel});
    $self->{-title} =$tbl;
 }

 my $wgd=[];
 for (my $i =0; $i <=$#{@{$do->{-dbfds}}}; $i++) {
     push @$wgd, [$do->{-dbfds}->[$i]->{NAME}, 'Entry'];
     last if $i >5;
 }

 my $wgt=$self->{-wgscr}->tmTable(
          -rowcount=>10
         ,-colspecs=>$wgd
         )->pack;

 $do->set(-wgtbl=>$wgt);
 
 $do->Retrieve('#reread')
}


sub DataSimplest {
 #print "DataSimplest(",join(',',@_),")\n";
 my ($self, $cmd, $opt, $mst) =@_;
 return(1) if $cmd =~/stop/;

 my $do;
 if (!$self->{-dos}) {
    $do =new Tk::TM::DataObject(-mdedt=>0);
    $self->{-dos} =[$do];
 }
 else {
    $do =$self->{-dos}->[0];
 }

 my $rwm =$mst->{-dos}->[0]->dsRowDta();
 my $tbl =(defined($rwm->[1]) ? $rwm->[1] .'.' : '') .($rwm->[2] ||'');
 if ($tbl) {$self->{-wgapp}->{-parm}->{table} =$tbl}
 else      {$tbl =$self->{-wgapp}->{-parm}->{table}}
 $self->{-title} =$tbl;

 my $wgt=$self->{-wgscr}->tmTable(
          -rowcount=>10
         ,-colspecs=>[['Col1' ,'Entry']
                     ,['Col2' ,'Entry']
                     ,['Col3' ,'Entry']
                     ,['Col4' ,'Entry']]
         )->pack;

 $do->set(-wgtbl=>$wgt
         ,-sqlsel=>"select * from $tbl"
         );
 
 $do->Retrieve('#reread')
}


sub Descriptions {
 #print "Descriptions(",join(',',@_),")\n";
 my ($self, $cmd, $opt, $mst) =@_;
 return(1) if $cmd =~/stop/;

 my $wgt=$self->{-wgscr}->tmTable(
          -rowcount=>10
         ,-colspecs=>[['NAME'      ,'Entry']
                     ,['TYPE'      ,'Entry',-width=>5]
                     ,['PRECIS'    ,'Entry',-width=>5]
                     ,['SCALE'     ,'Entry',-width=>5]
                     ,['NULLABLE'  ,'Entry',-width=>5]]
         )->pack;

 my $do;
 if (!$self->{-dos}) {
    $do =new Tk::TM::DataObject();
    $self->{-dos} =[$do];
 }
 else {
    $do =$self->{-dos}->[0];
 }

 my $rwm =$mst->{-dos}->[0]->dsRowDta();
 my $tbl =(defined($rwm->[1]) ? $rwm->[1] .'.' : '') .($rwm->[2] ||'');
 if ($tbl) {$self->{-wgapp}->{-parm}->{table} =$tbl}
 else      {$tbl =$self->{-wgapp}->{-parm}->{table}}
 $self->{-title} =$tbl;

 $do->set(-wgtbl=>$wgt
         ,-mdedt=>0
         ,-cbdbRead=>sub{
            my $dbs =$Tk::TM::Common::DBH->prepare("select * from $tbl");
               $dbs->execute;
            eval {
              for (my $i =$[; $i <$dbs->{NUM_OF_FIELDS} +$[; $i++) {
                 my $dsc ={};
                 eval {$dsc->{NAME}      =$dbs->{NAME}->[$i]};
                 eval {$dsc->{TYPE}      =$dbs->{TYPE}->[$i]};
                 eval {$dsc->{SCALE}     =$dbs->{SCALE}->[$i]};
                 eval {$dsc->{PRECISION} =$dbs->{PRECISION}->[$i]};
                 eval {$dsc->{NULLABLE}  =$dbs->{NULLABLE}->[$i]};
                 $_[0]->dsRowFeed([$dsc->{NAME},$dsc->{TYPE},$dsc->{PRECISION},$dsc->{SCALE},$dsc->{NULLABLE}]);
              }
            };
            $dbs->finish; 1;
           }
         );
 
 $do->Retrieve('#reread')
}