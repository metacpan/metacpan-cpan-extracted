use strict ;

use File::Spec ;
use Test::More tests => 3 ;
BEGIN { use_ok('autodynaload') } 
BEGIN {$autodynaload::INC[-1]->disable()}

use autodynaload sub {
	my ($this, @args) = @_ ;

	# The last argument is the actual dll name
	my $so_name = pop @args ;
	my @dirs = @args ;

	my $so = undef ;
	foreach my $d (@dirs){
		$d =~ s/^-L// ;
		my $file = File::Spec->catfile($d, $so_name) ;
		$so = autodynaload->is_installed($file) ;
		last if $so ;
	}

	return $so ;
} ;
BEGIN {$autodynaload::INC[-1]->disable()}


eval "use MIME::Base64 ;" ;
like($@, qr/Can't locate loadable object/) ; #'

delete $INC{'MIME/Base64.pm'} ;
$autodynaload::INC[-1]->enable() ;
{
	local $^W ;
	eval "use MIME::Base64 ;" ;
	is(MIME::Base64::encode_base64('A', ''), 'QQ==') ;
}
