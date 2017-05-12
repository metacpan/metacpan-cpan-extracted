#!/usr/bin/perl
# Sat Feb  7 03:02:37 CET 2004
use WWW::Orkut::Spider;
use Data::Dumper;

my $user = 'usern';
my $pass = 'passw';
#my $proxy = "http://proxy:8080/";
my $proxy = undef;
$|=0;

my $orkut = WWW::Orkut::Spider->new($proxy);
$orkut->login($user,$pass);
$orkut->get_myfriends();
$orkut->get_friendsfriends(1);


my $i=0;
print '<persons>'."\n";
foreach my $uid ( $orkut->users() ) { 
        $i++;
        if ($i>50) {
                # delay and relogin
                $i=0;
                sleep 7;
                $orkut->logout();
                $orkut->login($user,$pass);
        }
        
        print '<person uid="'.$uid.'" name="'.$orkut->name($uid).'">'."\n";
        print $orkut->get_xml_profile($uid);
        print $orkut->get_xml_communities($uid);
        print $orkut->get_xml_friendslist($uid);
        print '</person>'."\n";
}
print '</persons>'."\n";
