use strict;
use warnings FATAL => qw(all);

use My::TestUtil;
use IO::File;
use Apache::Test qw(-withtestmore);

My::TestUtil->write_echo();

plan tests => 12;

my $class = qw(My::Subclass);

use_ok($class);

{
  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $rc = $o->ping_device;

  ok (! $rc,
      'no rc for no device id');
}

{

  #local $WebService::UrbanAirship::APNS::DEBUG = 1;

  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $rc = $o->ping_device(device_token => '0000    0000-lcwdw <dfsd >aerfdd >- gghi    htds');

  ok ($rc,
      'GET returned successfully');

  my $outfile =  File::Spec->catfile(Apache::Test::vars('serverroot'),
                                     qw(test/output.txt));

  ok (-e $outfile,
      "output file $outfile exists");

  my $fh = IO::File->new($outfile);

  ok ($fh,
      "could open $outfile");

  my $content = do { local $/; <$fh> };

  like ($content,
        qr!\QHTTP_USER_AGENT => WebService::UrbanAirship::APNS/0.\E\d+!,
        "found user agent");
  
  like ($content,
        qr!\QSCRIPT_URL => /api/device_tokens/00000000LCWDWDFSDAERFDDGGHIHTDS!,
        "found url");
  
  like ($content,
        qr!\QSCRIPT_URI => https://!,
        "request was https");
  
  like ($content,
        qr!\QHTTPS => on!,
        "request was really https");
  
  like ($content,
        qr!\QREQUEST_METHOD => GET!,
        "request was GET");
  
  like ($content,
        qr!\QWSAUTH => Basic a2V5OnNlY3JldA==!,
        "request used application key for authentication");
  
  unlink $outfile;

  ok (! -e $outfile,
      "removed $outfile");
}
