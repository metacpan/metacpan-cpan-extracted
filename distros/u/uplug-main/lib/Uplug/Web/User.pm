# Copyright (C) 2004 Jörg Tiedemann  <joerg@stp.ling.uu.se>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package Uplug::Web::User;

use strict;
use Exporter;
use lib '/home/staff/joerg/user_perl/lib/perl5/site_perl/5.6.1/';
use Mail::Mailer;
use Uplug::Web::Process::Stack;

use vars qw(@ISA @EXPORT);

@ISA    = qw( Exporter);
@EXPORT = qw( ReadUserInfo );

our $UplugAdmin   = $ENV{UPLUGADMIN};
our $Uplug2Dir    = $ENV{UPLUGDATA};
our $CorpusDir    = $Uplug2Dir;
our $UserDataFile = $Uplug2Dir.'/.user';
our $PasswordFile = $Uplug2Dir.'/.htpasswd';

# my $IniDir=$CorpusDir.'/ini';
# my $CorpusFile=$IniDir.'/uplugUserStreams';


######################################################################

sub SendUserPassword{
    my $user=shift;
    my %UserData=();
    &ReadUserInfo(\%UserData,$user);

    if (not defined $UserData{$user}{Password}){
	return "Cannot find user '$user'! Please register first!\n";
    }
    &SendMail($user,'UplugWeb password',
	      "UplugWeb account: $user\nUplugWeb password: $UserData{$user}{Password}");
    return "Mail sent to $user!";
}


sub RemoveUser{
    my $user=shift;
    my %UserData=();
    &ReadUserInfo(\%UserData,$user);
    if (not -e "$CorpusDir/.recycled"){
	`mkdir $CorpusDir/.recycled`;
	`chmod 755 $CorpusDir/.recycled`;
	`chmod g+s $CorpusDir/.recycled`;
    }
    if (-e "$CorpusDir/.recycled/$user"){
	`rm -fr $CorpusDir/.recycled/$user`;
    }
    `mv $CorpusDir/$user $CorpusDir/.recycled/`;

    my $UserInfo=Uplug::Web::Process::Stack->new($UserDataFile);
    $UserInfo->remove($user);

    &SendMail($user,'UplugWeb account',
	      'Your UplugWeb account has been removed!');
}


sub EditUser{
    my $user=shift;
    my %UserData=();
#    &ReadUserInfo(\%UserData,$user);
    return "edit $user (not implemented yet!)";
}


sub ReadUserInfo{
    my $data=shift;
    my $user=shift;
    open F,"<$UserDataFile";
    while (<F>){
	chomp;
	my ($u,$f)=split(/\:/);
	$$data{$u}{info}=$f;
	if (not -e $f){$$data{$u}{status}='removed';}
	elsif ($user eq $u){
	    open U, '<:encoding(utf8)',$f;
#	    open U,"<$f";
	    while (<U>){
		chomp;
		my ($k,$v)=split(/\:/);
#		if ($k eq 'Password'){$$data{$u}{$k}='******';}
#		else{$$data{$u}{$k}=$v;}
		$$data{$u}{$k}=$v;
	    }
	    close U;
	}
    }
    close F;
}


sub SendMail{

    my ($to,$subject,$message)=@_;

    my $mailer=Mail::Mailer->new("sendmail");
    $mailer->open({From    => $UplugAdmin,
		   To      => $to,
		   Subject => $subject});
    print $mailer $message;
    $mailer->close();
}


sub SendFile{

    my ($to,$subject,$file)=@_;

    if (not -e $file){return 0;}

    my $mailer=Mail::Mailer->new("sendmail");
    $mailer->open({From    => $UplugAdmin,
		   To      => $to,
		   Subject => $subject});

    if ($file=~/\.gz$/){open F,"gzip -cd $file |";}
    else{open F,"<$file";}
    binmode (F);
    while (<F>){print $mailer $_;}
    $mailer->close();
}

