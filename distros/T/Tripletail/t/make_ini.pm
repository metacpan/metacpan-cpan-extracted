## ----------------------------------------------------------------------------
#  t/make_ini.pm
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright YMIRLINK, Inc.
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
package t::make_ini;
use strict;
use warnings;

our $USER;
our $INI_FILE;
our @cleanup;
our $NOCLEAN = $ENV{TL_TEST_NOCLEAN};

&setup;

1;

# -----------------------------------------------------------------------------
# $pkg->import({ ini => \%ini, });
# $pkg->import({ ini => sub{\%ini}, cleanup=>[qw(..)]);
# use t::make_ini \%opts;
# -----------------------------------------------------------------------------
sub import
{
	my $pkg  = shift;
	my $opts = shift;
	
	my $ini = $opts->{ini};
	$ini or die "no ini";
	ref($ini) eq 'CODE' and $ini = $ini->();
	write_ini($ini);
	
	if( $opts->{clean} )
	{
		push(@cleanup, @{$opts->{clean}});
	}
}

# -----------------------------------------------------------------------------
# setup.
# -----------------------------------------------------------------------------
sub setup
{
	$USER = eval{getpwuid($<)} || $ENV{USERNAME};
	$USER && $USER=~/^(\w+)\z/ or $USER = 'guest';
	
	$INI_FILE = "tmp$$.ini";
	-d "t" and $INI_FILE = "t/$INI_FILE";
}

# -----------------------------------------------------------------------------
# tear down.
# -----------------------------------------------------------------------------
END
{
	$NOCLEAN or unlink @cleanup;
}

# -----------------------------------------------------------------------------
# write_ini(%ini);
# write ini on $t::make_ini::INI_FILE;
# -----------------------------------------------------------------------------
sub write_ini
{
	my $hash = shift;
	
	#print STDERR "write [$INI_FILE]\n";
	open my $fh, '>', $INI_FILE or die "could not create file [$INI_FILE]: $!";
	my @keys = sort keys %$hash;
	@keys = ((grep{/^TL$/}@keys),(grep{!/^TL$/}@keys));
	my $cont = 0;
	foreach my $group (@keys)
	{
		$cont and print $fh "\n";
		print $fh "[$group]\n";
		foreach my $key (sort keys %{$hash->{$group}})
		{
			my $val = $hash->{$group}{$key};
			ref($val) eq 'ARRAY' and $val = join(',',@$val);
			print $fh "$key = $val\n";
		}
		$cont = 1;
	}
	close $fh;
	push(@cleanup, $INI_FILE);
}

# -----------------------------------------------------------------------------
# $ret = tltest($opts)
# forkして子プロセスでTL環境をロードし, 関数を実行.
# $opts->{ini}    = \%ini.
# $opts->{method} = 'GET' | 'POST'
# $opts->{param}  = \%param.
# $opts->{file}   = \%file.
# $opts->{sub}    = \&sub.
# $opts->{timed_result} = $flag.
# $ret :: t::make_ini::TestResult.
# $ret->is_success.
# $ret->content.
# $ret->headers.
# -----------------------------------------------------------------------------
sub tltest
{
	my $opts = shift;
	if( $INC{'Tripletai.pm'} )
	{
		die "Tripletail already loaded";
	}
	
	local(%ENV) = %ENV;
	$ENV{GATEWAY_INTERFACE} = 'Tripletail::Test/0.9';
	$ENV{REQUEST_URI}       = '/';
	$ENV{REQUEST_METHOD}    = $opts->{method};
	$ENV{QUERY_STRING}      = '';
	my $content;
	
	my $enc = sub{
		my $s = shift;
		$s =~ s/([^-\w])/'%'.unpack("H*",$1)/ge;
		$s;
	};
	if( !$opts->{method} )
	{
		die "no method";
	}elsif( $opts->{method} eq 'GET' )
	{
		$ENV{QUERY_STRING} = join('&', map{ join('&', map{$enc->($_)} $_, $opts->{param}{$_}); } keys %{$opts->{param}});
	}elsif( !$opts->{file} )
	{
		$content = join('&', map{ join('&', map{$enc->($_)} $_, $opts->{param}{$_}) } keys %{$opts->{param}});
		$ENV{CONTENT_LENGTH} = length($content);
	}else
	{
		my $boundary;
		my $retry = 0;
		MULTIPART:
		{
			$boundary = sprintf('%08x%08x', rand(0xffffffff), rand(0xffffffff));
			$content = '';
			foreach my $key (keys %{$opts->{param}})
			{
				my $val = $opts->{param}{$key};
				if( index($key, $boundary)!=-1 || index($val, $boundary)!=-1 )
				{
					++$retry;
					$retry>=10 and die "could not build multipart content";
					redo MULTIPART;
				}
				$content .= "--$boundary\r\n";
				$content .= qq{Content-Disposition: name="$key"\r\n};
				$content .= "\r\n";
				$content .= $val;
				$content .= "\r\n";
			}
			foreach my $key (keys %{$opts->{file}})
			{
				my $val = $opts->{file}{$key};
				if( index($key, $boundary)!=-1 || index($val, $boundary)!=-1 )
				{
					++$retry;
					$retry>=10 and die "could not build multipart content";
					redo MULTIPART;
				}
				$content .= "--$boundary\r\n";
				$content .= qq{Content-Disposition: name="$key"; filename="$key"\r\n};
				$content .= "\r\n";
				$content .= $val;
				$content .= "\r\n";
			}
			$content .= "--$boundary--\r\n";
		}
		$ENV{CONTENT_TYPE} = qq{multipart/form-data; boundary="$boundary"};
		$ENV{CONTENT_LENGTH} = length($content);
	}
	write_ini($opts->{ini});
	
	pipe(my $par_r, my $chl_w) or die "pipe(stdin): $!";
	pipe(my $chl_r, my $par_w) or die "pipe(stdout): $!";
	local($SIG{CHLD})=  'DEFAULT';
	my $pid = fork();
	if( !defined($pid) )
	{
		die "fork: $!";
	}
	if( !$pid )
	{
		close $par_r;
		close $par_w;
		my $caller = $opts->{caller} || caller();
		select((select($chl_w),$|=1)[0]);
		eval{
			# dup2 does not works well on MSWin32.
			local(*STDIN)  = $chl_r;
			local(*STDOUT) = $chl_w;
			local(*STDERR) = $chl_w;
			$| = 1;
			eval "{package $caller; use Tripletail qw($INI_FILE);1;}";
			$@ and die "load: $@";
			alarm(15);$SIG{ALRM} = sub{ print "ALRM\n";exit 1;};
			$opts->{sub}->();
		};
		$@ and print $chl_w $@;
		exit;
	}
	close $chl_r;
	close $chl_w;
	if( defined($content) )
	{
		print $par_w $content;
	}
	close $par_w;
	my $hdr = {};
	my $valref;
	my $body;
	$SIG{__DIE__} = 'DEFAULT';
	eval
	{
		while( <$par_r> )
		{
			#print "from-child: [[$_]]\n";
			if( defined($body) )
			{
				if( $opts->{timed_result} )
				{
				  $body .= time.":";
				}
				$body .= $_;
				next;
			}
			if( /^\r?\n\z/ )
			{
				# End of Headers.
				$body = '';
				next;
			}
			s/[\r\n]+\z//;
			if( s/^\s// )
			{
				$valref or die;
				$$valref .= $_;
				next;
			}
			my ($key, $val) = split(/:\s*/, $_, 2);
			if( !defined($val) )
			{
				$body = $_;
				next;
			}
			push(@{$hdr->{$key}}, $val);
			$valref = \$hdr->{$key}[-1];
		}
	};
	$@ and die;
	my $succ = waitpid($pid, 0);
	close $par_r;
	
	my $ret = {
		content => $body,
		headers => $hdr,
	};
	t::make_ini::TestResult->new($ret);
}

package t::make_ini::TestResult;
sub new
{
	my $pkg  = shift;
	my $data = shift;
	my $this = bless { %$data }, $pkg;
	
	exists($this->{content}) or die "no content parameter";
	exists($this->{headers}) or die "no headers parameter";
	
	$this->{status_line} = undef;
	$this->{status_code} = undef;
	$this->{is_success} = undef;
	$this->{is_failure} = undef;
	CHECK_SUCCESS:
	{
		if( my $status_array = $this->{headers}{Status} )
		{
			@$status_array==1 or die "too many Status: lines found ";
			my $status = $status_array->[0];
			my ($code) = $status =~ /^(\d+)(\s|$)/ or die "invalid status line [$status]";
			$this->{status_line} = $status;
			$this->{status_code} = $code;
			if( int($code/100)!=2 )
			{
				$this->{is_success} = undef;
				$this->{is_failure} = "Status: $code";
				last CHECK_SUCCESS;
			}
		}
		if( !defined($this->{content}) )
		{
			$this->{is_success} = undef;
			$this->{is_failure} = "content is undefined";
			last CHECK_SUCCESS;
		}
		if( $this->{content} =~ m{\Q<title>[TL] 内部エラー</title>\E} )
		{
			$this->{is_success} = undef;
			$this->{is_failure} = "internal error";
			last CHECK_SUCCESS;
		}
		$this->{is_success} = 1;
		$this->{is_failure} = undef;
	}
	if( !$this->{status_line} )
	{
		if( $this->{is_success} )
		{
			$this->{status_line} = '200 OK';
			$this->{status_code} = 200;
		}else
		{
			$this->{status_line} = '500 Internal Error';
			$this->{status_code} = 500;
		}
	}
	
	#print Dumper($this); use Data::Dumper;
	$this;
}
sub is_success
{
	shift->{is_success};
}
sub content
{
	shift->{content};
}
sub headers
{
	shift->{headers};
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
