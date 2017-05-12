#!/usr/bin/perl

# $Id: 50_books.t 40 2006-10-13 04:23:07Z  $

use strict;
use vars qw($CAN_PARSE_DATES $idx);

use File::Basename 'dirname';
use Test::More;

use WebService::ISBNDB::API;
use WebService::ISBNDB::API::Books;

BEGIN
{
    eval "use Date::Parse";
    $CAN_PARSE_DATES = ($@) ? 0 : 1;
}

my $dir = dirname $0;
do "$dir/util.pl";
do "$dir/DUMMY.pm";

WebService::ISBNDB::API->set_default_api_key(api_key());

open my $fh, "< $dir/xml/Books-isbn=0596002068.xml"
   or die "Error opening test XML: $!";
my $body = join('', <$fh>);
close($fh);
my $change_time = ($body =~ /change_time="(.*?)"/)[0];
my $change_time_sec = $CAN_PARSE_DATES ? str2time($change_time) : 0;
my $price_time = ($body =~ /price_time="(.*?)"/)[0];
my $price_time_sec = $CAN_PARSE_DATES ? str2time($price_time) : 0;
my @subj = ($body =~ /Subject\s+subject_id="(.*?)"/g);
my @auth = ($body =~ /Person\s+person_id="(.*?)"/g);
my @marc = ($body =~ /<MARC\s+(.*?)\s+\/>/g);
my @price = ($body =~ /<Price\s+(.*?)\s+\/>/g);

# 52 is the number of predefined tests, while the lists define the number of
# on-the-fly tests.
plan tests => 52 + @auth + @subj + 4*@marc + 12*@price;

# For future ref: Need a book (or several) that has more of the data fields
my $pwswp = '0596002068';

# Try creating a blank object, just to see what works:
my $book = WebService::ISBNDB::API::Books->new();
isa_ok($book, 'WebService::ISBNDB::API::Books');
# Check some defaults
is($book->get_protocol, 'REST', 'Default protocol set');
is($book->get_api_key, api_key(), 'Default API key');

# Change to the dummy agent class
WebService::ISBNDB::API->set_default_protocol('DUMMY');

# Try a real book... like, say, mine?
$book = WebService::ISBNDB::API::Books->new($pwswp);
isa_ok($book, 'WebService::ISBNDB::API::Books');
is($book->get_id, 'programming_web_services_with_perl', 'ID');
is($book->get_isbn, $pwswp, 'ISBN');
like($book->get_title, '/^programming web services with perl$/i', 'Title');
like($book->get_longtitle, '/^$/', 'Long title');
like($book->get_authors_text, '/^Randy J. Ray and Pavel Kulchenko$/i',
    'Authors (text)');
like($book->get_publisher_text,
     qr/^Farnham ; O'Reilly, 2002 printing, c2003\.$/i, 'Publisher (text)');
is($book->get_dewey_decimal, '005.2762', 'Dewey decimal');
is($book->get_dewey_decimal_normalized, '5.2762',
   'Dewey decimal (normalized)');
is($book->get_lcc_number, 'TK5105.888', 'LCC number');
is($book->get_language, 'eng', 'Language');
is($book->get_physical_description_text, 'xiii, 470 p. : ill. ; 24 cm.',
   'Physical description text');
is($book->get_edition_info, '', 'Edition info');
is($book->get_change_time, $change_time, 'Change time');
SKIP: {
    skip 'Date::Parse not installed', 1 unless $CAN_PARSE_DATES;

    is($book->get_change_time_sec, $change_time_sec, 'Change time (seconds)');
}
is($book->get_price_time, $price_time, 'Price time');
SKIP: {
    skip 'Date::Parse not installed', 1 unless $CAN_PARSE_DATES;

    is($book->get_price_time_sec, $price_time_sec, 'Price time (seconds)');
}
is($book->get_summary, '', 'Summary');
is($book->get_notes,
  'Includes bibliographical references (p. 434-437) and index.', 'Notes');
is($book->get_urlstext, '', 'URLs text');
is($book->get_awardstext, '', 'Awards text');

# Look at the subjects
my $subjects = $book->get_subjects;
is(scalar(@$subjects), scalar(@subj), 'Subjects count matches XML');
# Sub-tests for subjects
for $idx (0 .. $#$subjects)
{
    is($subjects->[$idx]->get_id, $subj[$idx], "ID of subject $idx");
}
# Look at the authors
my $authors = $book->get_authors;
is(scalar(@$authors), scalar(@auth), 'Authors count matches XML');
# Sub-tests for authors
for $idx (0 .. $#$authors)
{
    is($authors->[$idx]->get_id, $auth[$idx], "ID of author $idx");
}
# Look at MARC data
my $marcs = $book->get_marc;
is(scalar(@$marcs), scalar(@marc), 'MARC count matches XML');
for $idx (0 .. $#$marcs)
{
    my $library_name = ($marc[$idx] =~ /library_name="(.*?)"/)[0];
    my $marc_url = ($marc[$idx] =~ /marc_url="(.*?)"/)[0];
    my $last_update = ($marc[$idx] =~ /last_update="(.*?)"/)[0];
    my $last_update_sec = $CAN_PARSE_DATES ? str2time($last_update) : 0;

    is($marcs->[$idx]->{library_name}, $library_name, "MARC $idx library name");
    is($marcs->[$idx]->{marc_url}, $marc_url, "MARC $idx URL");
    is($marcs->[$idx]->{last_update}, $last_update, "MARC $idx last update");
    SKIP: {
        skip 'Date::Parse not installed', 1 unless $CAN_PARSE_DATES;

        is($marcs->[$idx]->{last_update_sec}, $last_update_sec,
           "MARC $idx last update (seconds)");
    }
}
# Look at price data
my $prices = $book->get_prices;
is(scalar(@$prices), scalar(@price), 'Price count matches XML');
for $idx (0 .. $#$prices)
{
    my $store_isbn = ($price[$idx] =~ /store_isbn="(.*?)?"/)[0];
    my $store_title = ($price[$idx] =~ /store_title="(.*?)?"/)[0];
    my $store_url = ($price[$idx] =~ /store_url="(.*?)"/)[0];
    $store_url =~ s/&amp;/&/g;
    my $store_id = ($price[$idx] =~ /store_id="(.*?)"/)[0];
    my $currency_code = ($price[$idx] =~ /currency_code="(.*?)"/)[0];
    my $is_in_stock = ($price[$idx] =~ /is_in_stock="(.*?)"/)[0];
    my $is_historic = ($price[$idx] =~ /is_historic="(.*?)"/)[0];
    my $is_new = ($price[$idx] =~ /is_new="(.*?)"/)[0];
    my $check_time = ($price[$idx] =~ /check_time="(.*?)"/)[0];
    my $check_time_sec = $CAN_PARSE_DATES ? str2time($check_time) : 0;
    my $currency_rate = ($price[$idx] =~ /currency_rate="(.*?)"/)[0];
    my $price = ($price[$idx] =~ /price="(.*?)"/)[0];

    is($prices->[$idx]->{store_isbn}, $store_isbn, "Price $idx store ISBN");
    is($prices->[$idx]->{store_title}, $store_title, "Price $idx store title");
    is($prices->[$idx]->{store_url}, $store_url, "Price $idx store URL");
    is($prices->[$idx]->{store_id}, $store_id, "Price $idx store ID");
    is($prices->[$idx]->{currency_code}, $currency_code,
       "Price $idx currency code");
    is($prices->[$idx]->{is_in_stock}, $is_in_stock,
       "Price $idx is in stock (boolean)");
    is($prices->[$idx]->{is_historic}, $is_historic,
       "Price $idx is historic (boolean)");
    is($prices->[$idx]->{is_new}, $is_new, "Price $idx is new (boolean)");
    is($prices->[$idx]->{currency_rate}, $currency_rate,
       "Price $idx currency rate");
    is($prices->[$idx]->{price}, $price, "Price $idx price");
    is($prices->[$idx]->{check_time}, $check_time, "Price $idx check time");
    SKIP: {
        skip 'Date::Parse not installed', 1 unless $CAN_PARSE_DATES;

        is($prices->[$idx]->{check_time_sec}, $check_time_sec,
           "Price $idx check time (seconds)");
    }
}

# Try the same book, but with the factory construction. Don't need to repeat
# the inner-content tests.
$book = WebService::ISBNDB::API->new(Books => $pwswp);
isa_ok($book, 'WebService::ISBNDB::API::Books');
is($book->get_id, 'programming_web_services_with_perl', 'ID');
is($book->get_isbn, $pwswp, 'ISBN');
like($book->get_title, '/^programming web services with perl$/i', 'Title');
like($book->get_longtitle, '/^$/', 'Long title');
like($book->get_authors_text, '/^Randy J. Ray and Pavel Kulchenko$/i',
    'Authors (text)');
like($book->get_publisher_text,
     qr/^Farnham ; O'Reilly, 2002 printing, c2003\.$/i, 'Publisher (text)');
is($book->get_dewey_decimal, '005.2762', 'Dewey decimal');
is($book->get_dewey_decimal_normalized, '5.2762',
   'Dewey decimal (normalized)');
is($book->get_lcc_number, 'TK5105.888', 'LCC number');
is($book->get_language, 'eng', 'Language');
is($book->get_physical_description_text, 'xiii, 470 p. : ill. ; 24 cm.',
   'Physical description text');
is($book->get_edition_info, '', 'Edition info');
is($book->get_change_time, $change_time, 'Change time');
SKIP: {
    skip 'Date::Parse not installed', 1 unless $CAN_PARSE_DATES;

    is($book->get_change_time_sec, $change_time_sec, 'Change time (seconds)');
}
is($book->get_price_time, $price_time, 'Price time');
SKIP: {
    skip 'Date::Parse not installed', 1 unless $CAN_PARSE_DATES;

    is($book->get_price_time_sec, $price_time_sec, 'Price time (seconds)');
}
is($book->get_summary, '', 'Summary');
is($book->get_notes,
   'Includes bibliographical references (p. 434-437) and index.', 'Notes');
is($book->get_urlstext, '', 'URLs text');
is($book->get_awardstext, '', 'Awards text');

# Try it with the Book ID instead of the ISBN
$book = WebService::ISBNDB::API->new(Books =>
                                     'programming_web_services_with_perl');
isa_ok($book, 'WebService::ISBNDB::API::Books');
is($book->get_id, 'programming_web_services_with_perl', 'ID');
is($book->get_isbn, $pwswp, 'ISBN');

exit;
