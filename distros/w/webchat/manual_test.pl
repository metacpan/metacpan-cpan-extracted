#!/usr/bin/perl -w

# This is a judgement call but I have moved the
# the eval tests out of the main test suite because, 
# unless you are connected to the Net and perl.com
# is up the tests are likely to fail which might 
# cause issues. /shrug/
# 

use lib 'lib';
use strict;
use WWW::Chat::Processor;


my $script = << 'EOS';
GET http://www.perl.com
EXPECT OK
EOS

my $convert = WWW::Chat::Processor::parse ($script, '<inline>');


eval $convert;

unless ($@)
{
	print "ok 1\n";
	print "- successfully eval-ed converted code in 'main::' name space\n";
} else {
	print "not ok 1\n";
	print "- failed to eval converted code in 'main::' name space : $@\n";
}


unless (SubPack::do($convert))
{
	print "ok 2\n";
	print "- successfully eval-ed code in none 'main::' name space\n";
} else {
	print "not ok 2\n";
	print "- failed to ev code in none 'main::' name space : $@\n";
}     


undef $/;
my $oldscript = <DATA>;
eval $oldscript;
unless ($@)
{
	print "ok 3\n";
	print "- successfully eval-ed old style code\n";
} else {
	print "not ok 3\n";
	print "-failed to eval old style code\n";
}

exit 0;

package SubPack;
sub do
{
	my $script = shift;
	eval $script;
	return $@;
}

package main;

__DATA__
#!/usr/bin/perl -w
# !!! DO NOT EDIT !!!
# This program was automatically generated from '../simple.wc' by webchatpp

use strict;

use URI ();
use HTTP::Request ();
use LWP::UserAgent ();
#use LWP::Debug qw(+);

use HTML::Form ();
use WWW::Chat;

use vars qw($ua $uri $base $req $res $status $ct @forms $form @links $TRACE);

$base ||= "http://localhost";
unless ($ua) {
    $ua  = LWP::UserAgent->new;
    $ua->agent("webchat/0.01 " . $ua->agent);
    $ua->env_proxy;
}

$TRACE = $ENV{WEBCHAT_TRACE};

#line 1 "../simple.wc"
#GET "http://www.perl.com"
eval {
    local $uri = URI->new_abs("http://www.perl.com", $base);
    local $req = HTTP::Request->new(GET => $uri);
    local $res = WWW::Chat::request($req);
    #print STDERR $res->as_string;
    local $status = $res->code;
    local $base = $res->base;
    local $ct = $res->content_type || "";
    local $_ = $res->content;
    local(@forms, $form, @links);
    if ($ct eq 'text/html') {
        @forms = HTML::Form->parse($_, $res->base);
        $form = $forms[0] if @forms;
        @links = WWW::Chat::extract_links($_);
    }
#line 2 "../simple.wc"
}; WWW::Chat::check_eval($@);

