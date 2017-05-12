use LWP::Simple 'get';
use lib::abs;
sub {
	my $fn = lib::abs::path('.').'/uploads.rdf';
	open my $f, '<',$fn  or return do {
		warn "Fetching file\n";
		my $data = get 'http://search.cpan.org/uploads.rdf';
		open my $fo, '>', $fn;
		print $fo $data;
		close $fo;
		$data;
	};
	warn "Have preloaded file\n";
	local $/;
	<$f>
}->();
