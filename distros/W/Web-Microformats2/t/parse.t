use warnings; use strict;
use Test::More;
use Test::Deep;
use List::Util qw(first);
use Path::Class::Dir;
use FindBin;
use JSON;

use_ok ("Web::Microformats2");

my $parser = Web::Microformats2::Parser->new;
my $test_dir = Path::Class::Dir->new( "$FindBin::Bin/microformats-v2");

$test_dir->recurse( callback => \&handle_file );

sub handle_file {
    my $file = shift;

    return unless $file->basename =~ /html/;

    my ( $main, $ext ) = $file->basename =~ /^(.*)\.(.*)$/;

    my $json_file = Path::Class::File->new(
        $file->dir, "$main.json"
    );

    my $html = $file->slurp(iomode => '<:encoding(UTF-8)');
    my $target_json = $json_file->slurp;

    my $candidate = decode_json($parser->parse( $html )->as_json);
    my $target = decode_json($target_json);
    is_deeply( $candidate, $target );
}

done_testing();
