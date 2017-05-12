# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use vars qw($loaded);

BEGIN { $| = 1; print "1..187\n"; }
END   { print "not ok 1\n" unless $loaded; }

my $ok_count = 1;
sub ok {
  my $ok = shift;
  $ok or print "not ";
  print "ok $ok_count\n";
  ++$ok_count;
  $ok;
}

use URI;
use WebFS::FileCopy;
use Data::Dumper;
use Cwd;
use LWP::StdSched;

if (0) {
  $LWP::UA::DEBUG = 10;
  $LWP::EventLoop::DEBUG = 10;
  $LWP::Server::DEBUG = 10;
  $LWP::Conn::FTP::DEBUG = 10;
  $LWP::Conn::HTTP::DEBUG = 10;
  $LWP::Conn::_Connect::DEBUG = 10;
  $LWP::StdSched::DEBUG = 10;
}

# If we got here, then the package being tested was loaded.
$loaded = 1;
ok(1);									#  1

# Cd to the test directory.
chdir 't' if -d 't';

# Check the _is_directory subroutine.
ok(  WebFS::FileCopy::_is_directory('http://www.gps.caltech.edu') );	#  2
ok( !WebFS::FileCopy::_is_directory('http://www/fff') );		#  3
ok(  WebFS::FileCopy::_is_directory('http://www.gps.caltech.edu/~blair/') );# 4
ok( !WebFS::FileCopy::_is_directory(URI::file->new_abs('file1')) );	#  5

# Check illegal argument passing to copy_urls.

# Cannot copy more than one file to a single destination file.
ok( !defined copy_urls(['file:/a', 'file:/b'], 'file:/c') );		#  6
ok( $@ eq 'Cannot copy many files to one file' );			#  7

# Cannot copy a directory.
ok( !defined copy_urls('file:/tmp/', 'file:/tmp/') );			#  8
ok( $@ eq 'Cannot copy directories: file:/tmp/' );			#  9

# Cannot copy to non ftp: or file:
ok( !copy_url('http://www.gps.caltech.edu/', 'http://ftp/') );		# 10
ok( $@ eq 'Can only copy to file or FTP URLs: http://ftp/' );		# 11

# Put together file URIs for the test files.  Files 1, 2, and 3, 5 exists and
# file 4 doesn't.
my $cwd = cwd;
my @from_files = qw(file1 file2 file3 file4 file5);
my @from_uris  = map { URI::file->new_abs($_) } @from_files;
my @to_uris    = map { WebFS::FileCopy::_create_uri("$_.new") } @from_uris;

# Clean up any output files from previous testing runs.
unlink(map { $_->file } @to_uris);

# Test the get_urls.
my @a = get_urls(@from_uris);

ok( @a == @from_uris );							# 12
ok( $a[0] );								# 13
ok( $a[1] );								# 14
ok( $a[2] );								# 15
ok( $a[3] );								# 16
ok( $a[4] );								# 17

ok(  $a[0]->is_success and length($a[0]->content) ==  90 );		# 18
ok(  $a[1]->is_success and length($a[1]->content) == 501 );		# 19
ok(  $a[2]->is_success and length($a[2]->content) == 365 );		# 20
ok( !$a[3]->is_success );						# 21
ok(  $a[4]->is_success and length($a[4]->content) == 11683 );		# 22

# Try to put the files.
my $content = $a[4]->content;
my @b = put_urls($content, @to_uris, 'file:/this/path/should/not/exist');
ok(  @b == @from_files+1 );						# 23
ok(  $b[0] );								# 24
ok(  $b[1] );								# 25
ok(  $b[2] );								# 26
ok(  $b[3] );								# 27
ok(  $b[4] );								# 28
ok(  $b[5] );								# 29
ok(  $b[0]->is_success );						# 30
ok(  $b[1]->is_success );						# 31
ok(  $b[2]->is_success );						# 32
ok(  $b[3]->is_success );						# 33
ok(  $b[4]->is_success );						# 34
ok( !$b[5]->is_success );						# 35
ok(  $b[5]->message eq "No such file or directory" );			# 36

# Try to get the same files we just put.
my @c = get_urls(@to_uris);
ok( @c == @from_files );						# 37
ok( $a[4] );								# 38
ok( $a[4]->content eq $c[0]->content );					# 39
ok( $a[4]->content eq $c[1]->content );					# 40
ok( $a[4]->content eq $c[2]->content );					# 41
ok( $a[4]->content eq $c[3]->content );					# 42
ok( $a[4]->content eq $c[4]->content );					# 43

# Test the subroutine form of put_urls.
my $i = 0;
my $put_string = $a[2]->content;
sub put_test {
  return undef if $i == length($put_string);
  substr($put_string, $i++, 1);
}

@b = put_urls(\&put_test, 'file:/this/path/should/not/exist', @to_uris);
ok( @b == @from_files+1 );						# 44
ok(  $b[0] );								# 45
ok(  $b[1] );								# 46
ok(  $b[2] );								# 47
ok(  $b[3] );								# 48
ok(  $b[4] );								# 49
ok(  $b[5] );								# 50
ok( !$b[0]->is_success );						# 51
ok(  $b[0]->message eq "No such file or directory" );			# 52
ok(  $b[1]->is_success );						# 53
ok(  $b[2]->is_success );						# 54
ok(  $b[3]->is_success );						# 55
ok(  $b[4]->is_success );						# 56
ok(  $b[5]->is_success );						# 57

# Try to get the same files we just put.
@b = get_urls(@to_uris);
ok( @b == @from_files );						# 58
ok( $a[2] );								# 59
ok( $b[0] );								# 60
ok( $b[1] );								# 61
ok( $b[2] );								# 62
ok( $b[3] );								# 63
ok( $b[4] );								# 64
ok( $a[2]->content eq $b[0]->content );					# 65
ok( $a[2]->content eq $b[1]->content );					# 66
ok( $a[2]->content eq $b[2]->content );					# 67
ok( $a[2]->content eq $b[3]->content );					# 68
ok( $a[2]->content eq $b[4]->content );					# 69

# Try to get many different failures from put_urls.
@b = put_urls('text',
	'http://www.perl.com/test.html',
	'file://some.other.host/test',
	'ftp://ftp.gps.caltech.edu/test',
        '');
ok(  $b[0] );								# 70
ok(  $b[1] );								# 71
ok(  $b[2] );								# 72
ok(  $b[3] );								# 73
ok( !$b[0]->is_success );						# 74
ok(  $b[0]->message eq 'Invalid scheme http' );				# 75
ok( !$b[1]->is_success );						# 76
ok(  $b[1]->message eq "Only file://localhost/ allowed" );		# 77
ok( !$b[2]->is_success );						# 78
ok(  $b[2]->message eq "FTP return code 553" );				# 79
ok( !$b[3]->is_success );						# 80
ok(  $b[3]->message eq "Missing URL in request" );			# 81

# Try to delete some nonexistent files.
@b = delete_urls(
	'http://www.perl.com/test.html',
	'file://some.other.host/test',
	'ftp://ftp.gps.caltech.edu/test',
        '');
ok( $b[0] );								# 82
ok( $b[1] );								# 83
ok( $b[2] );								# 84
ok( !$b[0]->is_success );						# 85
ok(  $b[0]->message eq "Method Not Allowed" );				# 86
ok( !$b[1]->is_success );						# 87
ok(  $b[1]->message eq "Use ftp instead" );				# 88
ok( !$b[2]->is_success );						# 89
ok(  $b[2]->message eq "/test: Permission denied on server. (Delete)" );# 90
ok( !$b[3]->is_success );						# 91
ok(  $b[3]->message eq "Missing URL in request" );			# 92

# Try to delete the files we created.
@b = delete_urls(@to_uris);
ok( @b == @to_uris );							# 93
ok( $b[0] );								# 94
ok( $b[1] );								# 95
ok( $b[2] );								# 96
ok( $b[3] );								# 97
ok( $b[4] );								# 98
ok( $b[0]->is_success );						# 99
ok( $b[1]->is_success );						# 100
ok( $b[2]->is_success );						# 101
ok( $b[3]->is_success );						# 102
ok( $b[4]->is_success );						# 103

# Try to delete the files again.  This time it should fail.
@b = delete_urls(@to_uris);
ok(  @b == @to_uris );							# 104
ok(  $b[0] );								# 105
ok(  $b[1] );								# 106
ok(  $b[2] );								# 107
ok(  $b[3] );								# 108
ok(  $b[4] );								# 109
ok( !$b[0]->is_success );						# 110
ok( !$b[1]->is_success );						# 111
ok( !$b[2]->is_success );						# 112
ok( !$b[3]->is_success );						# 113
ok( !$b[4]->is_success );						# 114

# Create one file and try to move it.
ok( copy_url($from_uris[4], $to_uris[4]) );				# 115
ok( move_url($to_uris[4], $to_uris[0]) );				# 116

# Now try failures of move_url.
ok( !move_url($to_uris[4], $to_uris[0]) );				# 117
ok( $@ =~ m?/t/file5.new: No such file or directory? );			# 118
ok( !move_url($to_uris[0], 'file://some.other.host/test') );		# 119
ok( $@ eq 'PUT file://some.other.host/test: Only file://localhost/ allowed' ); # 120

# Make sure that if empty URIs are passed, we get the proper return message.
ok( !copy_url(' ', ' ') );						# 121
ok( $@ eq 'Missing GET URL' );						# 122
ok( !copy_url('http://www.perl.com/', ' ') );				# 123
ok( $@ eq 'Missing PUT URL' );						# 124

ok( !copy_urls([], []) );						# 125
ok( $@ eq 'No non-empty GET URLs' );					# 126
ok( !copy_urls('http://www.perl.com/', []) );				# 127
ok( $@ eq 'No non-empty PUT URLs' );					# 128

@b = delete_urls(' ');
ok(  $b[0] );								# 129
ok( !$b[0]->is_success );						# 130
ok(  $b[0]->message eq 'Missing URL in request' );			# 131

@b = get_urls(' ');
ok(  $b[0] );								# 132
ok( !$b[0]->is_success );						# 133
ok(  $b[0]->message eq 'Missing URL in request' );			# 134

@b = move_url(' ', 'file:/tmp/ ');
ok( !$b[0] );								# 135
ok(  $@ eq 'Missing GET URL');						# 136

@b = move_url('/etc/passwd', ' ');
ok( !$b[0] );								# 137
ok(  $@ eq 'Missing PUT URL' );						# 138

@b = put_urls('test', ' ');
ok( !$b[0]->is_success );						# 139
ok(  $b[0]->message eq 'Missing URL in request' );			# 140

# Test copy_urls.
@b = copy_urls(['', $from_uris[0]], [@to_uris, '', 'file:/no/such/path/ZZZ/']);
ok( @b );								# 141
ok(  $b[0] );								# 142
ok(  $b[1] );								# 143
ok( !$b[0]->is_success );						# 144
ok(  $b[0]->message eq 'Missing URL in request' );			# 145
ok(  $b[1]->is_success );						# 146
ok(  $b[1]->{put_requests}[0]->is_success );				# 147
ok(  $b[1]->{put_requests}[1]->is_success );				# 148
ok(  $b[1]->{put_requests}[2]->is_success );				# 149
ok(  $b[1]->{put_requests}[3]->is_success );				# 150
ok(  $b[1]->{put_requests}[4]->is_success );				# 151
ok( !$b[1]->{put_requests}[5]->is_success );				# 152
ok(  $b[1]->{put_requests}[5]->message eq 'Missing URL in request' );	# 153
ok( !$b[1]->{put_requests}[6]->is_success );				# 154
ok(  $b[1]->{put_requests}[6]->message eq 'No such file or directory' ); # 155

# Try to read all of the files we put and compare with what we've read.
@b = get_urls(@to_uris);
ok( @b == @from_files );						# 156
ok( $b[0] );								# 157
ok( $b[1] );								# 158
ok( $b[2] );								# 159
ok( $b[3] );								# 160
ok( $b[4] );								# 161
ok( $b[0]->is_success and $b[0]->content eq $a[0]->content );		# 162
ok( $b[1]->is_success and $b[1]->content eq $a[0]->content );		# 163
ok( $b[2]->is_success and $b[2]->content eq $a[0]->content );		# 164
ok( $b[3]->is_success and $b[3]->content eq $a[0]->content );		# 165
ok( $b[4]->is_success and $b[4]->content eq $a[0]->content );		# 166

# Check the directory listing code.
ok( !list_url );							# 167
ok( !list_url('http://www.perl.com/') );				# 168
ok( $@ eq 'Unsupported scheme http in URL http://www.perl.com/' );	# 169
@b = list_url("file://localhost/$cwd");
ok( @b == 13 );								# 170
ok( !list_url('file://localhost/this/path/should/not/exist') );		# 171
# This case insensitive match is done to match on both Unix and Windows.
#           File or directory `/this/path/should/not/exist' does not exist
ok( $@ =~ m:File or directory `.this.path.should.not.exist' does not exist:i ); # 172
ok( !list_url($from_uris[0]) );						# 173
ok( $@ =~ m:t.file1' is not a directory:i );				# 174
ok( !list_url('ftp://ftp.gps.caltech.edu/ZZZZ') );			# 175
ok( $@ = "Cannot chdir to `ZZZ'" );					# 176
@b = list_url("ftp://ftp.gps.caltech.edu/etc");
ok( @b == 5 );								# 177

# Try one function with a HTTP::Request object.  Because we are doing
# a GET on a object but passing in a request with a DELETE method,
# get_urls should make a clone, change the method and leave the initial
# request alone.
my $http_req = HTTP::Request->new('DELETE', $from_uris[0]);
ok( $http_req and $http_req->method eq 'DELETE' );			# 178
@b = get_urls($http_req);
ok( @b == 1);								# 179
ok( $b[0] and $b[0]->is_success and length($b[0]->content) == 90 );	# 180
ok( $http_req and $http_req->method eq 'DELETE' );			# 181

# Try copying a file from a subdirectory into the current directory.
# This also tests the name appending code for copying a file into a
# directory.
ok( copy_url('file:dir/file6', "file://localhost/$cwd/") );		# 182
ok( -e 'file6' );							# 183
ok( -s _ == 90 );							# 184
ok( unlink('file6') );							# 185

# Clean up the output files.
ok( unlink(map { $_->file } @to_uris) == @from_files );			# 186
@b = list_url("file://localhost/$cwd");
ok( @b == 8 );								# 187
