use warnings; use strict;
use Test::More;
use Test::Deep;
use List::Util qw(first);
use Path::Class::Dir;
use FindBin;
use JSON;

# %TODO_TESTS: Hash of tests that the parser should support someday, but
#              that day is not today.
my %TODO_TESTS =
(
          'h-geo' => [
                       'abbrpattern',
                       'valuetitleclass',
                       'hidden'
                     ],
          'h-recipe' => [
                          'all'
                        ],
          'h-entry' => [
                         'impliedvalue-nested'
                       ],
          'h-product' => [
                           'simpleproperties',
                           'aggregate'
                         ],
          'rel' => [
                     'duplicate-rels',
                     'xfn-all',
                     'license',
                     'nofollow',
                     'varying-text-duplicate-rels',
                     'xfn-elsewhere',
                     'rel-urls'
                   ],
          'h-resume' => [
                          'work',
                          'education'
                        ],
          'h-adr' => [
                       'simpleproperties'
                     ],
          'h-review' => [
                          'vcard',
                          'implieditem',
                          'item'
                        ],
          'h-event' => [
                         'dt-property',
                         'combining',
                         'time',
                         'concatenate',
                         'ampm',
                         'attendees',
                         'dates'
                       ],
          'h-review-aggregate' => [
                                    'simpleproperties',
                                    'justahyperlink',
                                    'hevent'
                                  ],
);

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

    my $candidate = decode_json($parser->parse( $html )->as_json);
    my $target = decode_json($json_file->slurp);

    if ( first { $_ eq $main } @{ $TODO_TESTS{ $file->parent->basename } } ) {
        local $TODO = "This Microformat2 parser doesn't support the "
                      . "'$main' test yet.";

        TODO: { is_deeply( $candidate, $target ) }
    }
    else {
        is_deeply( $candidate, $target );
    }
}

done_testing();
