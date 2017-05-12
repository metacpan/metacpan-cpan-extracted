
# Time-stamp: "2004-04-03 21:46:04 ADT"

require 5;
use strict;
use Test;
BEGIN { plan tests => 92 };
use Text::Shoebox::Lexicon;
use Text::Shoebox::Entry;
ok 1;

print "# Entry class tests... Text::Shoebox::Entry v$Text::Shoebox::Entry::VERSION\n";

sub group (&) {
  eval { &{$_[0]} };
  return 1 unless $@;
  print "# Die in test-group : ", $@;
  return 0;
}

my @in = (
  'foo', 'bar', 'baz', " quux foo\n\t\tchacha  ", 'thwak', ''
);
my $e = Text::Shoebox::Entry->new(@in);
ok $e;
ok $e->headword_field, "foo";
ok $e->headword, "bar";
ok $e->_('foo'), 'bar';
ok $e->_('baz'), $in[3];
ok $e->_('thwak'), $in[5];
ok !defined $e->_('cronk');
ok !defined $e->_('');
ok !defined $e->_("\e123\n\r");

{
  my @e = $e->as_list;
  ok scalar(@e), scalar(@in);
  ok join("+", @e), join("+", @in);
}
{
  my @e = $e->keys;
  print "# Keys <@e>\n";
  ok scalar(@e), scalar(@in)/2;
  ok join("+", @e), join("+", @in[0,2,4]);
}
{
  my @e = $e->values;
  #print "# Values <@e>\n";
  ok scalar(@e), scalar(@in)/2;
  ok join("+", @e), join("+", @in[1,3,5]);
}


sub e { Text::Shoebox::Entry->new(@_) }

print "# Testing is_null...\n";
ok !$e->is_null;
ok !e($e->as_list)->is_null;
ok e()->is_null;


print "# Testing is_sane...\n";
ok $e->is_sane;
ok ! e()->is_sane;
ok ! e('thing' => \123)->is_sane;
ok ! e('' => 'foo')->is_sane;
ok ! e('thang', 'zorch', '' => 'foo')->is_sane;
ok ! e(undef() => 'foo')->is_sane;
ok ! e('thang', 'zorch', undef() => 'foo')->is_sane;


print "# Testing pair_count and pair...\n";
ok $e->pair_count, 3;
ok join("+",$e->pair(0)), "foo+bar";
ok join("+",$e->pair(2)), "thwak+";
ok join("+",$e->pair(0,2)), "foo+bar+thwak+";
ok join("+","X:", $e->pair()), "X:";


print "# Testing are_keys_unique...\n";
ok $e->are_keys_unique;
ok e()->are_keys_unique;
ok e(qw(foo bar))->are_keys_unique;
ok e(qw(foo bar baz quux))->are_keys_unique;
ok e(qw(foo bar baz quux ling quux))->are_keys_unique;
ok ! e(qw(foo bar baz quux foo quux))->are_keys_unique;
ok ! e(qw(foo bar baz quux baz quux))->are_keys_unique;


ok group { print "# Testing copy...\n";
  my $c = $e->copy;
  ok $c != $e;
  ok    scalar($c->as_list)  == scalar($e->as_list);
  ok join("+", $c->as_list), join("+", $e->as_list);
  $c->as_arrayref->[1] = 'squim';
  # $c->dump; $e->dump;
  ok join("+", $c->as_list) ne join("+", $e->as_list);
  1;
};


ok group { print "# Testing as_hashref...\n";
  my $h = $e->as_hashref;
  ok $h && %$h;
  ok scalar(keys(%$h)), 3;
  ok join("+", sort keys %$h), "baz+foo+thwak";
  ok $h->{'foo'}, $e->_('foo');
  ok $h->{'baz'}, $e->_('baz');
  ok $h->{'thwak'}, $e->_('thwak');
  1;
};



ok group { print "# Testing as_HoL...\n";
  my $h = $e->as_HoL;
  ok $h && %$h;
  ok scalar(keys(%$h)), 3;
  ok scalar(grep @$_ == 1, values(%$h)), 3; # make sure all single-entry
  ok join("+", sort keys %$h), "baz+foo+thwak";
  ok $h->{'foo'}->[0], $e->_('foo');
  ok $h->{'baz'}->[0], $e->_('baz');
  ok $h->{'thwak'}->[0], $e->_('thwak');
  # Test stringification magic
  ok "$h->{'foo'}", $e->_('foo');
  ok "$h->{'baz'}", $e->_('baz');
  ok "$h->{'thwak'}", $e->_('thwak');
  1;
};

ok group { print "# More testing as_HoL...\n";
  my $h = e(qw(foo bar foo baz quim quonk))->as_HoL;
  ok $h && %$h;
  ok scalar( keys %$h ), 2;
  ok join("+", sort keys %$h), "foo+quim";
  ok scalar @{$h->{'foo'}}, 2;
  ok scalar @{$h->{'quim'}}, 1;
  ok join("+", @{$h->{'foo'}}), "bar+baz";
  ok "$h->{'foo'}", "bar; baz";
  1;
};


print "# Testing as_HoLS...\n";
ok group {
  my $e = e(qw(foo bar foo baz quim quonk));
  my $h = $e->as_HoLS;
  ok scalar( keys %$h ), 2;
  ok join("+", sort keys %$h), "foo+quim";
  ok scalar @{$h->{'foo'}}, 2;
  ok scalar @{$h->{'quim'}}, 1;
  print "# foo => [ ", map("<$_> ", @{$h->{'foo'}}), "]\n";
  ok grep(ref($_) eq "SCALAR", map @$_, values %$h), 3;
  ok join("+", map $$_, @{$h->{'foo'}}), "bar+baz";
  # Finally test mutability / coreferentiality:
  ${ $h->{'foo'}->[0] } = "PIES";
  ok $e->_('foo')->[0], 'PIES';
};

print "# Testing as_doublets...\n";
ok group {
  my $e = e(qw(foo bar foo baz quim quonk));
  my @p = $e->as_doublets;
  ok scalar(@p), 3;
  ok grep(ref($_) eq 'ARRAY', @p), 3;
  ok grep(@$_ == 2, @p), 3;
  ok join("|", map join("+", @$_), @p), "foo+bar|foo+baz|quim+quonk";
};

print "# Testing as_xml...\n";
ok group {
  my $e = e(qw(foo bar foo baz quim quonk&griggle));
  ok $e->as_xml, '/^\s*<foo>bar<\/foo>\s*<foo>baz<\/foo>\s*<quim>quonk&amp;griggle<\/quim>\s*$/';
};

print "# Testing as_xml_pairs...\n";
ok group {
  my $e = e(qw(foo bar foo baz quim quonk&griggle));
  ok $e->as_xml_pairs, '/^\s*<pair key="foo" value="bar" />\s*<pair key="foo" value="baz" />\s*<pair key="quim" value="quonk&amp;griggle" />\s*$/';
  ok $e->as_xml_pairs('Fang', 'sprong', 'zik:zak'), '/^\s*<Fang sprong="foo" zik:zak="bar" />\s*<Fang sprong="foo" zik:zak="baz" />\s*<Fang sprong="quim" zik:zak="quonk&amp;griggle" />\s*$/';
};


print "# Testing scrunch...\n";
$e->scrunch;
ok !defined $e->_('thwak');
ok scalar($e->keys), 2;
ok $e->_('foo'), 'bar';
ok $e->_('baz'), "quux foo chacha";

print "# Bye...\n";
ok 1;

