use strict;
use warnings;
use Test::More;
use YAML::XS;

my $yaml = <<'EOM';
---
a: true
b: false
EOM
subtest 'JSON::PP' => sub {
    my $ok = eval "use JSON::PP; 1";
    unless ($ok) {
        plan skip_all => "JSON::PP not installed";
    }
    my $xs = YAML::XS->new(boolean => 'JSON::PP');
    my $data = $xs->load($yaml);
    is ref $data->{a}, 'JSON::PP::Boolean', 'true loaded as expected';
    is ref $data->{b}, 'JSON::PP::Boolean', 'false loaded as expected';

    my $out = $xs->dump($data);
    is $out, $yaml, 'dump as expected';
};

subtest 'boolean.pm' => sub {
    my $ok = eval "use boolean; 1";
    unless ($ok) {
        plan skip_all => "boolean not installed";
    }
    my $xs = YAML::XS->new(boolean => 'boolean');
    my $data = $xs->load($yaml);
    is ref $data->{a}, 'boolean', 'true loaded as expected';
    is ref $data->{b}, 'boolean', 'false loaded as expected';

    my $out = $xs->dump($data);
    is $out, $yaml, 'dump as expected';
};

subtest invalid => sub {
    eval { YAML::XS->new(boolean => 'foo') };
    like $@, qr/YAML::XS->new: boolean only accepts 'JSON::PP', 'boolean' or a false value/;
};

done_testing;
