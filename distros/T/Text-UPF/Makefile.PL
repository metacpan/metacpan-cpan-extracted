use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


##GET INFO FROM USER
 sub get_info {
     %data = ();
     
     print "Word Wrap populated output to this many columns: (usually 80)\n";
     $data{'Column Length'} = <stdin>;
     
     print "Do you want UPF.pm to be able to retrieve forms from a database?  [yes/no]\n";
     $switch = <stdin>;
     if ($switch =~/^y/i){ 
     
         print "what's your database server?\n";
         $data{'Database Server'} = <stdin>;
     
         print "what type of database is it? [ex. Oracle, Sybase, MySQL .. etc]\n";
         $data{'Database Type'} = <stdin>;
     
         if ($data{'Database Type'} =~/^Oracle/i){
             print "what is the SID of the Oracle database containing the forms?\n";
             $data{'SID'} = <stdin>;
         }
     
         print "should I attempt to connect to this database on a non-standard port?  [yes/no]\n";
         $switch = <stdin>;
         if ($switch =~/^y/i){
             print "\twhich port?\n";
             $data{'Port'} = <stdin>;
         }
     
         print "what key in passwds.xml contains the username for db access?\n";
         $data{'User Key'} = <stdin>;
     
         print "what key in passwds.xml contains the password for db access?\n";
         $data{'Pass Key'} = <stdin>;
     
         print "Which table or view in this database contains the forms?\n";
         $data{'Form View'} = <stdin>;
     
         print "Which field in the table or view contains the form name?\n";
         $data{'Form Name'} = <stdin>;
     
         print "Which field in the table or view contains the form text?\n";
         $data{'Form Text'} = <stdin>;
     
         print "\nYour database may contain a standard disclaimer which is attached\n";
         print "to all outgoing emails. You can include this disclaimer in the text\n";
         print "of your letter by using the <pop>Disclaimer</pop> tag. Do you have such\n";
         print "a thing? [yes/no]\n";
         $switch = <stdin>;
         if ($switch =~/^y/i){
             print "\twhat is it's name?\n";
             $data{'Disclaimer'} = <stdin>;
             print "\tdo you wish to prefix each line of the disclaimer with quote charachter(s)?\n";
             $switch = <stdin>;
             if ($switch =~/^y/i){
                 print "\t\tplease enter your quote charachter(s):\n";
                 $data{'Disclaimer Quote'} = <stdin>;
             }
         }
     }
     
     print "\n\n=======NOTICE=======\n";
     print "The values you just entered are stored in a hash at the top of UPF.pm.\n";
     print "Portions of this data are also stored in SiteConfig.xml. Be aware that\n";
     print "if you change the data here you must also change it in SiteConfig.xml\n";
     print "and likewise if you edit SiteConfig.xml, you must change values here.\n";
     print "To edit the values here you may edit UPF.pm directly, or alternatively\n";
     print "rebuild the module.\n\n";
     
    #clean up the data
     foreach (keys %data){ chomp($data{$_}); }
     
    #write info to config.cache
     print "saving config data in config.cache\n";
     open (conf, ">./config.cache") || die ("can't write config data: $!\n");
     foreach (keys %data){ print conf "{$_}\t$data{$_}\n"; }
     close(conf);
     return (1);
 }
 
%REQUIRED_MODS	= (
    "Date::Parse"	=> 2.20
);

if (get_info()){
    WriteMakefile(
        'NAME'			=> 'Text::UPF',
        'VERSION_FROM'	=> 'UPF.pm',
        'ABSTRACT_FROM'	=> 'UPF.pod',
        'AUTHOR'		=> 'Andrew N. Hicox  <andrew@hicox.com>',
        'PREREQ_PM'		=> {
            Date::Parse			=> '2.20',
            Config::Framework	=> '2.4',
            DBIx::YAWM			=> '2.0.8',
            Text::Wrapper		=> '1.000'
        },
        'PM_FILTER'		=> "\$(PERL) ./insert_config_data"
    );
}else{
    WriteMakefile(
        'NAME'			=> 'Text::UPF',
        'VERSION_FROM'	=> 'UPF.pm',
        'ABSTRACT_FROM'	=> 'UPF.pod',
        'AUTHOR'		=> 'Andrew N. Hicox  <andrew@hicox.com>',
        'PREREQ_PM'		=> {
            Date::Parse		=> '2.20',
            Text::Wrapper	=> '1.000'
        },
        'PM_FILTER'		=> "\$(PERL) ./insert_config_data"
    );
}