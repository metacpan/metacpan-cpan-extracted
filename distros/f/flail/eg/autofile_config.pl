## autofile_config.pl - config for autofiling
##

use vars qw($AUTO_FILE);

$AUTO_FILE = {
    'Subject' => {
        'alib-cvs' => '\[alib-cvs\]',
        'alib-dev' => '\[alib-dev\]',
        'wookie-cvs' => '\[wookie-cvs\]',
        'wookie-dev' => '\[wookie-dev\]',
        'webapp-cvs' => '\[webapp-cvs\]',
        'webapp-dev' => '\[webapp-dev\]',
        'random-cvs' => '\[cvs:\s.*\]',
        'cron-hawg' => 'Cron.*hawg',
        'cron-itzamna' => 'Cron.*itzamna',
        'jobs' => 'jobs\.perl\.org',
    },
    'To,Cc' => {
        'cert-crap' => '.*@cert.org',
    },
    'From,Sender' => {
        'guru' => '.*@guru.com',
        'odesk' => '.*@odesk.com',
        'inphonex' => '.*\.inphonex.com',
        'domains' => '@256domains\.com|pdqregistrar\.com',
        'slashdot' => 'slashdot@slashdot',
        'pair' => '.*@pair\.com',
        'voicemail' => 'Voicemail System.*donotreply@InPhonex.com',
        'mailnull-notifications' => 'no_reply@mailnull\.com',
        'itzamna-logs' => '(root|MAILER-DAEMON)@(itzamna\.|)cluefactory\.com',
        'hawg-logs' => '(root|MAILER-DAEMON)@(hawg\.|)(stalphonsos|bitsend|hardbits)\.com',
        'agrun-logs' => '(root|MAILER-DAEMON)@(agrun\.|)stalphonsos\.com',
        'enkum-logs' => '(root|MAILER-DAEMON)@(enkum\.|)stalphonsos\.com',
        'bcc-snl' => 'snl@(.*\.|)(cluefactory|bitsend|hardbits)',
        'bcc-attila' => 'attila@(.*\.|)(stalphonsos|cluefactory)',
    },
    ':Content' => {
        POSIX::strftime("htmlspam_%G%m%d%H",localtime) =>
            '(?is)<(|/)(html|body|font|div|span|p|form|input|script)(|.*?)>',
    },
};


1;
__END__

# Local variables:
# mode: perl
# indent-tabs-mode: nil
# tab-width: 4
# perl-indent-level: 4
# End:
