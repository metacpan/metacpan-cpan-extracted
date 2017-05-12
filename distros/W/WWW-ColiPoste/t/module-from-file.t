#!perl -T
use strict;
use warnings;
use File::Spec::Functions;
use Test::More;


my @known_fields = qw< date site status >;
my @files = glob(catfile(qw< t files results-*.html >));

plan tests => 3 + (4 + @known_fields) * @files;

my $module = "WWW::ColiPoste";
use_ok($module);

my $coliposte = eval { $module->new };
is( $@, "", "creating a $module object" );
isa_ok( $coliposte, $module, "check that the object" );

for my $file (@files) {
    my $status = eval { $coliposte->get_status(tracking_id => 0, from => $file) };
    is( $@, "", "getting status from file $file" );
    isa_ok( $status, "ARRAY", " :: checking that the status" );
    cmp_ok( scalar @$status, ">=", 1,
        " ::  checking that there is at least one item" );
    isa_ok( $status->[0], "HASH", " :: checking that this line" );

    my %status_fields = map { $_ => 1 } keys %{ $status->[0] };
    for my $field (@known_fields) {
        ok( exists $status_fields{$field},
            " :: checking that the $field field is present" );
    }
}
