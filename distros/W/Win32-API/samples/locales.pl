use Win32::kernel32;

for $locale (0 .. 2048) {
    $lang = Win32::VerLanguageName($locale);
    if ($lang ne "Language Neutral") {
        printf("%4d (%s) %s\n", $locale, $lang, Win32::GetCurrencyFormat(10000, $locale));
    }
}
