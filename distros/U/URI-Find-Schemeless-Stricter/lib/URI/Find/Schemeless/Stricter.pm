package URI::Find::Schemeless::Stricter;

use 5.00600;

use strict;

use base 'URI::Find';

our $VERSION = '1.03';

# We could put the whole ISO country code thing in here...
my $tldRe      = '(?i:biz|com|edu|gov|info|int|mil|net|org|[a-z]{2})';
my $hostRe     = '(?i:www|ftp|web)';
my $dottedquad = qr/(?:\d{1,3}\.){3}\d{1,3}/;
my $dnsSet     = 'A-Za-z0-9-';
my $cruftSet   = q{),.'";\]};
my $uricSet    = __PACKAGE__->uric_set;

sub _is_uri {
	my ($class, $candidate) = @_;
	return 0 if $$candidate =~ /^$dottedquad$/;
	return $class->SUPER::_is_uri($candidate);
}

sub schemeless_uri_re {
	return qr{
		(?: ^ | (?<=[\s<]) )
		# hostname
		(?: $hostRe\.[$dnsSet]+(?:\.[$dnsSet]+)*\.$tldRe
			| $dottedquad )       # not inet_aton() complete
		(?:
			(?=[\s>?$cruftSet])   # followed by unrelated thing
				(?!\.\w)            #   but don't stop mid foo.xx.bar
				(?<!\.p[ml])        #   but exclude Foo.pm and Foo.pl
			|$                    # or end of line
				(?<!\.p[ml])        #   but exclude Foo.pm and Foo.pl
			|/[$uricSet#]*        # or slash and URI chars
  	)
  }x;
}

1;
__END__

=pod

=head1 NAME

URI::Find::Schemeless::Stricter - Find schemeless URIs in arbitrary text.

=head1 SYNOPSIS

	require URI::Find::Schemeless::Stricter;

 	my $finder = URI::Find::Schemeless::Stricter->new(\&callback);

The rest is the same as URI::Find::Schemeless.

=head1 DESCRIPTION

=head2 schemeless_uri_re

L<URI::Find> finds absolute URIs in plain text with some weak heuristics
for finding schemeless URIs.  This subclass is for finding things
which might be URIs in free text.  It is slightly stricter than
L<URI::Find::Schemeless>, as it finds things like "www.foo.com" but not
"lifes.a.bitch.if.you.aint.got.net"; it finds "1.2.3.4/foo" but not 
"1.2.3.4". This should mean your sectioned lists no longer get marked up
as URLs...

=head1 AUTHOR

Current maintainer: Tony Bowden

Original author: Simon Cozens

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-URI-Find_Schemeless-Stricter@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2003 - 2005 by Kasei Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<URI::Find>, L<URI::Find::Schemeless>

