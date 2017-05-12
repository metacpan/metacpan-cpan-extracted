#!/usr/bin/perl

use strict;
use Test::More tests => 110;
use URLprocessor;
#use Data::Dumper;

print "\n\n\n##########################################################################################\n";
print "### Test public interface.\n";
print "##########################################################################################\n\n";

print "\n";
print "Test API:\n";

my $url_str = 'HTTP://login:passwd@www.cpan.org:8080/local/path/file.php#some_fragment'; 
print "URL=$url_str\n";
my $url = URLprocessor->new($url_str);
# Test if url method has impact on localpath.
is($url->url, 'http://login:passwd@www.cpan.org:8080/local/path/file.php#some_fragment', 'url(): http://login:passwd@www.cpan.org:8080/local/path/file.php#some_fragment');
is($url->localpath, '/local/path/file.php', "localpath(): /local/path/file.php");
print "\n";

$url_str = 'HTTP://login:passwd@www.cpan.org:8080/local/path/file.php?param=val&param2=http://cpan.org#some_fragment'; 
print "URL=$url_str\n";
$url = URLprocessor->new($url_str);

# URL
is($url->url_global_part, 'http://login:passwd@www.cpan.org:8080', 'url_global_part(): http://login:passwd@www.cpan.org:8080');
is($url->url_local_part, '/local/path/file.php?param=val&param2=http://cpan.org#some_fragment', 'url_local_part(): /local/path/file.php?param=val&param2=http://cpan.org#some_fragment');
#is($url->url, 'http://login:passwd@www.cpan.org:8080/local/path/file.php?param=val&param2=http://cpan.org#some_fragment', 'url(): http://login:passwd@www.cpan.org:8080/local/path/file.php?param=val&param2=http://cpan.org#some_fragment');
# I have to disable this test url() method because sometimes parameters are in different order. 

# Protocol
is($url->protocol, 'http', "protocol(): http");
$url->protocol(undef);
is($url->protocol, undef, "protocol(undef) -> protocol(): undef");
is($url->valid_status, 0, "valid_status: 0 - protocol must be defined");
$url->protocol('ftp');
is($url->protocol, 'ftp', "protocol('ftp') -> protocol(): ftp");
print "\n";

# Login
is($url->login, 'login', "login(): login");
$url->login(undef);
is($url->login, undef, "login(undef) -> login(): undef");
$url->login('login2');
is($url->login, 'login2', "login('login2') -> login(): login2");
print "\n";

# Password
is($url->passwd, 'passwd', "passwd(): passwd");
$url->passwd(undef);
is($url->passwd, undef, "passwd(undef) -> passwd(): undef");
$url->passwd('passwd2');
is($url->passwd, 'passwd2', "passwd('passwd2') -> passwd(): passwd2");
print "\n";

# Host
is($url->host, 'www.cpan.org', "host(): www.cpan.org");
$url->host(undef);
is($url->host, undef, "host(undef) -> host(): undef");
is($url->valid_status, 0, "valid_status(): 0 - host must be defined");
$url->host('cpan.org');
is($url->host, 'cpan.org', "host('cpan.org') -> host(): cpan.org");
print "\n";

# Port
is($url->port, '8080', "port(): 8080");
$url->port(undef);
is($url->port, undef, "port(undef) -> port(): undef");
$url->port('abc');
is($url->port, 'abc', "port('abc') -> port(): abc");
is($url->valid_status, 0, "valid_status(): 0 - invalid port value 'abc'");
$url->port(80);
is($url->port, '80', "port('80') -> port(): 80");
$url->port('80');
is($url->port, '80', "port('80') -> port(): 80");
is($url->valid_status, 1, "valid_status(): 1 - valid port value");
print "\n";

# Local path
my @parts_of_path = ('local', 'path');
is($url->localpath, '/local/path/file.php', "localpath(): /local/path/file.php");
$url->localpath(undef);
is($url->localpath, undef, "localpath(undef) -> localpath(): undef");
$url->localpath('/local/path/');
is($url->localpath, '/local/path/', "localpath('/local/path/') -> localpath(): /local/path/");
is($url->localpath_array, @parts_of_path, "localpath_array(): ('local', 'path')");
is(($url->localpath_array)[0], 'local', "(localpath_array())[0]: 'local'");
is(($url->localpath_array)[1], 'path', "(localpath_array())[1]: 'path'");
push @parts_of_path, 'index.html';
$url->localpath(\@parts_of_path);
is($url->localpath, '/local/path/index.html', '@parts_of_path=qw(local path index.html); localpath(\@parts_of_path) -> localpath(): /local/path/index.html');
print "URL: ".$url->url,"\n";

@parts_of_path = ('local', 'simple', 'path/');
$url->localpath(\@parts_of_path);
is($url->localpath, '/local/simple/path/', '@parts_of_path=qw(local simple path/); localpath(\@parts_of_path) -> localpath(): /local/simple/path/');
print "URL: ".$url->url,"\n";

my $some_hash = { a => 1, b => 2};
$url->localpath($some_hash); # Only SCALAR, ARRAY and undef are allowed.
is($url->localpath, '/local/simple/path/', '$some_hash={a=>1,b=>2}; localpath($some_hash) -> localpath(): /local/simple/path/');
print "URL: ".$url->url,"\n";
print "\n";

# Parameters
my $params = $url->params_hash;
is($params->{'param'}, 'val', "params_hash(): param=val");
is($params->{'param2'}, 'http://cpan.org', "params_hash(): param2=http://cpan.org");
is($url->param_value(undef), undef, "param_value(undef): undef");
is($url->param_value('param'), 'val', "param_value('param'): val");
is($url->param_value('param22'), undef, "param_value('param22'): undef");
$url->param_del('param2');
is($url->param_value('param2'), undef, "param_del('param2')-> param_value('param2'): undef");
$url->param_del('param');
is($url->params_string, '', "params_string(): ''");
$url->param_add('param', 'value');
is($url->param_value('param'), 'value', "param_add('param', 'value') -> param_value('param'): value");
is($url->param_exist('notexistparam'), 0, "param_exist('notexistparam'): 0");
is($url->param_exist('param'), 1, "param_exist('param'): 1");
is($url->params_string, 'param=value', "params_string(): 'param=value'");
$url->param_add('param2', 'value2');
$url->param_add('param3', 'value3');
print "URL params with delimiter '|': ", $url->params_string('|'), "\n";
print "URL params: with default delimiter", $url->params_string, "\n";
print "\n";


# Fragment
is($url->fragment, 'some_fragment', "fragment(): some_fragment");
$url->fragment(undef);
is($url->fragment, undef, "fragment(undef) -> fragment(): undef");
$url->fragment('some_fragment2');
is($url->fragment, 'some_fragment2', "fragment('some_fragment2') -> fragment(): some_fragment2");
print "\n";


# URL validation methods
is($url->valid_status, 1, 'valid_status(): 1');
is($url->valid_msg, 'OK', 'valid_msg(): OK');
if ($url->valid_status == 1) {
	print "URL: ", $url->url, "\n";
} else {
	print "ERROR: URL is not valid\n";
}
print "\n";

$url_str ='HTTP://www.cpan.org/#some_fragment'; 
print "URL2=$url_str\n";
my $url2 = URLprocessor->new($url_str);
is($url2->login, undef, "login(): undef");
is($url2->passwd, undef, "passwd(): undef");
is($url2->port, undef, "port(): undef");
is($url2->param_exist('someparam'), 0, "param_exist('someparam'): 0");
is($url2->localpath, '/', "localpath(): ''");
is($url2->fragment, 'some_fragment', "fragment(): some_fragment");
is($url2->valid_status, 1, 'valid_status(): 1');
is($url2->valid_msg, 'OK', 'valid_msg(): OK');
print 'URL2: '.$url2->url."\n";
print "\n";




# Test private methods:
print "\nTest split method\n";
_test_split_url($url2);

print "\nTest parse global part method\n";
_test_parse_global_part($url2);

print "\nTest parse local part method\n";
_test_parse_local_part($url2);
print "\n";

print "\nTest parse params function\n";
_test_parse_params($url2);
print "\n";




########################### tests

sub _test_split_url {
	my $self = shift;
	# 1 - only global part.
	# 2 - global and local parts.
	# 0 - something is wrong.
	my $urls = {
		'http://www.cpan.org' => 1,
		'http://www.cpan.org/' => 2,
		'http://www.cpan.org/path/' => 2,
		'http://www.cpan.org/path/?p1=v1&p2=v2' => 2,
		'http://www.cpan.org/path/?p1=v1&p2=http://cpan.org' => 2,
		'http:///www.cpan.org/path/?p1=v1&p2=http://cpan.org' => 0,
		'http:///www.cpan.org' => 0,
		'http://' => 0,
		'http:///' => 0,
	};
	
	while (my($url, $v) = each %{$urls}) {
		$self->{URL} = $url;
		my ($global_p, $local_p) = $self->_split_url;
		if (!defined $global_p and !defined $local_p and $v == 0) {
			is(1, 1, "($url) is bad");
			
		} elsif (!defined $global_p and defined $local_p) {
			is('undef,def', 'def,def', "ERROR - ($url) global is undef, local is defined!");
			
		} elsif (defined $global_p and !defined $local_p and $v == 1) {
			is(1, 1, "($url) only global part is defined");
			
		} elsif (defined $global_p and defined $local_p and $v == 2) {
			is(1, 1, "($url) both parts are defined");
			
		} else {
			is('?', '???', "ERROR - ($url) is bad!");
		}
	}
}


sub _test_parse_global_part {
	my $self = shift;
	my $urls = {
		# value = number of elements.
		'http://www.cpan.org' => 2,
		'http://login:passwd@www.cpan.org' => 3,
		'http://www.cpan.org:80' => 3,
		'http://login:passwd@www.cpan.org:80' => 4,
		'http:///login:passwd@www.cpan.org:80' => 0,
		'http://login:@www.cpan.org:80' => 4,
		'http://:passwd@www.cpan.org:80' => 4,
		'http://login@www.cpan.org:80' => 4,
		'http://www.cpan.org::::80' => 5,
		'http:///www.cpan.org' => 0,
		'://login:passwd@www.cpan.org:80' => 0,
		'http:/www.cpan.org:80' => 0,
		'http://:80' => 0,
		'://:80' => 0,
	};
	
	while (my($url, $v) = each %{$urls}) {
		$self->{GLOBAL_PART} = $url;
		my ($protocol, $auth, $host, $port) = $self->_parse_global_part;
		$self->{PORT} = $port; # Required to check valid port numeric value.
		if (defined $protocol and defined $auth and defined $host and defined $port and $v == 4) {
			is(1, 1, "($url) has 4 parts");
			
		} elsif (defined $protocol and defined $host and (defined $auth or defined $port) and $v == 3) {
			is(1, 1, "($url) has 3 parts");
			
		} elsif (defined $protocol and !defined $auth and defined $host and !defined $port and $v == 2) {
			is(1, 1, "($url) has 2 parts");
			
		} elsif ((!defined $protocol or $protocol eq '') and $v == 0) {
			is(1, 1, "($url) is bad (protocol is empty)");
			
		} elsif ((!defined $host or $host eq '') and $v == 0) {
			is(1, 1, "($url) is bad (host is empty)");

		} elsif ($v == 5 and ($self->valid_status) == 0) {
			is(1, 1, "($url) is bad (".$self->valid_msg.")");
			
		} elsif ($v == 0) {
			is(1, 0, "($url) is bad:\n".Dumper($protocol, $auth, $host, $port));
			
		} else {
			is('?', '???', "ERROR - ($url) is bad:\n".Dumper($protocol, $auth, $host, $port));
		}
	}
	
}



sub _test_parse_local_part {
	my $self = shift;
	my $urls = {
		# value = number of elements.
		'path/file' => 0,
		'path/file.php?p=v' => 0,
		'path/file.php?p=v&p2=http://v2' => 0,
		'/' => 1,
		'/path/file/' => 1,
		'/path/file' => 1,
		'/path/file.php' => 1,
		'/path/file.php?p=v' => 2,
		'/path/file.php?p=v&p2=v2' => 2,
		'/path/file.php?p=v#fragment' => 3,
		'/path/file.php#fragment' => -2,
		'/#fragment' => -2,
		'/?p=v#fragment' => 3,
		'/?p=#fragment' => 3, # This is bad string, but I'm not checking params right now.
		'/?p=v&p2=http://v2.org#fragment' => 3,
	};
	
	while (my($url, $v) = each %{$urls}) {
		$self->{LOCAL_PART} = $url;
		my ($local_path, $params, $fragment) = $self->_parse_local_part;
		if (defined $local_path and defined $params and defined $fragment and $v == 3) {
			is(1, 1, "($url) has 3 parts");
			
		} elsif (defined $local_path and defined $params and !defined $fragment and $v == 2) {
			is(1, 1, "($url) has 2 parts");
			
		} elsif (defined $local_path and !defined $params and !defined $fragment and $v == 1) {
			is(1, 1, "($url) has 1 parts");
			
		} elsif (!defined $local_path and !defined $params and !defined $fragment and $v == 0) {
			is(1, 1, "($url) has 0 parts");
			
		} elsif (defined $local_path and !defined $params and defined $fragment and $v == -2) {
			is(1, 1, "($url) has 2* parts");
			
		} else {
			is('?', '???', "ERROR - ($url) is bad");
		}
	}
	
}



sub _test_parse_params {
	my $self = shift;
	my $urls = {
		'&' => 0,
		'p=' => 0,
		'p=&' => 0,
		'p=v&' => 1, # This is exception
		'p=v&v' => 0,
		'p=v&v=' => 0,
		'&p=v' => 0,
		'&p=' => 0,
		'&p' => 0,
		'p&v' => 0,
		
		'' => 1,
		'p=v' => 1,
		'p=v&p2=v2' => 1,
		'p=v&p2=v2&p3=v3' => 1,
	};
	
	while (my($url, $v) = each %{$urls}) {
		my ($valid_status, $params) = URLprocessor::_parse_params($url, '&');
		if (defined $valid_status and $valid_status == 1 and $v == 1) {
			is(1, 1, "params are ok: $url");

		} elsif (defined $valid_status and $valid_status == 0 and $v == 0) {
			is(1, 1, "params are bad: $url");
		
		} elsif (!defined $valid_status) {
			is('undef', 'def', "ERROR - valid status is undef: $url");
				
		} else {
			is($valid_status, $v, "ERROR - params are bad: $url (status=$valid_status, val=$v)");
		}
	}
}


