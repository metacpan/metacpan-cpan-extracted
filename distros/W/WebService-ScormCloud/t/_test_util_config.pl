#!perl -T

use strict;
use warnings;

use File::Spec;

use constant CFGFILE => File::Spec->catfile('blib', 'api-info.cfg');

use constant SERVICE_URL => 'http://cloud.scorm.com/api';

sub createTestConfigInfo
{
    my %opts = @_;

    my $skip_live_tests = $opts{skip_live_tests} ? 1 : 0;

    my $app_id      = '';
    my $secret_key  = '';
    my $service_url = '';

    my $fh;
    my $existing_file = 0;
    if (-f CFGFILE)
    {
        unless (open($fh, '+<', CFGFILE))
        {
            die 'Cannot open test config file for reading/writing: ' . CFGFILE;
        }

        $existing_file = 1;

        my @lines = <$fh>;
        chomp foreach @lines;

        ($app_id, $secret_key, $service_url) = @lines;
        $app_id      = '' unless $app_id;
        $secret_key  = '' unless $secret_key;
        $service_url = '' unless $service_url;

        seek $fh, 0, 0;
        truncate $fh, 0;
    }
    else
    {
        unless (open($fh, '>', CFGFILE))
        {
            die 'Cannot open test config file for writing: ' . CFGFILE;
        }
    }

    unless ($skip_live_tests)
    {
        _get_config_var('ScormCloud AppID', 'SCORM_CLOUD_APPID', \$app_id);

        _get_config_var('ScormCloud SecretKey',
                        'SCORM_CLOUD_SECRETKEY', \$secret_key);

        _get_config_var('ScormCloud ServiceURL',
                        'SCORM_CLOUD_SERVICEURL', \$service_url, SERVICE_URL);

        $service_url = SERVICE_URL if $service_url eq 'default';
    }

    print $fh "$app_id\n";
    print $fh "$secret_key\n";
    print $fh "$service_url\n";
    print $fh "$skip_live_tests\n";

    close $fh;
}

sub _get_config_var
{
    my ($name, $env_name, $valueref, $default) = @_;

    if ($ENV{$env_name})
    {
        $$valueref = $ENV{$env_name};
        print "Using \$ENV{$env_name}: $$valueref\n";
    }
    else
    {
        print "\n\$ENV{$env_name} is not set.\n";

        my $prompt = "Please enter your $name";
        if ($default && $default ne $$valueref)
        {
            $prompt .= qq{,\n  or enter the word "default" to use "$default"};
        }
        if ($$valueref)
        {
            print "Existing test config has: $$valueref\n";
            $prompt .= qq{,\n  or hit return to keep "$$valueref"};
        }
        $prompt .= ": ";

        my $input;
        do
        {
            print $prompt;
            $input = <STDIN>;
            chomp $input;
            $input = $$valueref if $$valueref && !$input;
        } until $input;

        $$valueref = $input;
    }
}

sub getTestConfigInfo
{
    my $fh;

    unless (open($fh, '<', CFGFILE))
    {
        BAIL_OUT('Cannot open existing test config file: ' . CFGFILE);
    }

    my @lines = <$fh>;
    close $fh;

    chomp foreach @lines;

    my ($app_id, $secret_key, $service_url, $skip_live_tests) = @lines;

    $app_id      = 'MISSING_APP_ID'      unless $app_id;
    $secret_key  = 'MISSING_SECRET_KEY'  unless $secret_key;
    $service_url = 'MISSING_SERVICE_URL' unless $service_url;

    $skip_live_tests = $skip_live_tests ? 1 : 0;

    return ($app_id, $secret_key, $service_url, $skip_live_tests);
}

1;

