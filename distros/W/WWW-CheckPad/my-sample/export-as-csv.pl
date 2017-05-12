#!/usr/bin/perl -w
################################################################################
# すべてのTodoをCSV形式で出力します。ただし、手抜きのCSVなので、タイトルにカンマが含まれる
# と正しい、CSV形式になりません。正しいCSV出力をしたい方はClass::CSVのようなCSV出力用の
# モジュールを使うと良いと思います。
# 
# Ken Takeshige 2006-07-05
################################################################################
use strict;
use warnings;
use WWW::CheckPad;
use WWW::CheckPad::CheckList;
use WWW::CheckPad::CheckItem;

if ((scalar @ARGV) != 2) {
    usage();
}

## Connec to check*pad server and login.
my $connection = WWW::CheckPad->connect(
    email => $ARGV[0],
    password => $ARGV[1],
);

die "Login failed" if not $connection->has_logged_in();

foreach my $checklist (WWW::CheckPad::CheckList->retrieve_all) {
    foreach my $checkitem ($checklist->checkitems) {
        printf "%s, %s, %s, %s, %s\n",
            $checklist->id, $checklist->title,
                $checkitem->id, $checkitem->title,
                    $checkitem->is_finished ? 'Finished' : 'Unfinished';
    }
}


sub usage {
    print "perl export-as-csv.pl <email> <password>\n\n";
    exit;
}
