#!/usr/bin/perl -w
use strict;

use FindBin;
use File::Temp qw( tempfile );
our ($_STDOUT_, $_STDERR_ );
use URI::URL;
#use LWP::Simple;
use Test::HTTP::LocalServer;
use Test::More;
use lib './inc';
use IO::Catch;

# Catch output:
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;
#tie *STDERR, 'IO::Catch', '_STDERR_' or die $!;

# Make HTML::Display do nothing:
BEGIN {
  $ENV{PERL_HTML_DISPLAY_CLASS} = 'HTML::Display::Dump';
  delete $ENV{PAGER};
};
use HTML::Display;

our %tests = (
    autofill => { requests => 2, lines => [ 'get %s',
                                            'autofill query Fixed foo',
                                            'autofill cat Keep',
                                            'autofill botcheck_query Fixed checked',
                                            'autofill query2 Fixed bar',
                                            'fillout',
                                            'submit' ], location => qr'^%s/formsubmit$',
                                            values => { query2 => 'bar', query => 'foo' }
                },
    auth => { requests => 1, lines => [ 'auth user password', 'get %s' ], location => qr'^%s/$' },
    back => { requests => 2, lines => [ 'get %s','open 0','back' ], location => qr'^%s/$' },
    content_save => { requests => 1, lines => [ 'get %s','content tmp.content','eval unlink "tmp.content"'], location => qr'^%s/$' },
    comment => { requests => 1, lines => [ '# a comment','get %s','# another comment' ], location => qr'^%s/$' },
    eval => { requests => 1, lines => [ 'eval "Hello World"', 'get %s','eval "Goodbye World"' ], location => qr'^%s/$' },
    eval_shell => { requests => 1, lines => [ 'get %s', 'eval $self->agent->ct' ], location => qr'^%s/$' },
    eval_sub => { requests => 2, lines => [
                        '# Fill in the "date" field with the current date/time as string',
                    'eval sub ::custom_today { "20030511" };',
                    'autofill session Callback ::custom_today',
                    'autofill query Keep',
                    'autofill botcheck_query Fixed checked',
                    'autofill query2 Fixed bar',
                    'autofill cat Keep',
                    'get %s',
                    'fillout',
                    'eval $self->agent->current_form->value("session")',
                    'submit',
                    'content',
    ], location => qr'^%s/formsubmit$',
       values => { query2 => 'bar', query => qr!\(empty\)!, session => '20030511' }
    },
    eval_multiline => { requests => 2,
                        lines => [ 'get %s',
                                                 'autofill query Keep',
                                                         'autofill cat Keep',
                                                         'autofill botcheck_query Fixed checked',
                                                         'autofill query2 Fixed bar',
                                             'fillout',
                                             'submit',
                                             'eval "Hello World ",
                                                    "from ",$self->agent->uri',
                                             'content' ],
                        location => qr'^%s/formsubmit$',
       values => { query2 => 'bar', query => qr!\(empty\)! },
                        },
    form_name => { requests => 2, lines => [ 'get %s','form f','submit' ],
              location => qr'^%s/formsubmit$',
       values => { query2 => qr!\(empty\)!, query => qr!\(empty\)! },
            },
    form_num => { requests => 2, lines => [ 'get %s','form 1','submit' ],
              location => qr'^%s/formsubmit$',
       values => { query2 => qr!\(empty\)!, query => qr!\(empty\)! },
            },
    formfiller_chars => { requests => 2,
                                        lines => [ 'eval srand 0',
                                                       'autofill botcheck_query Fixed checked',
                                                       'autofill query2 Fixed bar',
                                                       'autofill cat Keep',
                                                             'autofill query Random::Chars size 5 set alpha', 'get %s', 'fillout','submit','content' ],
        values => { query2 => 'bar', query => qr!\w{5}! },
                                       location => qr'^%s/formsubmit$' },
    formfiller_date => { requests => 2,
                                        lines => [ 'eval srand 0',
                                                       'autofill botcheck_query Fixed checked',
                                                       'autofill query2 Fixed bar',
                                                       'autofill cat Keep',
                                                             'autofill query Random::Date string %%Y%%m%%d', 'get %s', 'fillout','submit','content' ],
       values => { query2 => 'bar', query => qr!\d{8}! },
                                        location => qr'^%s/formsubmit$' },
    formfiller_default => { requests => 2,
                                        lines => [ 'autofill query Default foo',
                                                       'autofill cat Keep',
                                                       'autofill botcheck_query Fixed checked',
                                                       'autofill query2 Fixed bar',
                                                             'get %s', 'fillout','submit','content' ],
       values => { query2 => 'bar', query => qr!\(empty\)! },
                                        location => qr'^%s/formsubmit$' },
    formfiller_fixed => { requests => 2,
                                        lines => [ 'autofill query Fixed foo',
                                                       'autofill cat Keep',
                                                             'autofill botcheck_query Fixed checked',
                                                             'autofill query2 Fixed bar',
                                                             'get %s', 'fillout','submit','content' ],
       values => { query2 => 'bar', query => 'foo' },
                                        location => qr'^%s/formsubmit$' },
    formfiller_keep => { requests => 2,
                                        lines => [ 'autofill query Keep',
                                                       'autofill cat Keep',
                                                             'autofill botcheck_query Fixed checked',
                                                             'autofill query2 Fixed bar',
                                                             'get %s', 'fillout','submit','content' ],
       values => { query2 => 'bar', query => qr!\(empty\)! },
                                        location => qr'^%s/formsubmit$' },
    formfiller_random => { requests => 2,
                                        lines => [ 'autofill query Random foo',
                                                       'autofill cat Keep',
                                                             'autofill botcheck_query Fixed checked',
                                                             'autofill query2 Fixed bar',
                                                             'get %s', 'fillout','submit','content' ],
                                        location => qr'^%s/formsubmit$' },
    formfiller_re => { requests => 2,
                                        lines => [ 'eval srand 0',
                                                       'autofill cat Keep',
                                                             'autofill botcheck_query Fixed checked',
                                                             'autofill /qu/ Random::Date string %%Y%%m%%d', 'get %s', 'fillout','submit','content' ],
       values => { query2 => qr/^\d{8}$/, query => qr/^\d{8}$/ },
                                        location => qr'^%s/formsubmit$' },
    formfiller_word => { requests => 2,
                                        lines => [ 'eval srand 0',
                                                       'autofill cat Keep',
                                                             'autofill botcheck_query Fixed checked',
                                                             'autofill query2 Fixed bar',
                                                             'autofill query Random::Word size 1', 'get %s', 'fillout','submit','content' ],
                                        location => qr'^%s/formsubmit$' },
    get => { requests => 1, lines => [ 'get %s' ], location => qr'^%s/' },
    get_content => { requests => 1, lines => [ 'get %s', 'content' ], location => qr'^%s/' },
    get_redirect => { requests => 2, lines => [ 'get %sredirect/startpage' ], location => qr'^%s/startpage' },
    get_save => { requests => 4, lines => [ 'get %s','save "/\.save_log_server_test\.tmp$/"' ], location => qr'^%s/' },
    get_value_click => { requests => 2, lines => [ 'get %s','value query foo', 'click submit' ], location => qr'^%s/formsubmit$' },
    get_value_submit => { requests => 2, lines => [ 'get %s','value query foo', 'submit' ], location => qr'^%s/formsubmit$' },
    get_value2_submit => { requests => 2, lines => [
                    'get %s',
                    'value query foo',
                    'value session 2',
                    'submit'
    ], location => qr'^%s/formsubmit$',
       values => { session => '2', query => 'foo' },
    },
    interactive_script_creation => { requests => 2,
                                        lines => [ 'eval @::list=qw(foo bar xxx)',
                                                             'eval no warnings qw"redefine once"; *WWW::Mechanize::FormFiller::Value::Ask::ask_value = sub { my $value=shift @::list; push @{$_[0]->{shell}->{answers}}, [ $_[1]->name, $value ]; $value }',
                                                       'autofill cat Keep',
                                                             'autofill botcheck_query Fixed checked',
                                                             'autofill query2 Fixed bar',
                                                             'get %s',
                                                             'fillout',
                                                             'submit',
                                                             'content' ],
                                        location => qr'^%s/formsubmit$' },
    open_parm => { requests => 2, lines => [ 'get %s','open 1','content' ], location => qr'^%s/test$' },
    open_re => { requests => 2, lines => [ 'get %s','open "Link foo1.save_log_server_test.tmp"','content' ], location => qr'^%s/foo1.save_log_server_test.tmp$' },
    open_re2 => { requests => 2, lines => [ 'get %s','open "/foo1/"','content' ], location => qr'^%s/foo1.save_log_server_test.tmp$' },
    open_re3 => { requests => 2, lines => [ 'get %s','open "/Link /foo/"','content' ], location => qr'^%s/foo$' },
    open_re4 => { requests => 2, lines => [ 'get %s','open "/Link \/foo/"','content' ], location => qr'^%s/foo$' },
    open_re5 => { requests => 2, lines => [ 'get %s','open "/Link /$/"','content' ], location => qr'^%s/slash_end$' },
    open_re6 => { requests => 2, lines => [ 'get %s','open "/^/Link$/"','content' ], location => qr'^%s/slash_front$' },
    open_re7 => { requests => 2, lines => [ 'get %s','open "/^/Link in slashes//"','content' ], location => qr'^%s/slash_both$' },
    reload => { requests => 2, lines => [ 'get %s','reload','content' ], location => qr'^%s/$' },
    reload_2 => { requests => 3, lines => [ 'get %s','open "/Link \/foo/"','reload','content' ], location => qr'^%s/foo$' },
    tick => { requests => 2,
              lines => [ 'get %s','tick cat cat_foo','submit','content' ],
              location => qr'^%s/formsubmit$' },
    tick_all => { requests => 2,
              lines => [ 'get %s','tick cat','submit','content' ],
              location => qr'^%s/formsubmit$' },
    timeout => { requests => 1, lines => [ 'timeout 60', 'get %s', 'content' ], location => qr'^%s/' },
    ua_get => { requests => 1, lines => [ 'ua foo/1.1', 'get %s' ], location => qr'^%s/$' },
    ua_get_content => { requests => 1, lines => [ 'ua foo/1.1', 'get %s', 'content' ], location => qr'^%s/$' },
    untick => { requests => 2,
              lines => [ 'get %s','untick cat cat_foo','submit','content' ],
              location => qr'^%s/formsubmit$' },
    untick_all => { requests => 2,
              lines => [ 'get %s','untick cat','submit','content' ],
              location => qr'^%s/formsubmit$' },
  );

BEGIN {
  eval {
    require HTML::TableExtract;
    $tests{get_table} = { requests => 1, lines => [ 'get %s','table' ], location => qr'^%s/$' };
    $tests{get_table_params} = { requests => 1, lines => [ 'get %s','table Col2 Col1' ], location => qr'^%s/$' };
  };

  # To ease zeroing in on tests
  if (@ARGV) {
      my $re = join "|", @ARGV;
      for (sort keys %tests) {
           delete $tests{$_} unless /$re/o;
        };
    };
};

plan tests => (scalar keys %tests)*10;
BEGIN {
  # Disable all ReadLine functionality
  $ENV{PERL_RL} = 0;
  #require LWP::UserAgent;
  #my $old = \&LWP::UserAgent::request;
  #print STDERR $old;
  #*LWP::UserAgent::request = sub {print STDERR "LWP::UserAgent::request\n"; goto &$old };
};
use WWW::Mechanize::Shell;

SKIP: {

# We want to be safe from non-resolving local host names
delete @ENV{qw(HTTP_PROXY http_proxy CGI_HTTP_PROXY)};

our ($actual_requests, $dumped_requests );
{
  no warnings qw'redefine once';
  my $old_request = *WWW::Mechanize::_make_request{CODE};
  *WWW::Mechanize::_make_request = sub {
    $actual_requests++;
    goto &$old_request;
  };

  *WWW::Mechanize::Shell::status = sub {};
  *WWW::Mechanize::Shell::request_dumper = sub { $dumped_requests++; return 1 };

  #*Hook::LexWrap::Cleanup::DESTROY = sub {
      #print STDERR "Disabling hook.\n";
      #$_[0]->();
  #};
};

my $server = Test::HTTP::LocalServer->spawn();
diag "Spawned local test server at " . $server->url;

for my $name (sort keys %tests) {
  $_STDOUT_ = '';
  undef $_STDERR_;
  $actual_requests = 0;
  $dumped_requests = 0;
  my @lines = @{$tests{$name}->{lines}};
  my $requests = $tests{$name}->{requests};

  my $code_port = $server->port;

  my $url = $server->url;
  $url =~ s!/$!!;
  my $result_location = sprintf $tests{$name}->{location}, quotemeta $url;
  $result_location = qr{$result_location};
  my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );
  $s->option("dumprequests",1);
  my @commands;
  eval {
      for my $line (@lines) {
        no warnings;
        $line = sprintf $line, $server->url;
        push @commands, $line;
        $s->cmd($line);
      };
  };
  is $@, '', "Commands ran without dieing"
      or do { diag for @commands };
  $s->cmd('eval $self->agent->uri');
  my $code_output = $_STDOUT_;
  diag join( "\n", $s->history )
    unless like($s->agent->uri,$result_location,"Shell moved to the specified url for $name");

  my $parameters_ok = 1;
  my $expected_values = $tests{$name}->{values};
  for my $valname (sort keys %$expected_values) {
      if( $s->agent->value( $valname ) !~ /^$expected_values->{ $valname }$/) {
          $parameters_ok = 0;
          diag sprintf "Expected '%s', got '%s'",
              $expected_values->{ $valname },
              $s->agent->value( $valname ),
              ;
      };
  };
  is $parameters_ok, 1, "All parameters matched";
  diag join( "\n", $s->history )
    unless like($s->agent->uri,$result_location,"Shell moved to the specified url for $name");

  is($_STDERR_,undef,"Shell produced no error output for $name");
  is($actual_requests,$requests,"$requests requests were made for $name");
  is($dumped_requests,$requests,"$requests requests were dumped for $name");
  my $code_requests = $server->get_log;

  # Get a clean start
  my $script_port = $server->port;

  # Modify the generated Perl script to match the new? port
  my $script = join "\n", $s->script;
  s!\b$code_port\b!$script_port!smg for ($script, $code_output);
  #print STDERR "Releasing hook";
  undef $s->{request_wrapper};
  #{
  #  local *WWW::Mechanize::Shell::request_dumper = sub { die };
  #  use HTTP::Request::Common;
  #  $s->agent->request(GET 'http://google.de/');
  #};
  $s->release_agent;
  undef $s;

  # Write the generated Perl script
  my ($fh,$tempname) = tempfile();
  print $fh $script;
  close $fh;

  my ($compile) = `"$^X" -c "$tempname" 2>&1`;
  chomp $compile;
  SKIP: {
    unless (is($compile,"$tempname syntax OK","$name compiles")) {
      $server->get_log;
      diag $script;
      skip "Script $name didn't compile", 2;
    };
    my ($output);
    my $command = qq("$^X" -Iblib/lib "$tempname" 2>&1);
    $output = `$command`;
    $output =~ s!^Cookie:.*$!Cookie: <removed>!smg; # cookies get re-ordered, sometimes
    $code_output =~ s!^Cookie:.*$!Cookie: <removed>!smg; # cookies get re-ordered, sometimes
    is( $output, $code_output, "Output of $name is identical" )
      or diag "Script:\n$script";
    my $script_requests = $server->get_log;
    $code_requests =~ s!\b$code_port\b!$script_port!smg;
    $code_requests =~ s!^Cookie:.*$!Cookie: <removed>!smg; # cookies get re-ordered, sometimes
    $script_requests =~ s!^Cookie:.*$!Cookie: <removed>!smg; # cookies get re-ordered, sometimes
    is($code_requests,$script_requests,"$name produces identical queries")
      or diag $script;
  };
  unlink $tempname
    or diag "Couldn't remove tempfile '$name' : $!";
};
# $server->stop;

unlink $_ for (<*.save_log_server_test.tmp>);

};
