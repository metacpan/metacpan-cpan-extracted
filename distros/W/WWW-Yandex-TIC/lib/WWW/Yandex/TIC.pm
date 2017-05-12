package WWW::Yandex::TIC;

# -*- perl -*-

use strict;
use warnings;

use vars qw($VERSION);

use LWP::UserAgent;
use HTTP::Headers;

# we try to parse yandex bar info
# on failure we must parse yandex catalog page

$VERSION = '0.07';

my $regexps = [
	qr/(?is)<p class="errmsg">.*?<b>[^<]+? &(?:#151|mdash); (\d+)/,
	qr|(?is)<p class="errmsg">.*?<b>[^<]+? 1(\d+).|, # zero -)
	qr|(?is)<tr valign="top"[^<]+<td class="current".+?\/td>[^<]+(?:<td .+?\/td>[^<]+){2}?<td\D+(\d+)|,
];

sub new {
	my $class = shift;
	my %par = @_;
	my $self;
	
	# config overrided by parameters
	my $ua = $self->{ua} = LWP::UserAgent->new;
	
	my $proxy = delete $par{proxy};
	
	foreach my $k (keys %par) {
		$ua->$k ($par{$k});
	}
	
	if ($proxy) {
		# support for old interface
		$ua->proxy ('http', $proxy);
	}
	
	bless($self, $class);
}

sub user_agent {
	shift->{ua};
}

sub request_uri {
	my ($self, $url) = @_;

	my $query = "http://search.yaca.yandex.ru/yca/cy/ch/$url/";

	return $query;
}

sub get {
	my ($self, $url) = @_;

	my $query = $self->request_uri ($url);

	my $resp = $self->{ua}->get($query);

	if ($resp->is_success) {
		
		my $content = $resp->content;
		
		my $tic = undef;
		
		my $c = 0;
		
		foreach my $rx (@$regexps) {
			if ($content =~ /$rx/) {
				$tic = $1;
				last;
			}
		}

		if (wantarray) {
			return ($tic, $resp);
		} else {
			return $tic;
		}

	} else {
		if (wantarray) {
			return (undef, $resp);
		} else {
			return;
		}
	}
}

1;

__END__

=head1 NAME

WWW::Yandex::TIC - Query Yandex Thematic Index of Citing (TIC) for domain

=head1 SYNOPSIS

 use WWW::Yandex::TIC;
 my $ytic = WWW::Yandex::TIC->new;
 print $ytic->get('www.yandex.ru'), "\n";

=head1 DESCRIPTION

The C<WWW::Yandex::TIC> is a class implementing a interface for
querying Yandex Thematic Index of Citing (TIC) for domain.

To use it, you should create C<WWW::Yandex::TIC> object and use its
method get(), to query TIC for domain.

It uses C<LWP::UserAgent> for making request to Yandex.

=head1 CONSTRUCTOR METHOD

=over 4

=item  $tic = WWW::Yandex::TIC->new(%options);

This method constructs a new C<WWW::Yandex::TIC> object and returns it.

=item  $ua = $tic->user_agent;

This method returns constructed C<LWP::UserAgent> object.
You can configure object before making requests. 
Default configuration described below:

   KEY                     DEFAULT
   -----------             --------------------
   agent                   "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.1) Gecko/2008070206 Firefox/3.0.1"
   default_headers         "Accept-Charset: utf-8;q=0.7,*;q=0.7"

C<agent> specifies the header 'User-Agent' when querying Yandex.
C<default_headers> is a C<HTTP::Headers> object. See C<LWP::UserAgent>.

=back

=head1 QUERY METHOD

=over 4

=item  $tic = $ytic->get('www.yandex.ru');

Queries Yandex for a specified Yandex Thematic Index of Citing (TIC) for domain and returns TIC. If
query successfull, integer value from 0 to over 0 returned. If query fails
for some reason (Yandex unreachable, domain does not in Yandex catalog) it return C<undef>.

In list context this function returns list from two elements where
first is the result as in scalar context and the second is the
C<HTTP::Response> object (returned by C<LWP::UserAgent::get>). This
can be usefull for debugging purposes and for querying failure
details.

=back

=head1 BUGS

If you find any, please report ;)

=head1 AUTHOR

Dmitry Bashlov F<E<lt>bashlov@cpan.orgE<gt>> http://bashlov.ru.
Ivan Baktsheev F<E<lt>dot.and.thing@gmail.comE<gt>>.

=head1 COPYRIGHT

Copyright 2005, Dmitry Bashlov
Copyright 2008-2009, Ivan Baktsheev

You may use, modify, and distribute this package under the
same terms as Perl itself.
