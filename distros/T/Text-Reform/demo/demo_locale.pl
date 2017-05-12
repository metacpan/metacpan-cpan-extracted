use POSIX qw(locale_h);
setlocale(LC_ALL, "de");

# Get a reference to a hash of locale-dependent info
$locale_values = localeconv();

# Output sorted list of the values
for (sort keys %$locale_values) {
printf "%-20s = %s\n", $_, $locale_values->{$_}
}





__END__

use Text::Reform;

my @vals = (1.1,22.22,333.333);

print form 
']]]]]].[[',
[@vals];


print form 
']]]]]].[[',
[@vals];

setlocale(LC_CTYPE, "");

print form 
']]]]]].[[',
[@vals];

