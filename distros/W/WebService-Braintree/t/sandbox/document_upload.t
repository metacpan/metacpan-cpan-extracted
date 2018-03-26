# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

BEGIN {
    plan skip_all => "sandbox_config.json required for sandbox tests"
        unless -s 'sandbox_config.json';
}

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::TestHelper qw/sandbox/;

use File::Basename qw(fileparse);
use File::Spec ();
use File::Temp qw(tempdir tempfile);

my ($filename, $dir) = fileparse(__FILE__);
my $fixtures = File::Spec->catdir(
    File::Spec->rel2abs($dir),
    'fixtures',
    'document_upload',
);

my $tempdir = tempdir(CLEANUP => 1, DIR => File::Spec->tmpdir);

subtest create => sub {
    my $kind = WebService::Braintree::DocumentUpload::Kind->EvidenceDocument;

    subtest 'success with valid request' => sub {
        my $file = File::Spec->catfile($fixtures, 'bt_logo.png');
        my $size = -s $file;

        my $response = WebService::Braintree::DocumentUpload->create({
            kind => $kind,
            file => $file,
        });
        validate_result($response) or return;

        my $upload = $response->document_upload;
        isa_ok($upload, 'WebService::Braintree::_::DocumentUpload');
        ok($upload->id);
        is($upload->content_type, 'image/png');
        is($upload->kind, $kind);
        is($upload->name, 'bt_logo.png');
        cmp_ok($upload->size, '==', $size);
    };

    subtest 'returns file type error with unsupported file type' => sub {
        my $file = File::Spec->catfile($fixtures, 'gif_extension_bt_logo.gif');

        my $response = WebService::Braintree::DocumentUpload->create({
            kind => $kind,
            file => $file,
        });
        invalidate_result($response) or return;

        my $expected_error_code = WebService::Braintree::ErrorCodes::DocumentUpload::FileTypeIsInvalid;
        is($response->errors->for('document_upload')->on('file')->[0]->code, $expected_error_code);
    };

    subtest 'returns malformed error with malformed file' => sub {
        my $file = File::Spec->catfile($fixtures, 'malformed_pdf.pdf');

        my $response = WebService::Braintree::DocumentUpload->create({
            kind => $kind,
            file => $file,
        });
        invalidate_result($response) or return;

        my $expected_error_code = WebService::Braintree::ErrorCodes::DocumentUpload::FileIsMalformedOrEncrypted;
        is($response->errors->for('document_upload')->on('file')->[0]->code, $expected_error_code);
    };

    subtest 'returns invalid kind error with invalid kind' => sub {
        my $file = File::Spec->catfile($fixtures, 'malformed_pdf.pdf');

        my $response = WebService::Braintree::DocumentUpload->create({
            kind => $kind,
            file => $file,
        });
        invalidate_result($response) or return;

        my $expected_error_code = WebService::Braintree::ErrorCodes::DocumentUpload::FileIsMalformedOrEncrypted;
        is($response->errors->for('document_upload')->on('file')->[0]->code, $expected_error_code);
    };

    subtest 'returns file too large error over 4MB' => sub {
        my ($fh, $file) = tempfile('tmpXXXX', DIR => $tempdir, UNLINK => 1);
        for (1 .. 1048577 * 4) { print $fh 'a'; }

        my $response = WebService::Braintree::DocumentUpload->create({
            kind => $kind,
            file => $file,
        });
        invalidate_result($response) or return;

        my $expected_error_code = WebService::Braintree::ErrorCodes::DocumentUpload::FileIsTooLarge;
        is($response->errors->for('document_upload')->on('file')->[0]->code, $expected_error_code);
    };
};

done_testing;
