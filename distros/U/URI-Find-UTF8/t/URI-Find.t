#!perl -w
use strict;

# $Id: Find.t,v 1.12 2005/07/22 10:02:37 roderick Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use vars qw($Total_tests);

######################### We start with some black magic to print on failure.

my $loaded;
my $test_num = 1;
BEGIN { $| = 1; $^W = 1; }
END {print "not ok $test_num\n" unless $loaded;}
print "1..$Total_tests\n";
use URI::Find::UTF8;
use URI::Find::Schemeless ();
use URI::URL;
$loaded = 1;
BEGIN { $Total_tests++ }
ok(1, 'compile');

######################### End of black magic.

my $No_joined = @ARGV && $ARGV[0] eq '--no-joined' ? shift : 0;

sub ok {
    my($test, $name) = @_;
    print "not " unless $test;
    print "ok $test_num";
    print " - $name" if defined $name && !$test;
    print "\n";
    $test_num++;
}

sub eqarray  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;
    my $ok = 1;
    for (0..$#{$a1}) {
        unless($a1->[$_] eq $a2->[$_]) {
        $ok = 0;
        last;
        }
    }
    return $ok;
}

# %Run contains one entry for each type of finder.  Keys are mnemonics,
# required to be a single letter.  The values are hashes, keys are names
# (used only for output) and values are the subs which actually run the
# tests.  Each is invoked with a reference to the text to scan and a
# code reference, and runs the finder on that text with that callback,
# returning the number of matches.

my %Run;
BEGIN {
    %Run = (
	    # plain
	    P => {
#		  old_interface	=> sub { run_function(\&find_uris, @_) },
		  regular	=> sub { run_object('URI::Find::UTF8', @_) },
		 },
	    # schemeless
	    S => {
		  schemeless	=>
		      sub { run_object('URI::Find::Schemeless', @_) },
		 },
       );

    die if grep { length != 1 } keys %Run;
}

# A spec is a reference to a 2-element list.  The first is a string
# which contains the %Run keys which will find the URL, the second is
# the URL itself.  Eg:
#
#    [PS => 'http://www.foo.com/']	# found by both P and S
#    [S  => 'http://asdf.foo.com/']	# only found by S
#
# %Tests maps from input text to a list of specs which describe the URLs
# which will be found.  If the value is a reference to an empty list, no
# URLs will be found in the key.
#
# As a special case, a %Tests value can be initialized as a string.
# This will be replaced with a spec which indicates that all finders
# will locate that as the only URL in the key.

my %Tests;
BEGIN {
    my $all = join '', keys %Run;

    # ARGH!  URI::URL is inconsistant in how it normalizes URLs!
    # HTTP URLs get a trailing slash, FTP and gopher do not.
    %Tests = (
          '<URL:http://www.perl.com>' => 'http://www.perl.com',
          '<ftp://ftp.site.org>'      => 'ftp://ftp.site.org',
          '<ftp.site.org>'            => [[ S => 'ftp://ftp.site.org' ]],
          'Make sure "http://www.foo.com" is caught' =>
                'http://www.foo.com',
          'http://www.foo.com'  => 'http://www.foo.com',
          'www.foo.com'         => [[ S => 'http://www.foo.com' ]],
          'ftp.foo.com'         => [[ S => 'ftp://ftp.foo.com' ]],
          'gopher://moo.foo.com'        => 'gopher://moo.foo.com',
          'I saw this site, http://www.foo.com, and its really neat!'
              => 'http://www.foo.com',
          'Foo Industries (at http://www.foo.com)'
              => 'http://www.foo.com',
          'Oh, dear.  Another message from Dejanews.  http://www.deja.com/%5BST_rn=ps%5D/qs.xp?ST=PS&svcclass=dnyr&QRY=lwall&defaultOp=AND&DBS=1&OP=dnquery.xp&LNG=ALL&subjects=&groups=&authors=&fromdate=&todate=&showsort=score&maxhits=25  How fun.'
              => 'http://www.deja.com/%5BST_rn=ps%5D/qs.xp?ST=PS&svcclass=dnyr&QRY=lwall&defaultOp=AND&DBS=1&OP=dnquery.xp&LNG=ALL&subjects=&groups=&authors=&fromdate=&todate=&showsort=score&maxhits=25',
          'Hmmm, Storyserver from news.com.  http://news.cnet.com/news/0-1004-200-1537811.html?tag=st.ne.1002.thed.1004-200-1537811  How nice.'
             => [[S => 'http://news.com'],
	     	 [$all => 'http://news.cnet.com/news/0-1004-200-1537811.html?tag=st.ne.1002.thed.1004-200-1537811']],
          '$html = get("http://www.perl.com/");' => 'http://www.perl.com/',
          q|my $url = url('http://www.perl.com/cgi-bin/cpan_mod');|
              => 'http://www.perl.com/cgi-bin/cpan_mod',
          'http://www.perl.org/support/online_support.html#mail'
              => 'http://www.perl.org/support/online_support.html#mail',
    	  'irc.lightning.net irc.mcs.net'
	      => [[S => 'http://irc.lightning.net'],
		  [S => 'http://irc.mcs.net']],
    	  'foo.bar.xx/~baz/ abcd.efgh.mil, none.such/asdf/ hi.there.org'
	      => [
		  [S => 'http://abcd.efgh.mil'],
		  [S => 'http://hi.there.org']],
	  'foo:<1.2.3.4>'
	      => [[S => 'http://1.2.3.4']],
	  'mail.eserv.com.au?  failed before ? designated end'
	      => [[S => 'http://mail.eserv.com.au']],
	  'foo.info/himom ftp.bar.biz'
	      => [[S => 'http://foo.info/himom'],
		  [S => 'ftp://ftp.bar.biz']],
	  '(http://round.com)'   => 'http://round.com',
	  '[http://square.com]'  => 'http://square.com',
	  '{http://brace.com}'   => 'http://brace.com',
	  '<http://angle.com>'   => 'http://angle.com',
	  '(round.com)'          => [[S => 'http://round.com'  ]],
	  '[square.com]'         => [[S => 'http://square.com' ]],
	  '{brace.com}'          => [[S => 'http://brace.com'  ]],
	  '<angle.com>'          => [[S => 'http://angle.com'  ]],
	  '<x>intag.com</x>'     => [[S => 'http://intag.com'  ]],
	  '[mailto:somebody@company.ext]' => 'mailto:somebody@company.ext',
	  'HTtp://MIXED-Case.Com' => 'HTtp://MIXED-Case.Com',

	  # False tests
	  'HTTP::Request::Common'			=> [],
	  'comp.infosystems.www.authoring.cgi'		=> [],
	  'MIME/Lite.pm'				=> [],
	  'foo@bar.baz.com'				=> [],
	  'Foo.pm'					=> [],
	  'Foo.pl'					=> [],
	  'hi Foo.pm Foo.pl mom'			=> [],
    	  'x comp.ai.nat-lang libdb.so.3 x'		=> [],
    	  'x comp.ai.nat-lang libdb.so.3 x'		=> [],
	  'www.marselisl www.info@skive-hallerne.dk'	=> [],
# XXX broken
#	  q{$url = 'http://'.rand(1000000).'@anonymizer.com/'.$url;}
#							=> [],
    );

    # Convert plain string values to a list of 1 spec which indicates
    # that all finders will find that as the only URL.
    for (@Tests{keys %Tests}) {
	$_ = [[$all, $_]] if !ref;
    }

    # Run everything together as one big test.
    $Tests{join "\n", keys %Tests} = [map { @$_ } values %Tests]
	unless $No_joined;

    # Each test yields 3 tests for each finder (return value matches
    # number returned, matches equal expected matches, text was not
    # modified).
    my $finders = 0;
    $finders += keys %{ $Run{$_} } for keys %Run;
    $Total_tests += 3 * $finders * keys %Tests;
}

# Given a run type and a list of specs, return the URLs which that type
# should find.

sub specs_to_urls {
    my ($this_type, @spec) = @_;
    my @out;

    for (@spec) {
	my ($found_by_types, $url) = @$_;
	push @out, $url if index($found_by_types, $this_type) >= 0;
    }

    return @out;
}

sub run_function {
    my ($rfunc, $rtext, $callback) = @_;

    return $rfunc->($rtext, $callback);
}

sub run_object {
    my ($class, $rtext, $callback) = @_;

    my $finder = $class->new($callback);
    return $finder->find($rtext);
}

sub run {
    my ($orig_text, @spec) = @_;

    print "# testing [$orig_text]\n";
    for my $run_type (keys %Run) {
	print "# run type $run_type\n";
	while( my($run_name, $run_sub) = each %{ $Run{$run_type} } ) {
	    print "# running $run_name\n";
	    my @want = specs_to_urls $run_type, @spec;
	    my $text = $orig_text;
	    my @out;
	    my $n = $run_sub->(\$text, sub { push @out, $_[0]; $_[1] });
	    ok $n == @out,
		"invalid return value, returned $n but got " . scalar @out;
	    ok eqarray(\@want, \@out),
		"output mismatch, want:\n" . join("\n", @want)
    	    	    . "\ngot:\n" . join("\n", @out);
	    ok $text eq $orig_text,
		"text was modified, [$orig_text] => [$text]";
	}
    }
}

while( my($text, $rspec_list) = each %Tests ) {
    run $text, @$rspec_list;
}

# We used to turn URI::URL strict on and leave it on.

BEGIN { $Total_tests += 2 }
for my $val (0, 1) {
    URI::URL::strict($val);
    my $f = URI::Find::UTF8->new(sub { });
    my $t = "foo";
    $f->find(\$t);
    ok $val == URI::URL::strict, "URI::URL::strict $val";
}
