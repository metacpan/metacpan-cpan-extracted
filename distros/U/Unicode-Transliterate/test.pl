# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Unicode::Transliterate;
use strict;
our $loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print test_002() ? "ok 2\n" : "not ok 2\n";
print test_003() ? "ok 3\n" : "not ok 3\n";
print test_004() ? "ok 4\n" : "not ok 4\n";
print test_005() ? "ok 5\n" : "not ok 5\n";
print test_006() ? "ok 6\n" : "not ok 6\n";
print test_007() ? "ok 7\n" : "not ok 7\n";
print test_008() ? "ok 8\n" : "not ok 8\n";
print test_009() ? "ok 9\n" : "not ok 9\n";
print test_010() ? "ok 10\n" : "not ok 10\n";


# test low level xs transliteration
sub test_002
{
    my $name_orig = "Bruno Postle";
    my $name_kana = Unicode::Transliterate::_myxs_transliterate ("Latin-Katakana", "FORWARD", $name_orig);
    my $name_back = Unicode::Transliterate::_myxs_transliterate ("Latin-Katakana", "REVERSE", $name_kana);
    return $name_back eq "buruno posutere";
}


# test if we got a number of transliterators greater than 0
sub test_003
{
    my $number = Unicode::Transliterate::_myxs_countAvailableIDs();
    return $number > 0;
}


# test that we can get a transliterator
sub test_004
{
    my $availableIDs = Unicode::Transliterate::_myxs_countAvailableIDs();
    for (0..$availableIDs) {
        my $id = Unicode::Transliterate::_myxs_getAvailableID ($_);
        $id =~ /-/ or return;
    }
    return 1;
}


# test that we can list pairs of transliterators that can be used
sub test_005
{
    my $translit = new Unicode::Transliterate;
    my @pairs = $translit->list_pairs;
    return scalar @pairs;
}


# test the 'from' accessor
sub test_006
{
    my $translit = new Unicode::Transliterate;
    $translit->from ('Katakana');
    return $translit->from eq 'Katakana';
}


# test the 'to' accessor
sub test_007
{
    my $translit = new Unicode::Transliterate;
    $translit->to ('Katakana');
    return $translit->to eq 'Katakana';
}


# test high-level transliteration
sub test_008
{
    my $translit = new Unicode::Transliterate;
    $translit->from ('Latin');
    $translit->to ('Katakana');

    my $translit2 = new Unicode::Transliterate;
    $translit2->from ('Katakana');
    $translit2->to ('Latin');

    my $name_orig = "Bruno Postle";
    my $name_back = $translit2->process ($translit->process ($name_orig));

    return $name_back eq "buruno posutere";
}


# test low level xs transliteration
# with inter indic
sub test_009
{
    my $name_orig  = "foo";
    my $interindic = Unicode::Transliterate::_myxs_transliterate ("InterIndic-Latin", "REVERSE", $name_orig);
    my $latin      = Unicode::Transliterate::_myxs_transliterate ("InterIndic-Latin", "FORWARD", $interindic);
    
    return $latin eq "fo'o";
}


# print the list of all available transliterators
sub test_010
{
    my $latin_gurmukhi = new Unicode::Transliterate ( from => 'Latin', to => 'Gurmukhi' );
    my $gurmukhi_latin = new Unicode::Transliterate ( from => 'Gurmukhi', to => 'Latin' );
    return $gurmukhi_latin->process ( $latin_gurmukhi->process ("This is a test") );
}


1;
