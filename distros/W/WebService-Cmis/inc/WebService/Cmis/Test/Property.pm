package WebSercice::Cmis::Test::Property;
use base qw(WebService::Cmis::Test);

use strict;
use warnings;


use Test::More;
use Error qw(:try);
use POSIX qw(strtod setlocale LC_NUMERIC);

setlocale LC_NUMERIC, "en_US.UTF-8";

sub test_PropertyType : Tests {
  my $this = shift;

  my $repo = $this->getRepository;

  my $typeDefs = $repo->getTypeDefinitions;
  isa_ok($typeDefs, 'WebService::Cmis::AtomFeed::ObjectTypes');

  while(my $objectType = $typeDefs->getNext) {

    # type attributes
    note("objectType=".$objectType->toString);
    my $objAttrs = $objectType->getAttributes;
    ok(defined $objAttrs);

    foreach my $key (keys %$objAttrs) {
      note("  * $key=$objAttrs->{$key}");
    }

    # type property definitions
    my $propDefs = $objectType->getPropertyDefinitions;
    ok(defined $propDefs);

    foreach my $propDef (values %$propDefs) {
      note("   propDef=".$propDef->toString);

      my $attrs = $propDef->getAttributes;
      ok(defined $attrs);
      foreach my $key (keys %$attrs) {
        ok(defined $attrs->{$key});
        #note("     | $key=$attrs->{$key}");
      }
    }
  }
}

sub test_PropertyBoolean_parse : Test(19) {
  my $this = shift;

  require WebService::Cmis::Property;
  is(0, WebService::Cmis::Property::parseBoolean(''));
  is(0, WebService::Cmis::Property::parseBoolean(' '));
  is(1, WebService::Cmis::Property::parseBoolean('x'));
  is(0, WebService::Cmis::Property::parseBoolean(0));
  is(1, WebService::Cmis::Property::parseBoolean(1));
  is(0, WebService::Cmis::Property::parseBoolean('0')); # argh
  is(1, WebService::Cmis::Property::parseBoolean('1'));
  is(1, WebService::Cmis::Property::parseBoolean('on'));
  is(1, WebService::Cmis::Property::parseBoolean('ON'));
  is(0, WebService::Cmis::Property::parseBoolean('off'));
  is(0, WebService::Cmis::Property::parseBoolean('OFF'));
  is(1, WebService::Cmis::Property::parseBoolean('true'));
  is(1, WebService::Cmis::Property::parseBoolean('True'));
  is(1, WebService::Cmis::Property::parseBoolean('TRUE'));
  is(0, WebService::Cmis::Property::parseBoolean('false'));
  is(0, WebService::Cmis::Property::parseBoolean('False'));
  is(0, WebService::Cmis::Property::parseBoolean('False'));
  is(1, WebService::Cmis::Property::parseBoolean('yes'));
  is(0, WebService::Cmis::Property::parseBoolean('no'));
}

sub test_PropertyBoolean_unparse : Test(6) {
  my $this = shift;

  require WebService::Cmis::Property;

  is('false', WebService::Cmis::Property::formatBoolean(0));
  is('false', WebService::Cmis::Property::formatBoolean('0'));
  is('true', WebService::Cmis::Property::formatBoolean('1'));
  is('true', WebService::Cmis::Property::formatBoolean(1));
  is('foobar', WebService::Cmis::Property::formatBoolean('foobar'));
  is('none', WebService::Cmis::Property::formatBoolean());
}

sub test_PropertyId_parse : Test(2) {
  my $this = shift;

  require WebService::Cmis::Property;
  is('123', WebService::Cmis::Property::parseId('123'));
  is(123, WebService::Cmis::Property::parseId(123));
}

sub test_PropertyInteger_parse : Test(4) {
  my $this = shift;

  require WebService::Cmis::Property;
  is(123, WebService::Cmis::Property::parseInteger(123));
  is(123, WebService::Cmis::Property::parseInteger('123 '));
  is(123, WebService::Cmis::Property::parseInteger(123));
  is(123, WebService::Cmis::Property::parseInteger("123.456"));
}

sub test_PropertyDecimal_parse : Test(2) {
  my $this = shift;

  require WebService::Cmis::Property;
  is(WebService::Cmis::Property::parseDecimal(123.456, 'propertyDecimal'), 123.456);
  is(WebService::Cmis::Property::parseDecimal('123.456 foobar', 'propertyDecimal'), "123.456");
}

sub test_Property_parseDateTime : Test(5) {
  my $this = shift;

  require WebService::Cmis::Property;

  is("1234567890+00:00", WebService::Cmis::Property::parseDateTime('2009-02-13T23:31:30+00:00'));
  is("1234567890Z", WebService::Cmis::Property::parseDateTime('2009-02-13T23:31:30Z'));
  is("1295363154+01:00", WebService::Cmis::Property::parseDateTime('2011-01-18T15:05:54.951+01:00'));
  is("1295363154+01:00", WebService::Cmis::Property::parseDateTime('2011-01-18T15:05:54+01:00'));
  ok(!defined WebService::Cmis::Property::DateTime->parse('foo'));
}

sub test_Property_DateTime_unparse : Test(2) {
  my $this = shift;

  require WebService::Cmis::Property::DateTime;

  my $string = WebService::Cmis::Property::DateTime->unparse("1234567890+00:00");
  is("2009-02-13T23:31:30+00:00", $string);

  $string = WebService::Cmis::Property::DateTime->unparse("1234567890Z");
  is("2009-02-13T23:31:30Z", $string);
}

sub test_Property_DateTime_toString : Test {
  my $this = shift;

  require WebService::Cmis::Property::DateTime;

  my $dateTime = WebService::Cmis::Property::newDateTime(
    id=>"test",
    value=>WebService::Cmis::Property::parseDateTime("2011-01-25T13:22:28+01:00"),
  );
  note("dateTime=".$dateTime->toString);
  is("test=1295961748+01:00", $dateTime->toString);
}

sub test_Property_parseDateTime_format : Test {
  my $this = shift;

  require WebService::Cmis::Property;
  require WebService::Cmis::Property::DateTime;

  my $testDateString = "2011-01-25T13:22:28+01:00";

  my $result = WebService::Cmis::Property::parseDateTime($testDateString);
  #print STDERR "result=$result\n";

  my $dateString = WebService::Cmis::Property::formatDateTime($result);
  #print STDERR "dateString=$dateString\n";

  is($testDateString, $dateString);
}

sub test_Property_formatDateTime : Test(5) {
  my $this = shift;

  require WebService::Cmis::Property;
  require WebService::Cmis::Property::DateTime;

  is("2011-01-18T15:05:54+01:00", WebService::Cmis::Property::formatDateTime("1295363154+01:00"));
  is("2011-01-18T15:05:54+01", WebService::Cmis::Property::formatDateTime("1295363154+01"));
  is("2011-01-18T15:05:54", WebService::Cmis::Property::formatDateTime("1295363154"));
  is('none', WebService::Cmis::Property::formatDateTime('foo'));
  is("1970-01-01T00:00:00", WebService::Cmis::Property::formatDateTime(0));
}

1;
