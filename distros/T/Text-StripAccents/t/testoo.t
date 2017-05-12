
use Text::StripAccents;
use Test;
use strict;
BEGIN{plan tests=>1}

my $deutsch = "AUFKLÄRUNG ist der Ausgang des Menschen aus seiner selbstverschuldeten Unmündigkeit. Unmündigkeit ist das Unvermögen, sich seines Verstandes ohne Leitung eines anderen zu bedienen. Selbstverschuldet ist diese Unmündigkeit, wenn die Ursache derselben nicht am Mangel des Verstandes, sondern der Entschließung und des Mutes liegt, sich seiner ohne Leitung eines andern zu bedienen. Sapere aude! Habe Mut, dich deines eigenen Verstandes zu bedienen! ist also der Wahlspruch der Aufklärung.";
my $var2="AUFKLARUNG ist der Ausgang des Menschen aus seiner selbstverschuldeten Unmundigkeit. Unmundigkeit ist das Unvermogen, sich seines Verstandes ohne Leitung eines anderen zu bedienen. Selbstverschuldet ist diese Unmundigkeit, wenn die Ursache derselben nicht am Mangel des Verstandes, sondern der Entschliessung und des Mutes liegt, sich seiner ohne Leitung eines andern zu bedienen. Sapere aude! Habe Mut, dich deines eigenen Verstandes zu bedienen! ist also der Wahlspruch der Aufklarung.";

my $result=0;

my $stripper = Text::StripAccents->new();
my $var1 = $stripper->strip($deutsch);


if ($var1 eq $var2){$result=1}
ok($result);


