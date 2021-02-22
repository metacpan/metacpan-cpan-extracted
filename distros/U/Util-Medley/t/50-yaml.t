use Test::More;
use Modern::Perl;
use Util::Medley::YAML;
use Data::Printer alias => 'pdump';
use Util::Medley::Simple::String 'trim';
use Util::Medley::Simple::File 'unlink';

use constant TEST_YAML_FILE => 't/test.yaml';

my %data = (
    foo  => 'bar',
    biz  => 'baz',
    dogs => [qw(collie pug lab)],
);

my $dataAsStr = trim( '
---
biz: baz
dogs:
  - collie
  - pug
  - lab
foo: bar
'
);

#
# new
#
my $util = Util::Medley::YAML->new;
ok($util);

#
# encode
#
my $encoded = trim( $util->encode( \%data ) );
ok( $encoded eq $dataAsStr );

#
# decode
#
my ($decoded) = $util->decode($encoded);
is_deeply($decoded, \%data);

#
# write
#
eval {
    $util->write(TEST_YAML_FILE, \%data);
};
ok(!$@);

ok(-f TEST_YAML_FILE);

#
# read
#
my @res;
eval {
    @res = $util->read('t/test.yaml');
};
ok(!$@);

is_deeply($res[0], \%data);

#
# done
#
done_testing;

unlink(TEST_YAML_FILE);

