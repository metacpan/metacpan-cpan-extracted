use Test;
$|++;
BEGIN { plan tests => 2 };

use WWW::Search::Googlism;
ok(1);

print "Are you connected to internet [Y/n]?";
chomp($ans = <STDIN>);
if($ans =~ /n/i){
    ok(1);
}
else{
    $query = "googlism";
    $search = new WWW::Search('Googlism');
    $search->native_query(WWW::Search::escape_query($query), { type => 'who' });
    while (my $result = $search->next_result()) {
	$text .= "$result\n";
    }
    ok(($text ? 1 : 0), 1);
}
