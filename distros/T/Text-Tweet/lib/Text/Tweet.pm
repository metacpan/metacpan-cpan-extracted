package Text::Tweet;
BEGIN {
  $Text::Tweet::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $Text::Tweet::VERSION = '0.004';
}
# ABSTRACT: Optimize a tweet based on given keywords

use Moo;
use Text::Trim;


has maxlen => (
	is => 'ro',
	default => sub { 140 },
);

has marker => (
	is => 'ro',
	default => sub { '#' },
);

# TODO
has marker_re => (
	is => 'ro',
	default => sub { '\#' },
);

has hashtags_at_end => (
	is => 'ro',
	default => sub { 0 },
);

has keywords => (
	is => 'ro',
	default => sub {[]},	
);

# TODO - mappings
has mappings => (
	is => 'ro',
	default => sub {{}},
);

sub make_tweet {
	my ( $self, $text, $url, $keywords ) = @_;
	warn '['.__PACKAGE__.'] This function is DEPRECATED, use ->make($text,\$url,\@keywords)'."\n";
	return $self->make($text,\$url,$keywords);
}

sub make {
	my $self = shift;
	return $self->_generate_tweet( $self->keywords, @_ );
}

sub make_without_keywords { shift->_generate_tweet(@_) }

sub parts_length {
	my @parts;
	for (@_) {
		if (ref $_ eq 'SCALAR') {
			push @parts, ${$_};
		} else {
			push @parts, $_;
		}
	}
	length(join(' ',@parts));
}

sub _generate_tweet {
	my $self = shift;

	my @keywords;
	my @parts;

	for my $part (@_) {
		my $newpart;
		if (ref $part eq 'ARRAY') {
			push @keywords, @{$part};
		} elsif (ref $part eq 'HASH') {
			# TODO - mappings
		} elsif (ref $part eq 'SCALAR') {
			my $scalar_newpart = \trim(join(' ',split(/[\n\r\t ]+/,${$part})));
			$newpart = $scalar_newpart if ${$scalar_newpart};
		} else {
			$newpart = trim(join(' ',split(/[\n\r\t ]+/,scalar $part)));
		}
		push @parts, $newpart if $newpart;
	}
	
	my @newparts;
	my @used_keywords;
	my $marker = $self->marker;
	my $marker_re = $self->marker_re;
	for my $keyword (@keywords) {

		if (!grep { lc($_) eq lc($keyword) } @used_keywords) {
			push @used_keywords, $keyword;

			my $count = parts_length(@parts,@newparts);			
			last if $count + 1 + length($marker) > $self->maxlen;

			my $hkeyword = lc($keyword);
			$hkeyword =~ s/[^\w]|_//ig;
			$hkeyword = $marker.$hkeyword;

			my $found_in_parts = 0;
			
			if (!$self->hashtags_at_end) {
				for (@parts) {
					next if ref $_ eq 'SCALAR';
					my $original_part = $_;
					$_ =~ s/($keyword)/$marker$1/i;
					if ($_ ne $original_part) {
						$found_in_parts = 1;
						last;
					}
				}
			}
			
			if ($self->hashtags_at_end || ( !$self->hashtags_at_end && !$found_in_parts ) ) {
				if ($count + 1 + length($hkeyword) <= $self->maxlen) {
					push @newparts, $hkeyword;
				}
			}

		}

	}
	for (@parts) { $_ = ${$_} if (ref $_ eq 'SCALAR') };
	push @parts, @newparts;
	
	return join(" ",@parts);
}



1;

__END__
=pod

=head1 NAME

Text::Tweet - Optimize a tweet based on given keywords

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Text::Tweet;
  
  my $tweeter = new Text::Tweet({
    maxlen => 140,
    marker => '#',
    hashtags_at_end => 0,
    keywords => [ 'Perl', 'Twitter', 'Facebook', 'Private' ],
  });
  
  my $tweet = $tweeter->make(
    'This is my Perl Twitter Facebook Tweet',
    \'http://some.url/'
  );
  # This is my #Perl #Twitter #Facebook Tweet http://some.url/ #private

  my $next_tweet = $tweeter->make_without_keywords(
    'This is my Perl Twitter Facebook Tweet',
    \'http://some.url/',
    [ 'Tweet' ]
  );
  # This is my Perl Twitter Facebook #Tweet http://some.url/

  my $other_tweeter = new Text::Tweet({
    hashtags_at_end => 1,
  });

  my $other_tweet = $other_tweeter->make(
    'This is my Perl Twitter Facebook Tweet',
    \'http://some.url/',
    [ 'Perl', 'Twitter', 'Facebook' ]
  );
  # This is my Perl Twitter Facebook Tweet http://some.url/ #perl #twitter #facebook

=head1 DESCRIPTION

This package is nothing more than a little helper for making a more optimized tweet. It is supposed to be part of some bigger application,
for example for automatic Tweet generation out of RSS, or integrated via Ajax on a webpage to offer more effective tweets for the user.

=head1 CONTRIBUTORS

L<edenc|http://search.cpan.org/~edenc> - giving API design hints

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by L<Raudssus Social Software|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

