use Text::Names 'parseNames','cleanName','composeName','parseName';
use Test::More;
use utf8;
binmode(STDOUT,":utf8");

is(cleanName("T.H. Ho"),"Ho, T. H.");
is(cleanName("Ho, T. . ."),"Ho, T.");
is(cleanName("D.'Arms, D."), "D'Arms, D.");
is(cleanName("D.’Arms, D."), "D'Arms, D.");
is(cleanName("D’Arms, D."), "D’Arms, D.");
my ($f,$l) = parseName("D’Arms, D.");
is($l,"D’Arms");


my %tests = (
    'Kuehni, R. G., Hardin, C. L.' => 'Kuehni, R. G.; Hardin, C. L.',
	'Bourget, David; Doe, John' => 'Bourget, David; Doe, John',	
	'David Bourget & John Doe' => 'Bourget, David; Doe, John',	
	'David Bourget and John Doe' => 'Bourget, David; Doe, John',	
	'Bourget D, Doe J' => 'Bourget, D.; Doe, J.',	
	'Bourget DJR' => 'Bourget, D. J. R.',
    'Bourget, D.J.R.' => 'Bourget, D. J. R.',
    'Bourget D.J.R.' => 'Bourget, D. J. R.',
    'D.J. Bourget' => 'Bourget, D. J.',
	'Bourget, DAVID' => 'Bourget, DAVID',
	'David BOURGET' => 'BOURGET, David',
    'David Chalmers, David Bourget and John Doe' => 'Chalmers, David; Bourget, David; Doe, John',
    'Chalmers, David, Bourget, David, Doe, John' => 'Chalmers, David; Bourget, David; Doe, John',
    'Chalmers, David John, Bourget, David, Doe, John C.' => 'Chalmers, David John; Bourget, David; Doe, John C.',
	'DAVID BOURGET' => 'BOURGET, DAVID',
    'John Doe Jr' => 'Doe Jr, John',
    'John M. Doe Jr' => 'Doe Jr, John M.',
    'Dr Afsar Abbas' => 'Abbas, Afsar',
    'R. de Sousa' => 'de Sousa, R.',
    'Jean Claude van Damme' => 'van Damme, Jean Claude',
    'Dr. Jean Claude van Damme, Prof R de Sousa' => 'van Damme, Jean Claude; de Sousa, R.',
    "Maureen A. O'Malley" => "O'Malley, Maureen A.",
    "Gusmão da Silva, Guilherme" => "Gusmão da Silva, Guilherme",
    "D Bourget, Zbigniew Z Lukasiak and John Doe" => "Bourget, D.; Lukasiak, Zbigniew Z.; Doe, John",
    "Bourget, D and John Doe" => "Bourget, D.; Doe, John",
    "Bourget, D, Chalmers C, and John Doe" => "Bourget, D.; Chalmers, C.; Doe, John",
    cleanName("Guilherme Gusmão da Silva") => "da Silva, Guilherme Gusmão",
    cleanName("van Untouched, Firstname") => "van Untouched, Firstname",
    cleanName("Van Untouched, Firstname") => "Van Untouched, Firstname",
    cleanName("VAN TOUCHED, firstname") => "van Touched, Firstname",
    cleanName("CL Adams") => "Adams, C. L.",
    cleanName("Hacker, PMS") => "Hacker, P. M. S.",
    cleanName("van fraassen b") => "van Fraassen, B.",
    cleanName("van fraassen b c") => "van Fraassen, B. C.",
    cleanName("RawlsJ.") => "Rawls, J.",
    cleanName("RawlsJ.C.") => "Rawls, J. C.",
    cleanName("RawlsJC") => "Rawls, J. C.",
    cleanName("McKim, John") => "McKim, John",
    cleanName("John McKim") => "McKim, John",
    cleanName("McKim") => "McKim, "
);
is(cleanName("Hacker, PMS"),"Hacker, P. M. S.");
is(cleanName("Doe, Bob"),"Doe, Bob");
#print cleanName("Guilherme Gusmão da Silva");
foreach my $t (keys %tests) {
	my $r = join('; ',parseNames($t));
    is( $r, $tests{$t}, "$t -> $r" );
}
done_testing;
