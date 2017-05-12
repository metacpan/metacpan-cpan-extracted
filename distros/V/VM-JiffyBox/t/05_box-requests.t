use strict;
use warnings;

use JSON;
use Test::More;
my $number_of_tests = 0; # ne need to count them!

use VM::JiffyBox;

my $domain     = 'https://api.jiffybox.de';
my $auth_token = 'AUTH_TOKEN';
my $version    = 'v1.0';

my $base_url   = "$domain/$auth_token/$version";

my $box_id     = 'BOX_ID';

# here is a list of all the requests to check
my %requests = (
                get_backups => { url  => "$base_url/backups/$box_id" },
                get_details => { url  => "$base_url/jiffyBoxes/$box_id" },
                start       => { url  => "$base_url/jiffyBoxes/$box_id",
                                 json => to_json( { status => 'START' } ),
                               },
                stop        => { url  =>"$base_url/jiffyBoxes/$box_id",
                                 json => to_json( { status=>'SHUTDOWN' } ),
                               },
                delete      => { url  => "$base_url/jiffyBoxes/$box_id" },
               );

##############
# FIRST TEST #
##############

# do a test that should fail!
# we hardcode this for "get_details"
my $hypervisor = VM::JiffyBox->new( token     => $auth_token,
                                    test_mode => 1,
                                  );

my $vm = $hypervisor->get_vm($box_id);

my $fresh_url = $vm->get_details()->{url};

$number_of_tests++;
isnt ($fresh_url,
      "$base_url/jiiiiiiiffyBoxes/$box_id",
      "false URL for get_details (non-historic)"
     );

###############
# SECOND TEST #
###############

# check all the requests with fresh objects
for my $method (keys %requests) {

    my $static_url = $requests{$method}->{url};

    my $hypervisor = VM::JiffyBox->new( token     => $auth_token,
                                        test_mode => 1,
                                      );

    my $vm = $hypervisor->get_vm($box_id);

    my $fresh_url = $vm->$method()->{url};

    $number_of_tests++;
    is ($fresh_url, $static_url, "URL for $method (non-historic)" );

    # also check for JSON if it exists
    if ( exists $requests{$method}->{json} ) {
        my $static_json = $requests{$method}->{json};
        my $fresh_json  = $vm->$method()->{json};
        $number_of_tests++;
        is_deeply ( $fresh_json,
                    $static_json,
                    "JSON for $method (non-historic)"
                  );
    }
}

##############
# THIRD TEST #
##############

# and also check all the requests with old objects
$hypervisor = VM::JiffyBox->new( token     => $auth_token,
                                 test_mode => 1,
                               );

$vm = $hypervisor->get_vm($box_id);

for my $method (keys %requests) {

    my $static_url = $requests{$method}->{url};

    my $fresh_url = $vm->$method()->{url};

    $number_of_tests++;
    is ($fresh_url, $static_url, "URL for $method (historic)");

    # also check for JSON if it exists
    if ( exists $requests{$method}->{json} ) {
        my $static_json = $requests{$method}->{json};
        my $fresh_json  = $vm->$method()->{json};
        $number_of_tests++;
        is_deeply ( $fresh_json,
                    $static_json,
                    "JSON for $method (historic)"
                  );
    }
}

########
# DONE #
########

done_testing($number_of_tests);

