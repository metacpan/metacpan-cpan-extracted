use strict;
use warnings;

# I realize that these tests are messy due to unicode file names and
# the optional Mac::PropertyList module.  My goal is to test
# as much functionality as possible, while still allowing the tests
# to pass as long as minimal functionality was present.

use File::Spec qw(catdir catfile);
use Module::Load::Conditional qw[check_install];
use Test::More;

BEGIN { use_ok('WebShortcutUtil::Read') };
require_ok('WebShortcutUtil::Read');

# We do not use these subroutines directly, but let's make sure they are at least exported.
can_ok('WebShortcutUtil::Read', qw(
    read_desktop_shortcut_file
    read_url_shortcut_file
    read_webloc_shortcut_file
    read_website_shortcut_file
    read_desktop_shortcut_handle
    read_url_shortcut_handle
    read_webloc_shortcut_handle
    read_website_shortcut_handle
));

#########################

use WebShortcutUtil::Read qw(
    get_shortcut_name_from_filename
    shortcut_has_valid_extension
    get_handle_reader_for_file
    read_shortcut_file
    read_shortcut_file_url
    read_desktop_shortcut_handle
    read_url_shortcut_handle
    read_webloc_shortcut_handle
    read_website_shortcut_handle
);

sub _test_read_shortcut {
    my ( $path, $filename, $expected_name, $expected_url ) = @_;

    my $full_filename = File::Spec->catfile($path, $filename);
    my $result = read_shortcut_file($full_filename);

    my $expected_result = {
        "name", $expected_name,
        "url", $expected_url};
    is_deeply(\$result, \$expected_result, $full_filename);
}


# Note that we check for errors using eval instead of dies_ok.
# This is to avoid having to add a dependency to Test:::Exception.


use utf8;

# Avoid "Wide character in print..." warnings (per http://perldoc.perl.org/Test/More.html)
my $builder = Test::More->builder;
binmode $builder->output, ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output, ":utf8";


diag("Some of the following tests may show warnings.");

# get_shortcut_name_from_filename tests
is(get_shortcut_name_from_filename("mypath/my.file.desktop"), "my.file");
is(get_shortcut_name_from_filename("mypath\\my.file.desktop"), "my.file");

# has_valid_extension tests
ok(shortcut_has_valid_extension("file.desktop"), "Valid extention .desktop");
ok(shortcut_has_valid_extension("file.DESKTOP"), "Valid extention .DESKTOP");
ok(shortcut_has_valid_extension("file.url"), "Valid extention .url");
ok(shortcut_has_valid_extension("file.URL"), "Valid extention .URL");
ok(shortcut_has_valid_extension("file.webloc"), "Valid extention .webloc");
ok(shortcut_has_valid_extension("file.WEBLOC"), "Valid extention .WEBLOC");
ok(shortcut_has_valid_extension("file.misleading.desktop"), "Valid extention multiple dots");
ok(!shortcut_has_valid_extension("file.badextension"), "Invalid extention");
ok(!shortcut_has_valid_extension("file"), "Invalid no extention");
ok(!shortcut_has_valid_extension("file.misleading.badextension"), "Invalid extention multiple dots");

# get_handle_reader_for_file tests
is(get_handle_reader_for_file("myfile.desktop"),
   \&read_desktop_shortcut_handle);

is(get_handle_reader_for_file("myfile.url"),
   \&read_url_shortcut_handle);

is(get_handle_reader_for_file("myfile.webloc"),
   \&read_webloc_shortcut_handle);

is(get_handle_reader_for_file("myfile.website"),
   \&read_website_shortcut_handle);


# Test missing file
eval { read_shortcut_file("bad_file.desktop") };
like ($@, qr/File.*/, "Read bad desktop file");

eval { read_shortcut_file("bad_file.url") };
like ($@, qr/File.*/, "Read bad url file");

eval { read_shortcut_file("bad_file.bad_extension") };
like ($@, qr/Shortcut file does not have a recognized extension.*/, "Read bad extension");


# Gnome tests
my $gnome_path = File::Spec->catdir("t", "samples", "real", "desktop", "gnome");
_test_read_shortcut($gnome_path, "Google.desktop", "Google", "https://www.google.com/");
_test_read_shortcut($gnome_path, "Yahoo!.desktop", "Yahoo!", "http://www.yahoo.com/");
_test_read_shortcut($gnome_path, "1.desktop", "1", "http://japan.zdnet.com/");
_test_read_shortcut($gnome_path, "2.desktop", "2", "http://www.myspace.com/");
_test_read_shortcut($gnome_path, "3.desktop", "3", "http://www.microsoft.com/sv-se/default.aspx");
_test_read_shortcut($gnome_path, "4.desktop", "4", "http://www.google.se/#sclient=tablet-gws&hl=sv&tbo=d&q=sverige&oq=sveri&gs_l=tablet-gws.1.1.0l3.13058.15637.28.17682.5.2.2.1.1.0.143.243.0j2.2.0...0.0...1ac.1.xX8iu4i9hYM&pbx=1&fp=1&bpcl=40096503&biw=1280&bih=800&bav=on.2,or.r_gc.r_pw.r_qf.&cad=b");
_test_read_shortcut($gnome_path, "5.desktop", "5", "http://www.中国政府.政务.cn/");
_test_read_shortcut($gnome_path, "6.desktop", "6", "http://cn.yahoo.com/");
_test_read_shortcut($gnome_path, "7.desktop", "7", "http://导航.中国/");
_test_read_shortcut($gnome_path, "8.desktop", "8", "http://www.baidu.com/");
_test_read_shortcut($gnome_path, File::Spec->catdir("renamed", "Link to Google - renamed.desktop"), "Link to Google - renamed", "https://www.google.com/");


# KDE tests
my $kde_path = File::Spec->catdir("t", "samples", "real", "desktop", "kde");
_test_read_shortcut($kde_path, "http___japan.zdnet.com_.desktop", "http___japan.zdnet.com_", "http://japan.zdnet.com/");
_test_read_shortcut($kde_path, "https___www.google.com_.desktop", "https___www.google.com_", "https://www.google.com/");
_test_read_shortcut($kde_path, "http___www.microsoft.com_sv-se_default.aspx.desktop", "http___www.microsoft.com_sv-se_default.aspx", "http://www.microsoft.com/sv-se/default.aspx");
_test_read_shortcut($kde_path, "http___www.myspace.com_.desktop", "http___www.myspace.com_", "http://www.myspace.com/");
_test_read_shortcut($kde_path, "http___www.yahoo.com_.desktop", "http___www.yahoo.com_", "http://www.yahoo.com/");
_test_read_shortcut($kde_path, "http___cn.yahoo.com_.desktop", "http___cn.yahoo.com_", "http://cn.yahoo.com/");
_test_read_shortcut($kde_path, "http___xn--fet810g.xn--fiqs8s_.desktop", "http___xn--fet810g.xn--fiqs8s_", "http://xn--fet810g.xn--fiqs8s/");
_test_read_shortcut($kde_path, "http___www.baidu.com_.desktop", "http___www.baidu.com_", "http://www.baidu.com/");
_test_read_shortcut($kde_path, "1.desktop", "1", "http://www.xn--fiqs8sirgfmh.xn--zfr164b.cn/");


# Desktop fake tests
my $desktop_fake_path = File::Spec->catdir("t", "samples", "fake", "desktop");

_test_read_shortcut($desktop_fake_path, "CommentsAndBlankLines.desktop", "CommentsAndBlankLines", "https://www.google.com/");

eval { read_shortcut_file(File::Spec->catdir ($desktop_fake_path, "Empty.desktop")) };
like ($@, qr/Desktop Entry group not found.*/, "Empty desktop");

eval { read_shortcut_file(File::Spec->catdir ($desktop_fake_path, "GarbledHeader.desktop")) };
like ($@, qr/Desktop Entry group not found.*/, "Garbled header desktop");

_test_read_shortcut($desktop_fake_path, "GarbledEntry.desktop", "GarbledEntry", "https://www.google.com/");

eval { read_shortcut_file(File::Spec->catdir ($desktop_fake_path, "HeaderOnly.desktop")) };
like ($@, qr/URL not found in file.*/, "HeaderOnly.desktop");

eval { read_shortcut_file(File::Spec->catdir ($desktop_fake_path, "ApplicationType.desktop")) };
like ($@, qr/URL not found in file.*/, "Application desktop");

_test_read_shortcut($desktop_fake_path, "LotsOfWhitespace.desktop", "LotsOfWhitespace", "https://www.google.com/");


# URL tests: Chrome
my $url_chrome_path = File::Spec->catdir("t", "samples", "real", "url", "Chrome");
_test_read_shortcut($url_chrome_path, "Google.url", "Google", "https://www.google.com/");
_test_read_shortcut($url_chrome_path, "Myspace - Social Entertainment.url", "Myspace - Social Entertainment", "http://www.myspace.com/");
_test_read_shortcut($url_chrome_path, "Yahoo!.url", "Yahoo!", "http://www.yahoo.com/");
_test_read_shortcut($url_chrome_path, "1.url", "1", "http://japan.zdnet.com/");
_test_read_shortcut($url_chrome_path, "2.url", "2", "http://www.microsoft.com/sv-se/default.aspx");
_test_read_shortcut($url_chrome_path, "3.url", "3", "http://www.google.se/#sclient=tablet-gws&hl=sv&tbo=d&q=sverige&oq=sveri&gs_l=tablet-gws.1.1.0l3.13058.15637.28.17682.5.2.2.1.1.0.143.243.0j2.2.0...0.0...1ac.1.xX8iu4i9hYM&pbx=1&fp=1&bpcl=40096503&biw=1280&bih=800&bav=on.2,or.r_gc.r_pw.r_qf.&cad=b");
_test_read_shortcut($url_chrome_path, "4.url", "4", "http://www.xn--fiqs8sirgfmh.xn--zfr164b.cn/");
_test_read_shortcut($url_chrome_path, "5.url", "5", "http://cn.yahoo.com/");
_test_read_shortcut($url_chrome_path, "6.url", "6", "http://xn--fet810g.xn--fiqs8s/");
_test_read_shortcut($url_chrome_path, "7.url", "7", "http://www.baidu.com/");

# URL tests: Firefox (note that a couple of the URLs contain special ASCII characters (not UTF8) and need to use Perl's \xNN encoding mechanism)
my $url_firefox_path = File::Spec->catdir("t", "samples", "real", "url", "Firefox");
_test_read_shortcut($url_firefox_path, "Google.URL", "Google", "https://www.google.com/");
_test_read_shortcut($url_firefox_path, "Myspace Social Entertainment.URL", "Myspace Social Entertainment", "http://www.myspace.com/");
_test_read_shortcut($url_firefox_path, "Yahoo!.URL", "Yahoo!", "http://www.yahoo.com/");
_test_read_shortcut($url_firefox_path, "1.URL", "1", "http://japan.zdnet.com/");
_test_read_shortcut($url_firefox_path, "2.URL", "2", "http://www.microsoft.com/sv-se/default.aspx");
_test_read_shortcut($url_firefox_path, "3.URL", "3", "http://www.google.se/#sclient=tablet-gws&hl=sv&tbo=d&q=sverige&oq=sveri&gs_l=tablet-gws.1.1.0l3.13058.15637.28.17682.5.2.2.1.1.0.143.243.0j2.2.0...0.0...1ac.1.xX8iu4i9hYM&pbx=1&fp=1&bpcl=40096503&biw=1280&bih=800&bav=on.2,or.r_gc.r_pw.r_qf.&cad=b");
_test_read_shortcut($url_firefox_path, "4.URL", "4", "http://www.-\xFD?\x9C.?\xA1.cn/");
_test_read_shortcut($url_firefox_path, "5.URL", "5", "http://cn.yahoo.com/");
_test_read_shortcut($url_firefox_path, "6.URL", "6", "http://\xFC*.-\xFD/");
_test_read_shortcut($url_firefox_path, "7.URL", "7", "http://www.baidu.com/");

# URL tests: Internet Explorer
my $url_ie_path = File::Spec->catdir("t", "samples", "real", "url", "IE");
_test_read_shortcut($url_ie_path, "cn.yahoo.com.url", "cn.yahoo.com", "http://cn.yahoo.com/");
_test_read_shortcut($url_ie_path, "Google.url", "Google", "https://www.google.com/");
_test_read_shortcut($url_ie_path, "Myspace  Social Entertainment.url", "Myspace  Social Entertainment", "http://www.myspace.com/");
_test_read_shortcut($url_ie_path, "Yahoo!.url", "Yahoo!", "http://www.yahoo.com/");
_test_read_shortcut($url_ie_path, "1.url", "1", "http://www.microsoft.com/sv-se/default.aspx");
_test_read_shortcut($url_ie_path, "2.url", "2", "http://www.中国政府.政务.cn/");
_test_read_shortcut($url_ie_path, "3.url", "3", "http://www.baidu.com/");

# URL tests: Hypothetical
my $url_fake_path = File::Spec->catdir("t", "samples", "fake", "url");

_test_read_shortcut($url_fake_path, "LotsOfWhitespace.url", "LotsOfWhitespace", "https://www.google.com/");

_test_read_shortcut($url_fake_path, "GarbledEntry.url", "GarbledEntry", "https://www.google.com/");

eval { read_shortcut_file(File::Spec->catdir ($url_fake_path, "HeaderOnly.url")) };
like ($@, qr/URL not found in file.*/, "Url not found");


# Website tests: IE9
my $website_ie9_path = File::Spec->catdir("t", "samples", "real", "website", "IE9");
_test_read_shortcut($website_ie9_path, "Google.website", "Google", "https://www.google.com/");
_test_read_shortcut($website_ie9_path, "Microsoft Corporation.website", "Microsoft Corporation", "http://www.microsoft.com/sv-se/default.aspx");
_test_read_shortcut($website_ie9_path, "Myspace  Social Entertainment.website", "Myspace  Social Entertainment", "http://www.myspace.com/");
_test_read_shortcut($website_ie9_path, "Yahoo!.website", "Yahoo!", "http://www.yahoo.com/");
_test_read_shortcut($website_ie9_path, "1.website", "1", "http://japan.zdnet.com/");
_test_read_shortcut($website_ie9_path, "2.website", "2", "http://www.google.se/");
_test_read_shortcut($website_ie9_path, "3.website", "3", "http://www.中国政府.政务.cn/");
_test_read_shortcut($website_ie9_path, "4.website", "4", "http://cn.yahoo.com/");
_test_read_shortcut($website_ie9_path, "5.website", "5", "http://导航.中国/");
_test_read_shortcut($website_ie9_path, "6.website", "6", "http://www.baidu.com/");

# Website tests: IE10
my $website_ie10_path = File::Spec->catdir("t", "samples", "real", "website", "IE10");
_test_read_shortcut($website_ie10_path, "Google.website", "Google", "https://www.google.com/");
_test_read_shortcut($website_ie10_path, "Microsoft Corporation.website", "Microsoft Corporation", "http://www.microsoft.com/sv-se/default.aspx");
_test_read_shortcut($website_ie10_path, "Myspace  Social Entertainment.website", "Myspace  Social Entertainment", "http://www.myspace.com/");
_test_read_shortcut($website_ie10_path, "Yahoo!.website", "Yahoo!", "http://www.yahoo.com/");
_test_read_shortcut($website_ie10_path, "1.website", "1", "http://japan.zdnet.com/");
_test_read_shortcut($website_ie10_path, "2.website", "2", "http://www.google.se/");
_test_read_shortcut($website_ie10_path, "3.website", "3", "http://www.中国政府.政务.cn/");
_test_read_shortcut($website_ie10_path, "4.website", "4", "http://cn.yahoo.com/");
_test_read_shortcut($website_ie10_path, "5.website", "5", "http://导航.中国/");
_test_read_shortcut($website_ie10_path, "6.website", "6", "http://www.baidu.com/");


# Test read_shortcut_file_url
is(read_shortcut_file_url(File::Spec->catfile($gnome_path, "Google.desktop")), "https://www.google.com/", "read_shortcut_file_url");



SKIP: {
    if(!defined(check_install( module => 'Mac::PropertyList' ))) {
        skip ("Mac::PropertyList not installed.  Cannot test webloc functionality unless this package is installed.", 0);
    }

    # Binary plist tests
    my $webloc_bin_path = File::Spec->catdir("t", "samples", "real", "webloc", "binary");
    my $webloc_bin_percent_path = File::Spec->catdir($webloc_bin_path, "percent_encoded");
    _test_read_shortcut($webloc_bin_path, "Google.webloc", "Google", "https://www.google.com/");
    _test_read_shortcut($webloc_bin_path, "Yahoo!.webloc", "Yahoo!", "http://www.yahoo.com/");
    _test_read_shortcut($webloc_bin_path, "1.webloc", "1", "http://japan.zdnet.com/");
    _test_read_shortcut($webloc_bin_path, "2.webloc", "2", "http://www.microsoft.com/sv-se/default.aspx");
    _test_read_shortcut($webloc_bin_path, "3.webloc", "3", "http://www.myspace.com/");
    _test_read_shortcut($webloc_bin_path, "4.webloc", "4", "http://www.google.se/#sclient=tablet-gws&hl=sv&tbo=d&q=sverige&oq=sveri&gs_l=tablet-gws.1.1.0l3.13058.15637.28.17682.5.2.2.1.1.0.143.243.0j2.2.0...0.0...1ac.1.xX8iu4i9hYM&pbx=1&fp=1&bpcl=40096503&biw=1280&bih=800&bav=on.2,or.r_gc.r_pw.r_qf.&cad=b");
    _test_read_shortcut($webloc_bin_path, "5.webloc", "5", "http://www.xn--fiqs8sirgfmh.xn--zfr164b.cn/");
    _test_read_shortcut($webloc_bin_path, "6.webloc", "6", "http://cn.yahoo.com/");
    _test_read_shortcut($webloc_bin_path, "7.webloc", "7", "http://xn--fet810g.xn--fiqs8s/");
    _test_read_shortcut($webloc_bin_path, "8.webloc", "8", "http://www.baidu.com/");
    _test_read_shortcut($webloc_bin_percent_path, "1.webloc", "1", "http://%E5%AF%BC%E8%88%AA.%E4%B8%AD%E5%9B%BD/");

    # XML plist tests
    my $webloc_xml_path = File::Spec->catdir("t", "samples", "real", "webloc", "xml");
    my $webloc_xml_percent_path = File::Spec->catdir($webloc_xml_path, "percent_encoded");
    _test_read_shortcut($webloc_xml_path, "Google.webloc", "Google", "https://www.google.com/");
    _test_read_shortcut($webloc_xml_path, "Yahoo!.webloc", "Yahoo!", "http://www.yahoo.com/");
    _test_read_shortcut($webloc_xml_path, "1.webloc", "1", "http://japan.zdnet.com/");
    _test_read_shortcut($webloc_xml_path, "2.webloc", "2", "http://www.microsoft.com/sv-se/default.aspx");
    _test_read_shortcut($webloc_xml_path, "3.webloc", "3", "http://www.myspace.com/");
    _test_read_shortcut($webloc_xml_path, "4.webloc", "4", "http://www.google.se/#sclient=tablet-gws&hl=sv&tbo=d&q=sverige&oq=sveri&gs_l=tablet-gws.1.1.0l3.13058.15637.28.17682.5.2.2.1.1.0.143.243.0j2.2.0...0.0...1ac.1.xX8iu4i9hYM&pbx=1&fp=1&bpcl=40096503&biw=1280&bih=800&bav=on.2,or.r_gc.r_pw.r_qf.&cad=b");
    _test_read_shortcut($webloc_xml_path, "5.webloc", "5", "http://www.xn--fiqs8sirgfmh.xn--zfr164b.cn/");
    _test_read_shortcut($webloc_xml_path, "6.webloc", "6", "http://cn.yahoo.com/");
    _test_read_shortcut($webloc_xml_path, "7.webloc", "7", "http://xn--fet810g.xn--fiqs8s/");
    _test_read_shortcut($webloc_xml_path, "8.webloc", "8", "http://www.baidu.com/");
    _test_read_shortcut($webloc_xml_percent_path, "1.webloc", "1", "http://www.%E4%B8%AD%E5%9B%BD%E6%94%BF%E5%BA%9C.%E6%94%BF%E5%8A%A1.cn/");
    _test_read_shortcut($webloc_xml_percent_path, "2.webloc", "2", "http://%E5%AF%BC%E8%88%AA.%E4%B8%AD%E5%9B%BD/");

    # Missing file
    eval { read_shortcut_file("bad_file.webloc") };
    like ($@, qr/Error opening file.*/, "Read bad webloc file");

    # Plist Error Test
    my $webloc_xml_fake_path = File::Spec->catdir("t", "samples", "fake", "webloc", "xml");

    eval { read_shortcut_file(File::Spec->catdir ($webloc_xml_fake_path, "MissingDictionary.webloc")) } ;
    like ($@, qr/Webloc plist file does not contain a dictionary.*/);

    eval { read_shortcut_file(File::Spec->catdir ($webloc_xml_fake_path, "MissingUrl.webloc")) } ;
    like ($@, qr/Webloc plist file does not contain a URL.*/);
}

done_testing;
