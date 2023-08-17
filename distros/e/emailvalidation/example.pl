use Emailvalidation;

my $api = Emailvalidation->new(apikey => 'aTHs7yojZuenQwe0qkq26QoTZzoz6yB9RKrtcMi1');
my $data = $api->info('john@doe.com');
print $data;
