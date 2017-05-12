#! /usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..48\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::xSV;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $tests_done = 1;

my $csv = new Text::xSV(filename => "test.csv");
ok();

$csv->bind_header();
ok();

# With the first row test the mechanics...

# True while fetch row
$csv->get_row() ? ok() : not_ok();

my @results = $csv->extract("one", "two");
ok();

(("hello" eq $results[0] and "world" eq $results[1]))
  ? ok() : not_ok();

my %hash = $csv->extract_hash();
ok();

(("hello" eq $hash{one} and "world" eq $hash{two}))
  ? ok() : not_ok();

my $hash_ref = $csv->extract_hash();
ok();

(("hello" eq $hash_ref->{one} and "world" eq $hash_ref->{two}))
  ? ok() : not_ok();

%hash = $csv->extract_hash('one');
ok();

(("hello" eq $hash{one} and not defined($hash{two})))
  ? ok() : not_ok();


# The field "One" is missing..until I make that an alias.
eval {
  $csv->extract("One");
};
$@ ? ok() : not_ok();
$csv->alias("one", "One");
ok();
(($csv->extract("One"))[0] eq "hello")
  ? ok()
  : not_ok();
$csv->delete("One");
ok();
eval {
  $csv->extract("One");
};
$@ ? ok() : not_ok();
my $called = 0;
$csv->add_compute("full message", sub {
  my $self = shift;
  $called++;
  return join " ", map {
    defined($_) ? $_ : "<undef>"
  } $self->extract("one", "two");
});
ok();
(($csv->extract("full message"))[0] eq "hello world")
  ? ok() : not_ok();
# Test that deep recursion doesn't stop me from calling it again.
$csv->extract("full message");
ok();
# Caching works?
(1== $called) ? ok() : not_ok();

my @headers = $csv->get_fields;
ok();
@headers = sort @headers;
("@headers" eq "full message one test two")
  ? ok() : not_ok();

# I should catch infinite recursion
$csv->add_compute("recurse", sub {(shift)->extract("recurse")});
eval {
  $csv->extract("recurse");
};
($@ =~ m/^Infinite recursion detected/)
  ? ok() : not_ok();

test_row(undef, undef);
# And caching does not carry across rows
(($csv->extract("full message"))[0] eq "<undef> <undef>")
  ? ok() : not_ok();

test_row("hello", "world");
test_row("return\nhere","quotes\"here");
test_row("","");
test_row("",undef);

test_row("abcd" x 2000, "1234");
test_row("abcd" x 100000, "ABCD");

# And now test the fetchrow version, but we will still have
# the above deep recursion error so...
my $error;

$csv->set_error_handler( sub {$error = shift} );
ok();

%hash = $csv->fetchrow_hash();
ok();

(("hello" eq $hash{one} and "world" eq $hash{two}))
  ? ok() : not_ok();

$hash{"full message"} eq "hello world"
  ? ok() : not_ok();

($error =~ /Infinite recursion/) ? ok() : not_ok();

$csv->set_sep(":");
ok();

test_row("hello,world","other:stuff");

# Test whether I can set a multi-character seperator.
$csv->set_sep("::");
$error =~ /not of length 1/ ? ok() : not_ok();

# end of file
$csv->get_row() ? not_ok() : ok();

$csv->fetchrow_hash() ? not_ok() : ok();

my $temp_file = "temp.csv";

$csv = Text::xSV->new(filename => $temp_file);

$csv->print_row(qw(a b c d));
$csv->print_row("hello", "", undef, "with space");

$csv->set_dont_quote(1);
ok();
$csv->print_row("hello", "", undef, "with space");

$csv->set_dont_quote(0);
$csv->set_quote_all(1);
ok();
$csv->print_row("hello", "", undef, "with space");

$csv = undef; # Should delete the object.

$csv = Text::xSV->new(filename => $temp_file);

test_arrays_match([qw(a b c d)], scalar $csv->get_row());
test_arrays_match(["hello", "", undef, "with space"], scalar $csv->get_row());
test_next_line_is("hello,,,with space\n");
test_next_line_is(qq{"hello","","","with space"\n});

exit;

sub not_ok {
  print "not ";
  ok();
}

sub ok {
  $tests_done++;
  print "ok $tests_done\n";
}

# Takes two arrays by reference, sees that they match
sub test_arrays_match {
  my ($ary_1, $ary_2) = @_;
  if (@$ary_1 != @$ary_2) {
    not_ok();
    print STDERR "\nArrays have different length\n";
    return;
  }
  foreach (0..$#$ary_1) {
    if (
      defined($ary_1->[$_]) != defined($ary_2->[$_])
        or (
        defined($ary_1->[$_])
          and
        $ary_1->[$_] ne $ary_2->[$_]
      )
    ) {
      print STDERR "\nElement $_ differs in arrays ($ary_1->[$_] vs $ary_2->[$_]).\n";
      not_ok();
      return;
    }
  }
  ok();
}

sub test_row {
  unless ($csv->get_row()) {
    not_ok();
    return;
  } 
  #print STDERR $csv->extract("test"), "\n";
  test_arrays_match([@_], [$csv->extract("one", "two")]);
}

sub test_next_line_is {
  my $fh = $csv->{fh};
  my $next_line = <$fh>;
  my $expected = shift;
  if ($next_line eq $expected) {
    ok();
  }
  else {
    print STDERR "Wrong next line!\n  Expected: $expected  Got: $next_line";
    not_ok();
  }
}
