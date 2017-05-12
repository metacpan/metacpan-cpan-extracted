
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
# Time-stamp: "2001-05-16 22:05:51 MDT"
######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Win32::Locale;
$loaded = 1;
print "ok 1\n";

print "Win32::Locale version: $Win32::Locale::VERSION\n";
###########################################################################
$| = 1;

print '',
 'en-us' eq ($Win32::Locale::MSLocale2LangTag{0x0409} || '')
  ? "ok 2\n" : "fail 2\n"
;

{
  my $locale = Win32::Locale::get_ms_locale();
  if($locale) {
    printf "Current locale 0x%08x (%s => %s) => Lang %s\n\n",
      $locale, $locale,
      Win32::Locale::get_locale($locale)   || '?',
      Win32::Locale::get_language($locale) || '?',
  } else {
    print "(Can't get ms-locale)\n";
  }
}

__END__
