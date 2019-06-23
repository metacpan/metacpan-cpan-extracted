package URI::Pure;

use v5.16;
use strict;
use warnings;

our $VERSION = '0.09';

use Encode;
use Net::IDN::Punycode qw(encode_punycode decode_punycode);


{
# From URI and URI::Escape
my $reserved   = q(;/?:@&=+$,[]);
my $mark       = q(-_.!~*'());
my $unreserved = "A-Za-z0-9\Q$mark\E";
my $uric       = quotemeta($reserved) . $unreserved . "%";

my %escapes = map { chr($_) => sprintf "%%%02X", $_ } 0 .. 255;

sub uri_unescape { my $str = shift; $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg if defined $str; $str }

sub uri_escape   { my $str = shift; $str =~ s/([^$uric\#])/ $escapes{$1} /ego if defined $str; $str }
}


sub _normalize {
	my ($p) = @_;

	return $p unless $p =~ m/\.\// or $p =~ m/\/\./ or $p =~ m/\/\//;

	my $is_abs = $p =~ m/^\// ? 1 : 0;
	my $is_dot = $p =~ m/^\./ ? 1 : 0;
	my $is_dir = ($p =~ m/\/$/ or $p =~ m/\/\.$/ or $p =~ m/\/\.\.$/) ? 1 : 0;

	my @p = split "/", $p;
	shift @p if $is_abs;

	my @n = ();
	foreach my $i (@p) {
		$i or next;
		if ($i eq "..") {
			if ($is_abs) {
					pop @n;
			} else {
				if (@n and $n[0] ne "..") {
					pop @n;
				} else {
					push @n, $i;
				}
			}
		} elsif ($i ne ".") {
			push @n, $i;
		}
	}

	my $r = join "/", ($is_abs ? "" : ()), @n, ($is_dir ? "" : ());
	$r ||= "." if $is_dot;
	return $r;
}



sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my ($uri) = @_;
	if (Encode::is_utf8($uri)) {
		warn "URI must be without utf8 flag: $uri";
		return;
	}

	my ($scheme, $authority, $path, $query, $fragment) =
		$uri =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;
			# На основе взятого из URI (это также рекомендуется в RFC 3986)
			# =head1 PARSING URIs WITH REGEXP
			# Смотри также URI::Split

	my ($user, $password, $host, $port) = $authority =~ m/^(?:([^:]+)(?::(.+))?\@)?([^:]+)(?::(\d+))?$/ if $authority;

	$scheme = lc $scheme if $scheme;

	if ($host) {
		if ($host =~ m/[^\p{ASCII}]/) {
			$host = join ".", map {
				if (m/[^\p{ASCII}]/) {
					my $p = decode_utf8 $_;
					$p =~ s/\x{202b}//g;  # RIGHT-TO-LEFT EMBEDDING
					$p =~ s/\x{202c}//g;  # POP DIRECTIONAL FORMATTING
					join "", "xn--", encode_punycode fc $p;
				} else {
					$_;
				}
			} split /\./, $host;
		} else {
			$host = lc $host;
		}
	}


	$path = _normalize($path) if $path;

	$path  = uri_escape($path) if $path;

	$query = uri_escape($query) if $query;

	my $self = {
		scheme    => $scheme,
		user      => $user,
		password  => $password,
		host      => $host,
		port      => $port,
		path      => $path,
		query     => $query,
		fragment  => $fragment,
	};

	bless $self, $class;
	return $self;
}



foreach my $method (qw(scheme user password host port path query fragment)) {
 	no strict 'refs';
 	*$method = sub { my $self = shift; return $self->{$method} };
}



sub _as {
	my $self = shift;
	my ($iri) = @_;

	my @as_string = ($self->{scheme}, ":") if $self->scheme;

	push @as_string, "//" if $self->{host};

	if ($self->{user}) {
		push @as_string, $self->{user};
		push @as_string, ":", $self->{password} if $self->{password};
		push @as_string, "@";
	}

	if (my $host = $self->{host}) {
		if ($iri and $host =~ m/xn--/) {
			$host = join ".", map {
				if (m/^xn--/) {
					s/^xn--//;
					encode_utf8 decode_punycode $_;
				} else {
					$_;
				}
			} split /\./, $host;
		}
		push @as_string, $host;
	}

	if ($self->{port}) {
		unless (
			($self->{scheme} eq "http"  and $self->{port} == 80) or
			($self->{scheme} eq "https" and $self->{port} == 443)
		) {
			push @as_string, ":", $self->{port};
		}
	}

	if (my $path = $self->{path}) {
		$path = uri_unescape $path if $iri;
		push @as_string, $path;
	}

	if (my $query = $self->{query}) {
		$query = uri_unescape $query if $iri;
		push @as_string, "?", $query;
	}

	push @as_string, "#", $self->{fragment} if $self->{fragment};

	return join "", @as_string;
}

sub as_string {
	my $self = shift;
	$self->_as(0);
}

sub as_iri {
	my $self = shift;
	$self->_as(1);
}


sub abs {
	my ($self, $base) = @_;

	return $self if $self->{scheme};

	if ($self->{host}) {
		$self->{scheme} = $base->{scheme};
		return $self;
	}

	$self->{scheme}    = $base->{scheme};
	$self->{user}      = $base->{user};
	$self->{password}  = $base->{password};
	$self->{host}      = $base->{host};
	$self->{port}      = $base->{port};

	if ($self->{path}) {
		unless ($self->{path} =~ m/^\//) {
			my @path = split /\//, $base->{path};
			pop @path;
			my $path = join "/", @path;
			$self->{path} = _normalize($path . "/" . $self->{path});
		}
	} else {
		$self->{path} = $base->{path};
		$self->{query} ||= $base->{query};
	}

	return $self;
}



1;

__END__


=head1 NAME

URI::Pure - with Internationalized Domain Names (IDN) and Internationalized Resource Identifiers (IRI) support.

=head1 SYNOPSIS

=encoding UTF-8

  use URI::Pure;

  my $u = URI::Pure->new("http://Інтернаціоналізовані.Доменні.Імена/Головна/сторінка?a=Вітаю&b=До побачення");
  $u->as_string; # IDN
  $u->as_iri;    # IRI

  my $b = URI::Pure->new($base);
  my $url = $u->abs($b);

  $url->scheme;
  $url->user;
  $url->password;
  $url->host;
  $url->port;
  $url->path;
  $url->query;
  $url->fragment;

=head1 DESCRIPTION

URI with Internationalized Domain Names (IDN) and Internationalized Resource Identifiers (IRI) support.
Double dot normalization.

=head1 AUTHOR

Nick Kostyria

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Nick Kostyria

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
