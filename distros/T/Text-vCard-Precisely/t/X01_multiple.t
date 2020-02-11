use strict;
use warnings;

use Test::More tests => 10;
use Path::Tiny qw(path);
use Data::Section::Simple qw(get_data_section);
use Text::Diff qw(diff);
use lib qw(./lib);

BEGIN { use_ok ('Text::vCard::Precisely::Multiple') };                                                  # 1
my $vcm = new_ok('Text::vCard::Precisely::Multiple');                                                   # 2

my $path = path( 't', 'Multiple', 'example.vcf' );
$vcm->load_file($path);

foreach my $vc ( $vcm->all_options() ){
    next unless $vc->fn();
    #note $vc->as_string();
    $vc->fn()->[0] =~ /^FN:(\w+)/;
    is $vc->isa('Text::vCard::Precisely'), 1, "loading vCard for $1 succeeded.";                        # 3-7
}

my $got = $vcm->as_file('got.vcf');
open my $fh_got, '<', $got;
open my $fh_expected, '<', $^O eq 'MSWin32'? path( 't', 'Multiple', 'windows.vcf' ): $path;
is diff( $fh_got, $fh_expected ), '', "method as_file succeeded.";                                      # 8
close $fh_got;
close $fh_expected;
$got->remove();

my $arrayref = [];
my $e = get_data_section('array.pl');
eval $e or die $@;
$vcm->load_arrayref($arrayref);
is $vcm->count_options(), 2, "loading from ArrayRef succeeded.";                                        # 9

( my $gump = get_data_section('Gump') ) =~ s/\n/\r\n/g;
is $vcm->as_string(), $gump, "method as_string succeeded.";                                             #10

done_testing;

__DATA__
@@ array.pl
$arrayref = [
    {
        N   => [ 'Gump', 'Forrest', '', 'Mr.', '' ],
        FN  => 'Forrest Gump',
        ORG => 'Bubba Gump Shrimp Co.',
        TITLE => 'Shrimp Man',
        PHOTO => { media_type => 'image/gif', content => 'http://www.example.com/dir_photos/my_photo.gif' },
        TEL => [
            { types => ['WORK','VOICE'], content => '(111) 555-1212' },
        ],
        ADR =>[{
            types       => ['work'],
            pref        => 1,
            extended    => 100,
            street      => 'Waters Edge',
            city        => 'Baytown',
            region      => 'LA',
            post_code   => '30314',
            country     => 'United States of America'
        }],
        URL => 'http://www.example.com/dir_photos/my_photo.gif',
        EMAIL => 'forrestgump@example.com',
        REV => '20080424T195243Z',
    },{
        N   => [ 'Gump', 'Forrest', '', 'Mr.', '' ],
        FN  => 'Forrest Gump',
        ORG => 'Bubba Gump Shrimp Co.',
        TITLE => 'Shrimp Man',
        PHOTO => { media_type => 'image/gif', content => 'http://www.example.com/dir_photos/my_photo.gif' },
        TEL => [
            { types => ['HOME','VOICE'], content => '(404) 555-1212' },
        ],
        ADR =>[{
            types       => ['home'],
            extended    => 42,
            street      => 'Plantation St.',
            city        => 'Baytown',
            region      => 'LA',
            post_code   => '30314',
            country     => 'United States of America'
        }],
        URL => 'http://www.example.com/dir_photos/my_photo.gif',
        EMAIL => 'forrestgump@example.com',
        REV => '20080424T195243Z',
    },
];

@@ Gump
BEGIN:VCARD
VERSION:3.0
FN:Forrest Gump
N:Gump;Forrest;;Mr.;
ADR;TYPE=WORK;PREF=1:;100;Waters Edge;Baytown;LA;30314;United States of
  America
TEL;TYPE="WORK,VOICE":(111) 555-1212
EMAIL:forrestgump@example.com
ORG:Bubba Gump Shrimp Co.
TITLE:Shrimp Man
URL:http://www.example.com/dir_photos/my_photo.gif
PHOTO;TYPE=image/gif:http://www.example.com/dir_photos/my_photo.gif
REV:20080424T195243Z
END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:Forrest Gump
N:Gump;Forrest;;Mr.;
ADR;TYPE=HOME:;42;Plantation St.;Baytown;LA;30314;United States of America
TEL;TYPE="HOME,VOICE":(404) 555-1212
EMAIL:forrestgump@example.com
ORG:Bubba Gump Shrimp Co.
TITLE:Shrimp Man
URL:http://www.example.com/dir_photos/my_photo.gif
PHOTO;TYPE=image/gif:http://www.example.com/dir_photos/my_photo.gif
REV:20080424T195243Z
END:VCARD
