use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;

use FindBin qw/$Bin/;
use JSON;
use Term::ANSIColor;
use File::Find;
use Validator::LIVR;

iterate_test_data('test_suite/positive' => sub {
    my $data = shift;

    my $validator = Validator::LIVR->new( $data->{rules} );
    my $output = $validator->validate( $data->{input} );

    ok(! $validator->get_errors(), 'Validator should contain no errors' ) or diag explain {
        got_errors => $validator->get_errors(),
        test_data  => $data,
    };

    is_deeply( $output, $data->{output}, 'Validator should return validated data' );
});


iterate_test_data('test_suite/negative' => sub {
    my $data = shift;

    my $validator = Validator::LIVR->new( $data->{rules} );
    my $output = $validator->validate( $data->{input} );

    ok(!$output, 'Validator should return false');

    is_deeply( $validator->get_errors(), $data->{errors}, 'Validator should contain valid errors' )
        or (diag(explain({ got_errors => $validator->get_errors(), test_data => $data })) && exit);
});


iterate_test_data('test_suite/aliases_positive' => sub {
    my $data = shift;

    my $validator = Validator::LIVR->new( $data->{rules} );
    $validator->register_aliased_rule($_) for @{ $data->{aliases} };
    my $output = $validator->validate( $data->{input} );

    ok(! $validator->get_errors(), 'Validator should contain no errors' ) or diag explain $validator->get_errors();
    is_deeply( $output, $data->{output}, 'Validator should return validated data' );
});


iterate_test_data('test_suite/aliases_negative' => sub {
    my $data = shift;

    my $validator = Validator::LIVR->new( $data->{rules} );
    $validator->register_aliased_rule($_) for @{ $data->{aliases} };

    my $output = $validator->validate( $data->{input} );

    ok(!$output, 'Validator should return false');

    is_deeply( $validator->get_errors(), $data->{errors}, 'Validator should contain valid errors' );
});

done_testing;

sub iterate_test_data {
    my ( $dir_basename, $cb ) = @_;
    FindBin->again();

    my $dir_fullname = "$Bin/$dir_basename";
    note( colored($dir_fullname, 'yellow bold') );

    opendir( my $dh, $dir_fullname );
    my @tests = sort grep { /^[^.]/ } readdir($dh);
    closedir $dh;

    foreach my $test_name (@tests) {
        my $test_dir = "$dir_fullname/$test_name";

        my %data = (test_name => $test_name);
        find( sub {
            my $file = $File::Find::name;
            return unless $file =~ /.json$/;

            # Load data
            open (my $fh, '<', $file) or die $!;
            my $json = do { local $/; <$fh> };
            close $fh;

            my $content = eval { decode_json($json) };
            if ($@) {
                die "Cannot read [$file]. $@";
            }

            # Prepare key
            $file =~ s/^\Q$test_dir\E//;
            my @parts = grep{$_} split( /[\\\/]/, $file);
            my $key = pop @parts;
            $key =~ s/\.json$//;

            # Go deep and set content
            my $hash = \%data;
            $hash = $hash->{$_} //= {} for @parts;
            $hash->{$key} = $content;
        }, $test_dir);

        subtest "Test $dir_basename/$test_name" => sub {
            $cb->( \%data );
        };
    }
}
