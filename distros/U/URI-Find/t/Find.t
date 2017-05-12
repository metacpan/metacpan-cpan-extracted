#!/usr/bin/perl -w

use strict;

use open ':std', ':encoding(utf8)';
use Test::More 'no_plan';

use_ok 'URI::Find';
use_ok 'URI::Find::Schemeless';

my $No_joined = @ARGV && $ARGV[0] eq '--no-joined' ? shift : 0;


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
                  old_interface => sub { run_function(\&find_uris, @_) },
                  regular       => sub { run_object('URI::Find', @_) },
                 },
            # schemeless
            S => {
                  schemeless    =>
                      sub { run_object('URI::Find::Schemeless', @_) },
                 },
       );

    die if grep { length != 1 } keys %Run;
}

# A spec is a reference to a 2-element list.  The first is a string
# which contains the %Run keys which will find the URL, the second is
# the URL itself.  Eg:
#
#    [PS => 'http://www.foo.com/']      # found by both P and S
#    [S  => 'http://asdf.foo.com/']     # only found by S
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
    
    use utf8;
    %Tests = (
          'Something something something.travel and stuff'
              => [[ S => 'http://something.travel' ]],
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
          'foo.bar.xx/~baz/' => [],
          'foo.bar.xx/~baz/ abcd.efgh.mil, none.such/asdf/ hi.there.org'
              => [[S => 'http://abcd.efgh.mil'],
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
          "The technology of magnetic energy has become so powerful an entire ".
          "house can...http://bit.ly/8yEdeb"
            => "http://bit.ly/8yEdeb",
          'http://www.foo.com/bar((baz)blah)' => 'http://www.foo.com/bar((baz)blah)',
          'https://[2607:5300:60:1509::228d:413a]'      => 'https://[2607:5300:60:1509::228d:413a]',
          '[https://[2607:5300:60:1509::228d:413a]]'    => 'https://[2607:5300:60:1509::228d:413a]',

          # Tests for file:
          "origin	file:///Users/schwern/devel/URI-Find/ (fetch)"
            => 'file:///Users/schwern/devel/URI-Find/',
          "This is how you express the root path file:/// as a URL"
            => 'file:///',

          # Tests for git:
          'GwenDragon	git://github.com/GwenDragon/uri-find.git (fetch)'
            => 'git://github.com/GwenDragon/uri-find.git',

          # Tests for svn+ssh:
          "URLs like svn+ssh://example.net aren't found"
            => 'svn+ssh://example.net',

          # Tests for IDNA domains
          'http://müller.de' => 'http://xn--mller-kva.de',
          'http://موقع.وزارة-الاتصالات.مصر' => 'http://xn--4gbrim.xn----ymcbaaajlc6dj7bxne2c.xn--wgbh1c',
          'http://правительство.рф' => 'http://xn--80aealotwbjpid2k.xn--p1ai',
          'http://北京大学.中國' => 'http://xn--1lq90ic7fzpc.xn--fiqz9s', 
          'http://北京大学.cn' => 'http://xn--1lq90ic7fzpc.cn',

          # Test new TLDs
          'http://my.test.transport' => 'http://my.test.transport',
          'http://regierung.bayern' => 'http://regierung.bayern',
          'http://kaiser-senf.gmbh/shop/' => 'http://kaiser-senf.gmbh/shop/',
          'Have vacation in lovely Bavaria and visit tourist.in.bayern to go to King Ludwig New Schwanstein. For political information see website regierung.bayern to get more.' 
            => [[S => 'http://tourist.in.bayern' ], [S => 'http://regierung.bayern' ]],
          'The mießlich-österlich-mück.ag was established in 2032 by M. Ostrich.' => [[S => 'http://xn--mielich-sterlich-mck-dwb52cye.ag' ]],

          # False tests
          'HTTP::Request::Common'                       => [],
          'comp.infosystems.www.authoring.cgi'          => [],
          'MIME/Lite.pm'                                => [],
          'foo@bar.baz.com'                             => [],
          'Foo.pm'                                      => [],
          'Foo.pl'                                      => [],
          'hi Foo.pm Foo.pl mom'                        => [],
          'x comp.ai.nat-lang libdb.so.3 x'             => [],
          'x comp.ai.nat-lang libdb.so.3 x'             => [],
          'www.marselisl www.info@skive-hallerne.dk'    => [],
          'bogusscheme://foo.com/'                      => [],
          'http:'                                       => [],
          'http://'                                     => [],
# XXX broken
#         q{$url = 'http://'.rand(1000000).'@anonymizer.com/'.$url;}
#                                                       => [],
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

    note "# testing [$orig_text]\n";
    for my $run_type (keys %Run) {
        note "# run type $run_type\n";
        while( my($run_name, $run_sub) = each %{ $Run{$run_type} } ) {
            note "# running $run_name\n";
            my @want = specs_to_urls $run_type, @spec;
            my $text = $orig_text;
            my @out;
            my $n = $run_sub->(\$text, sub { push @out, $_[0]; $_[1] });
            is $n, @out, "return value length";
            is_deeply \@out, \@want, "output" or diag("Original text: $text");
            is $text, $orig_text, "text unmodified";
        }
    }
}

while( my($text, $rspec_list) = each %Tests ) {
    run $text, @$rspec_list;
}
