# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test;
use strict;
use Test::More qw/no_plan/;

BEGIN {
    use_ok('XMail::Ctrl');
}

    my $XMail_admin      = $ENV{XMAIL_CTRL_ADMIN};
    my $XMail_pass       = $ENV{XMAIL_CTRL_PASS};
    my $XMail_port       = "6017";
    my $XMail_host       = $ENV{XMAIL_CTRL_HOST};
    my $test_domain      = $ENV{XMAIL_CTRL_TESTHOST};

    my $test_user        = 'cpan';
    

if ($ENV{XMAIL_CTRL_TESTHOST}) {
    
    my $xmail = XMail::Ctrl->new(
                ctrlid   => "$XMail_admin",
                ctrlpass => "$XMail_pass",
                port     => "$XMail_port",
                host     => "$XMail_host",
                debug    => 1
                                 ) or die $!;
    ok( ref($xmail) eq 'XMail::Ctrl' , "created XMail::Ctrl object");
    
    
    
    ok( $xmail->domainadd( { domain => $test_domain } ) , 'added a domain' );
   
        my $command_ok = $xmail->useradd(
            {
                username => "$test_user",
                password => 'test',
                domain   => "$test_domain",
                usertype => 'U'
            }
            );
    
    ok( $command_ok , "sucessfully add a user to test domain");
    
    # warn $command_ok , "\n";
    
    my $list = $xmail->userlist( { domain => $test_domain } );
    
    ok( scalar(@$list) > 0 , "had as lest one user in test domain" );
    
    #foreach my $row (@{$list}) {
    #    warn join("\t",@{$row}) . "\n";
    #}
    ok( $xmail->domaindel( { domain => $test_domain } ) , 'deleted a domain' ); 
}


#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

