use strict;
use warnings;

use WebService::Dropbox;

my $key = $ENV{DROPBOX_APP_KEY};
my $secret = $ENV{DROPBOX_APP_SECRET};
my $access_token = $ENV{DROPBOX_ACCESS_TOKEN};

my $box = WebService::Dropbox->new({
    key => $key,
    secret => $secret,
});

$box->debug;
$box->verbose;

if ($access_token) {
    $box->access_token($access_token);
} else {
    my $url = $box->authorize;

    print "Please Access URL and press Enter: $url\n";
    print "Please Input Code: ";

    chomp( my $code = <STDIN> );

    unless ($box->token($code)) {
        die $box->error;
    }

    print "Successfully authorized.\nYour AccessToken: ", $box->access_token, "\n";
}

my $res = $box->search('/Photos', '39.jpg');

# use Data::Dumper;
# warn Dumper($res);


# {
#     my $res = $box->get_current_account;
#     my $account_id = $res->{account_id};
#     $box->get_account($account_id);
#     $box->get_account_batch([ $account_id ]);
#     $box->get_space_usage;
# }

# # use Data::Dumper;
# # warn Dumper($res);

# {
#     my $res = $box->download('/aerith.json', './aerith.json');
#     # warn Dumper($res);
# }

# {
#     open(my $fh, '<', './aerith.json');
#     # $box->debug;
#     my $res = $box->upload_session('/aerith-test.json', $fh, { mode => 'overwrite' }, 20000);
#     # warn Dumper($res);
# }

# {
#     open(my $fh, '>', './hoge.pdf');
#     # $box->debug;
#     my $res = $box->get_preview('/work/recruit/職務経歴書.doc', $fh);
#     my $ct = $box->res->header('Content-Type');
#     warn $ct;
#     # warn Dumper($res);
# }
