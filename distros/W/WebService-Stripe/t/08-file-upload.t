use Test::Modern;
use t::lib::Common qw(skip_unless_has_secret stripe);

skip_unless_has_secret;

my $acct = stripe->create_account({
    managed => 'true',
    country => 'CA',
});

subtest 'upload_identity_document' => sub {
    subtest "Client can upload and attach a JPG identity document" => sub {
        my $jpg_path = "./documents/valid.jpg";
        my $file = stripe->upload_identity_document( $acct, $jpg_path );
        like $file->{id}, qr/file_\w+/,
            '... Uploaded the file';

        $acct = stripe->update_account( $acct->{id}, data => {
            'legal_entity[verification][document]' => $file->{id},
        });
        is $acct->{legal_entity}{verification}{document}, $file->{id},
            '... Linked uploaded file to an account';
    };
};

done_testing;
