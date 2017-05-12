use warnings;
use strict;

use Encode qw(decode);
use IO::File ();
use Params::Classify qw(scalar_class);
use Scalar::Util qw(blessed reftype);
use XML::Easy::Content ();
use XML::Easy::Element ();
use t::ErrorCases qw(
	COUNT_error_encname test_error_encname
	COUNT_error_content_recurse test_error_content_recurse
	COUNT_error_element_recurse test_error_element_recurse
);
use utf8 ();

use Test::More tests => 1 + 2*171 + 2 +
	COUNT_error_content_recurse*3 +
	COUNT_error_element_recurse*3 +
	COUNT_error_encname*4;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "XML::Easy::Text", qw(
		xml10_write_content xml10_write_element
		xml10_write_document xml10_write_extparsedent
); }

sub regraded($$);
sub regraded($$) {
	my($regrade, $x) = @_;
	my $class = scalar_class($x);
	if($class eq "STRING") {
		$regrade->($x);
	} elsif($class eq "BLESSED" || $class eq "REF") {
		my $blessed = blessed($x);
		my $type = reftype($x);
		if($type =~ /\A(?:REF|SCALAR|LVALUE|GLOB)\z/) {
			$x = \regraded($regrade, $$x);
		} elsif($type eq "ARRAY") {
			$x = [ map { regraded($regrade, $_) } @$x ];
		} elsif($type eq "HASH") {
			$x = { map {
				(regraded($regrade, $_) =>
					regraded($regrade, $x->{$_}))
			} keys %$x };
		} else {
			return $x;
		}
		bless($x, $blessed) if $class eq "BLESSED";
	}
	return $x;
}

sub upgraded($) { regraded(\&utf8::upgrade, $_[0]) }
sub downgraded($) { regraded(sub($) { utf8::downgrade($_[0], 1) }, $_[0]) }

my %writer = (
	c => \&xml10_write_content,
	e => \&xml10_write_element,
	d => \&xml10_write_document,
	x => \&xml10_write_extparsedent,
);

sub try_write($$$) {
	my $result = eval {
		$writer{$_[0]}->($_[1], defined($_[2]) ? ($_[2]) : ())
	};
	return $@ ne "" ? [ "error", $@ ] : [ "ok", $result ];
}

my $data_in = IO::File->new("t/write.data", "r") or die;
my $line = $data_in->getline;

while(1) {
	$line =~ /\A###(?:([a-z])([^\n]+)?)?\n\z/ or die;
	last unless defined $1;
	my($prod, $encname) = ($1, $2);
	$line = $data_in->getline;
	last unless defined $line;
	my $input = "";
	while($line ne "#\n") {
		die if $line =~ /\A###/;
		$input .= $line;
		$line = $data_in->getline;
		die unless defined $line;
	}
	die if $input eq "";
	$input = eval($input);
	my $correct = "";
	while(1) {
		$line = $data_in->getline;
		die unless defined $line;
		last if $line =~ /\A###/;
		$correct .= $line;
	}
	chomp $correct;
	$correct =~ tr/~/\r/;
	$correct =~ s/\$\((.*?)\)/$1 x 40000/seg;
	$correct =~ s/\$\{(.*?)\}/$1 x 32764/seg;
	$correct = decode("UTF-8", $correct);
	$correct = $correct =~ /\A[:'A-Za-z ]+\z/ ? [ "error", "$correct\n" ] :
						    [ "ok", $correct ];
	$encname = eval($encname) if defined $encname;
	is_deeply try_write($prod, upgraded($input), upgraded($encname)),
		$correct;
	is_deeply try_write($prod, downgraded($input), downgraded($encname)),
		$correct;
}

my $c0a = ["bop"];
my $c0o = XML::Easy::Content->new($c0a);
is xml10_write_content($c0a), xml10_write_content($c0o);
is xml10_write_extparsedent($c0a), xml10_write_extparsedent($c0o);

test_error_content_recurse \&xml10_write_content;
test_error_element_recurse \&xml10_write_element;
test_error_element_recurse \&xml10_write_document;
test_error_element_recurse sub { xml10_write_document($_[0], "UTF-8") };
test_error_content_recurse \&xml10_write_extparsedent;
test_error_content_recurse sub { xml10_write_extparsedent($_[0], "UTF-8") };

test_error_encname sub {
	die "invalid XML data: encoding name isn't a string\n"
		unless defined $_[0];
	xml10_write_document(XML::Easy::Element->new("foo", {}, [""]), $_[0]);
};
test_error_encname sub {
	die "invalid XML data: encoding name isn't a string\n"
		unless defined $_[0];
	xml10_write_extparsedent([""], $_[0]);
};

test_error_encname sub {
	die "invalid XML data: encoding name isn't a string\n"
		unless defined $_[0];
	xml10_write_document(undef, $_[0]);
};
test_error_encname sub {
	die "invalid XML data: encoding name isn't a string\n"
		unless defined $_[0];
	xml10_write_extparsedent(undef, $_[0]);
};

1;
