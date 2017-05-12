use strict;
use warnings FATAL => qw(all);

use My::TestUtil;
use IO::File;
use Apache::Test qw(-withtestmore);
use Data::Dumper;
$Data::Dumper::Indent=0;
$Data::Dumper::Terse=1;

My::TestUtil->write_echo();

plan tests => (11 * 9) + 2;

my $class = qw(My::Subclass);

use_ok($class);

{
  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $rc = $o->register_device;

  ok (! $rc,
      'no rc for no device id');
}

foreach my $alias (undef, '', 'my device alias') {

  foreach my $tags (undef, '', ['tag1','tag2']) {

    #local $WebService::UrbanAirship::APNS::DEBUG = 1;

    my $o = $class->new(application_key         => 'key',
                        application_secret      => 'secret',
                        application_push_secret => 'push secret');

    my $rc = $o->register_device(device_token => '0000    0000-lcwdw <dfsd >aerfdd >- gghi    htds',
                                 alias        => $alias,
                                 tags         => $tags);

    is ($rc,
        200,
        'PUT returned successfully');

    my $outfile =  File::Spec->catfile(Apache::Test::vars('serverroot'),
                                       qw(test/output.txt));

    ok (-e $outfile,
        "output file $outfile exists");

    my $fh = IO::File->new($outfile);

    ok ($fh,
        "could open $outfile");

    my $content = do { local $/; <$fh> };

    my $palias = $alias;
    $palias = 'undef' unless defined $alias;

    my $ptags = defined $tags ? Dumper($tags) : 'undef';

    like ($content,
          qr!\QHTTP_USER_AGENT => WebService::UrbanAirship::APNS/0.\E\d+!,
          "found alias '$palias', tags $ptags user agent");
  
    like ($content,
          qr!\QSCRIPT_URL => /api/device_tokens/00000000LCWDWDFSDAERFDDGGHIHTDS!,
          "found alias '$palias', tags $ptags url");
  
    like ($content,
          qr!\QSCRIPT_URI => https://!,
          "alias '$palias', tags $ptags request was https");
  
    like ($content,
          qr!\QHTTPS => on!,
          "alias '$palias', tags $ptags request was really https");
  
    like ($content,
          qr!\QREQUEST_METHOD => PUT!,
          "alias '$palias', tags $ptags  request was PUT");
  
    like ($content,
          qr!\QWSAUTH => Basic a2V5OnNlY3JldA==!,
          "alias '$palias', tags $ptags request used application key for authentication");
  
    my $test = '';

    if ($alias && $tags) {
      $test = '{"alias":"my device alias","tags":["tag1","tag2"]}';
    }
    elsif ($alias) {
      $test = '{"alias":"my device alias"}';
    }
    elsif ($tags) {
      $test = '{"tags":["tag1","tag2"]}';
    }

    like ($content,
          qr!\QWSBODY => $test!,
          "found alias $test for alias '$palias', tags $ptags");

    unlink $outfile;

    ok (! -e $outfile,
        "removed $outfile");
  }
}
