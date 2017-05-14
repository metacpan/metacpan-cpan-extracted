use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.056

use Test::More;

plan tests => 43;

my @module_files = (
    'WebService/PayPal/PaymentsAdvanced.pm',
    'WebService/PayPal/PaymentsAdvanced/Error/Authentication.pm',
    'WebService/PayPal/PaymentsAdvanced/Error/Generic.pm',
    'WebService/PayPal/PaymentsAdvanced/Error/HTTP.pm',
    'WebService/PayPal/PaymentsAdvanced/Error/HostedForm.pm',
    'WebService/PayPal/PaymentsAdvanced/Error/IPVerification.pm',
    'WebService/PayPal/PaymentsAdvanced/Error/Role/HasHTTPResponse.pm',
    'WebService/PayPal/PaymentsAdvanced/Mocker.pm',
    'WebService/PayPal/PaymentsAdvanced/Mocker/Helper.pm',
    'WebService/PayPal/PaymentsAdvanced/Mocker/PayflowLink.pm',
    'WebService/PayPal/PaymentsAdvanced/Mocker/PayflowPro.pm',
    'WebService/PayPal/PaymentsAdvanced/Mocker/SilentPOST.pm',
    'WebService/PayPal/PaymentsAdvanced/Response.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Authorization.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Authorization/CreditCard.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Authorization/PayPal.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Capture.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Credit.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/FromHTTP.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/FromRedirect.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/FromSilentPOST.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/FromSilentPOST/CreditCard.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/FromSilentPOST/PayPal.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Inquiry.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Inquiry/CreditCard.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Inquiry/PayPal.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Sale.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Sale/CreditCard.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Sale/PayPal.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/SecureToken.pm',
    'WebService/PayPal/PaymentsAdvanced/Response/Void.pm',
    'WebService/PayPal/PaymentsAdvanced/Role/ClassFor.pm',
    'WebService/PayPal/PaymentsAdvanced/Role/HasCreditCard.pm',
    'WebService/PayPal/PaymentsAdvanced/Role/HasMessage.pm',
    'WebService/PayPal/PaymentsAdvanced/Role/HasParams.pm',
    'WebService/PayPal/PaymentsAdvanced/Role/HasPayPal.pm',
    'WebService/PayPal/PaymentsAdvanced/Role/HasTender.pm',
    'WebService/PayPal/PaymentsAdvanced/Role/HasTokens.pm',
    'WebService/PayPal/PaymentsAdvanced/Role/HasTransactionTime.pm',
    'WebService/PayPal/PaymentsAdvanced/Role/HasUA.pm'
);

my @scripts = (
    'bin/mock-payflow-link',
    'bin/mock-payflow-pro'
);

# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    @switches = (@switches, split(' ', $1)) if $1;

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


