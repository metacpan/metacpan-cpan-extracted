#!/usr/local/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use lib 'lib';
BEGIN { use lib qw(.); $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;
#for ( sort keys %INC ) { print "$_: $INC{$_}\n"; }
}
use Text::Macros;
$loaded = 1;
report(1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub report {
	$TEST_NUM++;
	print ( $_[0] ? "ok $TEST_NUM\n" : "not ok $TEST_NUM\n" );
}

%macval = (
  alpha => 'foo',
  gamma => 'bar',
);

{
  # make a derived class:
  package TestMacro;
  @TestMacro::ISA = qw( Text::Macros );
  sub parse_args {
    my( $self, $arg_text ) = @_;
    map   { s/^\s+//; s/\s+$//; $_ }
    split /:/, $arg_text;
  }
}

$D0 = bless {}, 'D0';
$D1 = bless {}, 'D1';
$D2 = bless {}, 'D2';
$D3 = bless {}, 'D3';
$D4 = bless {}, 'D4';

$A0 = new Text::Macros qw( {{ }} );   report( defined $A0 );
$A1 = new Text::Macros qw( {{ }} 1 ); report( defined $A1 );
$B0 = new Text::Macros "\Q[[", "\Q]]";    report( defined $B0 );
$B1 = new Text::Macros "\Q[[", "\Q]]", 1; report( defined $B1 );

$A3 = new Text::Macros '{{', '}}', 0, \&alt_parse_args;   report( defined $A3 );
$A4 = new TestMacro qw( {{ }} );   report( defined $A4 );

test0( $A0, $D0, 'A{{alpha}}B' => "A$macval{'alpha'}B" );

test0( $A0, $D0, 'A {{alpha}} B' => "A $macval{'alpha'} B" );
test0( $A0, $D0, 'A {{ alpha }} B' => "A $macval{'alpha'} B" );
test0( $A0, $D0, 'A {{alpha}} B {{gamma}} C' => "A $macval{'alpha'} B $macval{'gamma'} C" );

test0( $B0, $D0, 'A[[alpha]]B' => "A$macval{'alpha'}B" );

test0( $A1, $D0, 'A{{alpha}}B' => "A$macval{'alpha'}B" );
test0( $B1, $D0, 'A[[alpha]]B' => "A$macval{'alpha'}B" );

test0( $A1, $D1, 'A{{alpha}}B' => "A$macval{'alpha'}B" );
test0( $B1, $D1, 'A[[alpha]]B' => "A$macval{'alpha'}B" );

test1( $A0, $D1, 'A{{alpha}}B' => "A$macval{'alpha'}B" );
test1( $B0, $D1, 'A[[alpha]]B' => "A$macval{'alpha'}B" );

# test arg parsers:
test0( $A0, $D2, 'A{{alpha
  foo  

 bar }}B' => "Afoo barB" );

# test arg parsers:
test0( $A3, $D3, 'A{{alpha / foo / bar }}B' => "Afoo/barB" );

# test arg parsers:
test0( $A4, $D4, 'A{{alpha : foo : bar }}B' => "Afoo:barB" );

###################################################################


sub test0 {
  my( $macros, $data_obj, $template, $expected_result ) = @_;
  my $result = $macros->expand_macros( $data_obj, $template );

  report($result eq $expected_result);

  $result ne $expected_result  and
  $ENV{TEST_VERBOSE} and
    print STDERR "'$result' ne '$expected_result'\n";
}

sub test1 {
  my( $macros, $data_obj, $template, $expected_result ) = @_;
  my $result;
  eval {
    $result = $macros->expand_macros( $data_obj, $template );
  };

  report( defined($@) and ( $@ =~ /Can't/ ) );

  $ENV{TEST_VERBOSE} and
    print STDERR "$@\n";
}

sub D0::alpha { $macval{'alpha'} }
sub D0::gamma { $macval{'gamma'} }

sub D1::DESTROY { }
sub D1::AUTOLOAD {
  my $self = shift;
  my $name = $D1::AUTOLOAD;
  $name =~ s/.*:://;
  $macval{$name}
}

# macro takes arguments; joins with ' '
sub D2::alpha {
  my( $self, @args ) = @_;
  join ' ', @args;
}

# macro takes arguments; joins with '/'
sub D3::alpha {
  my( $self, @args ) = @_;
  join '/', @args;
}

# macro takes arguments; joins with ':'
sub D4::alpha {
  my( $self, @args ) = @_;
  join ':', @args;
}

#
# a replacement for the arg parser; pass it to new().
#
sub alt_parse_args {
  my( $macro_expander, $arg_text ) = @_;
  map   { s/^\s+//; s/\s+$//; $_ }
  split /\//, $arg_text;
}


