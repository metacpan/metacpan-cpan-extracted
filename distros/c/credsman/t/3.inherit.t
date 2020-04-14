# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl credsman.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More tests => 12;
use ExtUtils::testlib;
BEGIN { use_ok('credsman')};
#########################

use Net::FTP;

sub Connect_FTP {
    my $arg = shift;
    # Here your code to login or connect using user and password
    # The given Parameter has the {inherit} key, if you passit the function
    # will return the inherit to evaluete.
    note ('FTP Function');
    ok $arg->{user}     eq 'dlpuser@dlptest.com', 'User Ok';
    ok $arg->{password} eq 'SzMf7rTE4pCrf9dV286GuNe4N', 'Password Ok';
    ok $arg->{target}   eq 'ftp.dlptest.com', 'Target is okay';

    my $ftp = Net::FTP->new($arg->{target});
    ok( defined $ftp && $ftp->isa('Net::FTP'),"FTP object Okay");
    my $status = $ftp->login("$arg->{user}",$arg->{password});
    ok $status,"FTP is connected";

    if( ! $status ){
        print "Attempt : $arg->{attempt} of $arg->{limit}\n"; 
        print "$arg->{user} cannot login ".$ftp->message ."\n";
        return 1;
    }

    ${$arg->{inherit}} = $ftp; # to pass your FTP object
    ok( defined ${$arg->{inherit}} && ${$arg->{inherit}}->isa('Net::FTP'),"inherit FTP");
    return 0; # Success
}

my $credsname = credsman::work_name('credsman-ftp','ftp.dlptest.com');
credsman::RemoveCredentials($credsname);
ok $credsname eq '*[credsman-ftp]~[ftp.dlptest.com]*', 'Create Test Target FTP Name';
ok !credsman::SaveCredentials($credsname, 'dlpuser@dlptest.com','SzMf7rTE4pCrf9dV286GuNe4N');

my $inFTP = credsman::login( program  => 'credsman-ftp', 
       target   => 'ftp.dlptest.com',
       subref   => \&Connect_FTP,
       debug    => 0,
       undefine => 1,

);
ok  defined $inFTP, "is Defined inFTP";
ok( $inFTP && $inFTP->isa('Net::FTP'),"Login passed FTP Ojbect");
ok credsman::RemoveCredentials($credsname), 'Remove Test Credentials';
done_testing;