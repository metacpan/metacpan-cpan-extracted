use strict;
use Test::More;
use XML::Diver;
use File::Spec;
use utf8;

my $xmlfile = File::Spec->catfile(qw|t data 41.xml|);

my $diver = XML::Diver->load_xml(location => $xmlfile);

subtest 'get_title_from_item' => sub { 
    my $title_joined = $diver
        ->dive('//item/title')
        ->each(sub{shift->text})
        ->join("\n")
    ;

    my $expect = <<'EOF';
[ PR ] ブログでお天気を簡単ゲット！
佐賀多久地区 - 乾燥注意報が発表されています。
鳥栖地区 - 乾燥注意報が発表されています。
武雄地区 - 乾燥注意報が発表されています。
鹿島地区 - 乾燥注意報が発表されています。
唐津地区 - 濃霧注意報、乾燥注意報が発表されています。
伊万里地区 - 濃霧注意報、乾燥注意報が発表されています。
EOF
    $expect =~ s/\n$//;

    is $title_joined, $expect;
};

done_testing;
