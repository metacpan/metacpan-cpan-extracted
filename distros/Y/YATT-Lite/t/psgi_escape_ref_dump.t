#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------
#
# References reaching escape() (the implicit Data::Dumper fallback):
#
#  1. Request parameters never bind a reference to a text/bool argument
#     (?q[]=... from nested query is stashed instead). scalar and list
#     arguments still accept structures (?choice[foo]=1).
#  2. When escape() does dump a reference, the dump is fully escaped
#     (also ' and >), so it is harmless even inside a quoted attribute.
#  3. Dumping happens only when $CON->has_htdebug('dump') says so
#     (HTDEBUG_DUMP / $app_root/.htdebug_dump) or under
#     PLACK_ENV=development; otherwise only the type name is printed.
#  4. $CON->has_htdebug($name) is cached per connection.
#

use Test::More;
use Test::Differences;
use File::Temp qw(tempdir);

BEGIN {
  foreach my $req (qw(Plack Plack::Test HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      plan skip_all => "$req is not installed.";
    }
    $req->import;
  }
}

use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::Util qw(escape);
use YATT::Lite::Util::File qw(mkfile_may_wait);
use YATT::Lite::WebMVC0::SiteApp ();

my $TMP = tempdir(CLEANUP => $ENV{NO_CLEANUP} ? 0 : 1);
END { chdir('/') }

my $PAGE = <<'END';
<!yatt:args q flag=bool choice=scalar items=list>
<input name="q" value='&yatt:q;'>
q=&yatt:q;
flag=&yatt:flag;
choice_foo=&yatt:choice{foo};
items0=&yatt:items[0];
stash=&yatt:CON:stash();

<!yatt:page dumpref>
<yatt:my h:value="+{a => q{it's <b>}, b => [1,2]}"/>
ref=&yatt:h;

<!yatt:page cache>
first=&yatt:CON:has_htdebug(dump);
<?perl $ENV{HTDEBUG_DUMP} = $ENV{HTDEBUG_DUMP} ? 0 : 1; ?>
second=&yatt:CON:has_htdebug(dump);
<?perl delete $ENV{HTDEBUG_DUMP}; ?>
END

my $i = 0;
my $make_site = sub {
  my (%opts) = @_;
  ++$i;
  my $approot = "$TMP/app$i";
  my $docroot = "$approot/docs";
  MY->mkfile_may_wait("$docroot/index.yatt", $PAGE);
  my $site = YATT::Lite::WebMVC0::SiteApp->new(
    app_ns => "MyYATTEscapeRef$i"
    , app_root => $approot
    , doc_root => $docroot
    , %opts
  );
  ($site, $approot);
};

sub enc {
  my ($s) = @_;
  $s =~ s{([^A-Za-z0-9_.~-])}{sprintf("%%%02X", ord $1)}ge;
  $s;
}

my $XSS = q{x' onfocus='alert(1)' autofocus='b};

#========================================
subtest "escape() of a reference (unit)", sub {
  my $ref = +{a => q{it's <b> & "q"}, b => [1, 2]};

  {
    local $ENV{HTDEBUG_DUMP} = 1;
    my $out = escape($ref);
    unlike $out, qr/['<>"]/, "dump has no raw quote, angle bracket or dquote";
    unlike $out, qr/&(?!amp;|lt;|gt;|quot;|#39;)/, "no raw ampersand";
    # (Data::Dumper writes the inner quote as \' so it shows up as \&#39;)
    like $out, qr/&#39;a&#39; =&gt; &#39;it\\&#39;s &lt;b&gt; &amp; &quot;q&quot;&#39;/
      , "contents are visible, fully escaped";
  }
  {
    local $ENV{HTDEBUG_DUMP} = 0;
    is escape($ref), '[HASH]', "HTDEBUG_DUMP=0: type name only";
    is escape([1]), '[ARRAY]';
    is escape(bless {}, 'My::Class'), '[My::Class]';
    is escape(sub {}), '[CODE]';
  }
  {
    local $ENV{PLACK_ENV} = 'development';
    delete local $ENV{HTDEBUG_DUMP};
    like escape($ref), qr/&#39;a&#39; =&gt;/, "development: dumped by default";
  }
  {
    local $ENV{PLACK_ENV} = 'deployment';
    delete local $ENV{HTDEBUG_DUMP};
    is escape($ref), '[HASH]', "deployment: type name only by default";
  }
  is escape(\ 'raw<b>'), 'raw<b>', "SCALAR ref still passes through";
};

#========================================
subtest "deployment: ?q[]= never reaches a text argument", sub {
  local $ENV{PLACK_ENV} = 'deployment';
  delete local $ENV{HTDEBUG_DUMP};
  my ($site) = $make_site->();
  my $test = Plack::Test->create($site->to_app);

  my $res = $test->request(GET "/?q[]=".enc($XSS));
  is $res->code, 200;
  like $res->content, qr/<input name="q" value=''>/, "text arg stays empty";
  unlike $res->content, qr/onfocus/, "payload is not reflected at all";
  like $res->content, qr/^stash=\[HASH\]$/m, "stash itself is not dumped in deployment";

  # scalar accepts a hash structure, list keeps working.
  $res = $test->request(GET "/?choice[foo]=1&choice[bar]=2&items=a");
  is $res->code, 200;
  like $res->content, qr/^choice_foo=1$/m, "scalar arg receives ?choice[foo]=1";
  like $res->content, qr/^items0=a$/m, "list arg receives ?items=";

  # bool is like text.
  $res = $test->request(GET "/?flag[]=1");
  is $res->code, 200;
  like $res->content, qr/^flag=$/m, "bool arg does not take a reference";
};

#========================================
subtest "development: ?q[]= is stashed, and the dump is escaped", sub {
  local $ENV{PLACK_ENV} = 'development';
  delete local $ENV{HTDEBUG_DUMP};
  my ($site) = $make_site->(stash_unknown_params_to => 'yatt.unknown_params');
  my $test = Plack::Test->create($site->to_app);

  my $res = $test->request(GET "/?q[]=".enc($XSS));
  is $res->code, 200 or diag $res->content;
  like $res->content, qr/<input name="q" value=''>/, "text arg stays empty";
  unlike $res->content, qr/onfocus='alert/, "payload never appears raw";
  like $res->content, qr/^stash=\{$/m, "stash is dumped in development";
  like $res->content, qr/&#39;q&#39; =&gt; \[/, "the ref went to the stash (escaped dump)";
  like $res->content, qr/x\\&#39; onfocus=\\&#39;alert\(1\)\\&#39;/, "quotes in the payload are escaped";
};

#========================================
subtest ".htdebug_dump file turns dumping on in deployment", sub {
  local $ENV{PLACK_ENV} = 'deployment';
  delete local $ENV{HTDEBUG_DUMP};
  my ($site, $approot) = $make_site->();
  MY->mkfile_may_wait("$approot/.htdebug_dump", "");
  my $test = Plack::Test->create($site->to_app);

  my $res = $test->request(GET "/?~~=dumpref");
  is $res->code, 200 or diag $res->content;
  like $res->content, qr/&#39;a&#39; =&gt; &#39;it\\&#39;s &lt;b&gt;&#39;/, "ref is dumped (escaped)";

  unlink "$approot/.htdebug_dump";
  $res = $test->request(GET "/?~~=dumpref");
  like $res->content, qr/^ref=\[HASH\]$/m, "without the file: type name only";
};

#========================================
subtest "\$CON->has_htdebug is cached per connection", sub {
  local $ENV{PLACK_ENV} = 'deployment';
  local $ENV{HTDEBUG_DUMP} = 1;
  my ($site) = $make_site->();
  my $test = Plack::Test->create($site->to_app);

  my $res = $test->request(GET "/?~~=cache");
  is $res->code, 200 or diag $res->content;
  like $res->content, qr/^first=1$/m, "first lookup sees HTDEBUG_DUMP=1";
  like $res->content, qr/^second=1$/m
    , "second lookup is served from the cache although %ENV changed";

  # A new request gets a fresh cache.
  $ENV{HTDEBUG_DUMP} = 0;
  $res = $test->request(GET "/?~~=cache");
  like $res->content, qr/^first=0$/m, "new connection: fresh lookup";
};

done_testing();
