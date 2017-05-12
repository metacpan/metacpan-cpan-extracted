#! perl -w

use strict;
use warnings;

use Test::More;

my @files = qw(
  Tripletail/CharConv.pm
  Tripletail/Cookie.pm
  Tripletail/Filter/SEO.pm
  Tripletail/Filter/TEXT.pm
  Tripletail/Filter/HeaderOnly.pm
  Tripletail/Filter/MobileHTML.pm
  Tripletail/Filter/Binary.pm
  Tripletail/Filter/MemCached.pm
  Tripletail/Filter/HTML.pm
  Tripletail/Filter/CSV.pm
  Tripletail/DB.pm
  Tripletail/Debug/Watch.pm
  Tripletail/Template.pm
  Tripletail/Ini.pm
  Tripletail/Validator/FilterFactory.pm
  Tripletail/Validator/Filter.pm
  Tripletail/Debug.pm
  Tripletail/HtmlMail.pm
  Tripletail/FileSentinel.pm
  Tripletail/Sendmail/MailQueue.pm
  Tripletail/Sendmail/Smtp.pm
  Tripletail/Sendmail/Sendmail.pm
  Tripletail/Sendmail/Esmtp.pm
  Tripletail/Validator.pm
  Tripletail/RawCookie.pm
  Tripletail/DateTime.pm
  Tripletail/InputFilter.pm
  Tripletail/Value.pm
  Tripletail/Mail.pm
  Tripletail/Session.pm
  Tripletail/MemCached.pm
  Tripletail/MemorySentinel.pm
  Tripletail/Sendmail.pm
  Tripletail/DateTime/JPHoliday.pm
  Tripletail/Form.pm
  Tripletail/Filter.pm
  Tripletail/Error.pm
  Tripletail/Pager.pm
  Tripletail/Template/Node.pm
  Tripletail/InputFilter/SEO.pm
  Tripletail/InputFilter/Plain.pm
  Tripletail/InputFilter/MobileHTML.pm
  Tripletail/InputFilter/HTML.pm
  Tripletail/TagCheck.pm
  Tripletail/CSV.pm
);
plan tests =>
  + 1 # use Tripletail.
  + @files;
;

use_ok( Tripletail => '/dev/null' );
diag( "Testing Tripletail $Tripletail::VERSION" );

foreach my $file (@files)
{
  require_ok($file);
}
