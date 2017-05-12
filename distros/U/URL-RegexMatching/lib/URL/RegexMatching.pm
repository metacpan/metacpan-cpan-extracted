package URL::RegexMatching;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(url_match_regex http_url_match_regex);
our $VERSION   = '1.1';

sub url_match_regex {
    return
      qr{(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))};
}

sub http_url_match_regex {
    return
      qr{(?i)\b((?:https?://|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))};
}

1;

__END__

=head1 NAME

URL::RegexMatching - A library of utility methods for
matching URLs with regex patterns.

=head1 SYNOPSIS

	#!/usr/bin/perl
	
	use strict;
	use warnings;
	
	use URL::RegexMatching qw(url_match_regex http_url_match_regex);
	
	my $text = <<SAMPLE;
	This is some sample text with links like
	<http://foo.com/blah_blah/> and others like WWW.EXAMPLE.COM
	and bit.ly/foo. And what about something like a
	mailto:name\@example.com pattern?
	SAMPLE
	
	my $url_regex = url_match_regex; 
	my $http_regex = http_url_match_regex;
	
	print "Using this sample text:\n";
	print "$text\n";
	
	print "These strings are probably links:\n";
	while ($text =~m{$url_regex}g) {
		print "\t$1\n";
	}
	
	print "\nWeb URLs:\n";
	while ($text =~m{$http_regex}g) {
		print "\t$1\n";
	}
	
	$text =~s{$http_regex}{<a href="$1">$1</a>}g;
	
	print "\n\n";
	print "Convert only HTTP links to HTML links using http_url_match_regex:\n";
	print "$text\n";
	
=head1 DESCRIPTION

This package is based on regular expression patterns
initially developed by John Gruber of Daring Fireball fame.
This module is simply a packaging of his work to make
utilization by the Perl community easier.

=head1 METHODS

=head2 url_match_regex

This method takes no arguments and returns a compiled
regular expression matching pattern. The pattern will
liberally match string that appear to be various HTTP, HTTPS
and mailto including a best attempt to identify relative URLs.

This method can be exported by request.

=head2 http_url_match_regex

This method takes no arguments and returns a compiled
regular expression matching pattern. This pattern will
liberally match I<only> web URLs -- http, https and relative
forms such as www.example.com

This method can be exported by request.

=head1 KNOWN ISSUES

Both regular expression patterns are known to fail against URL strings such as:

=over 4

=item http://example.com/quotes-are-“part”

=item ✪df.ws/1234
	
=item example.com

=item example.com/

=back

When using the C<http_url_match_regex> method it is likely
to match link strings whose domain/file path looks like a
web URL, but uses a different protocol such as
'ftp://www.example.com/foo.txt' where the match would
capture all but the 'ftp://' part.

=head1 SUPPORT

Bugs should be reported via the GitHub project issues tracking system:
L<http://github.com/tima/perl-url-regexmatching/issues>

=head1 AUTHOR

Timothy Appnel <tima@cpan.org>

=head1 SEE ALSO

http://daringfireball.net/2010/07/improved_regex_for_matching_urls

=head1 COPYRIGHT AND LICENCE

This module is based on the work of John Gruber of Daring
Fireball. John writes "this pattern is free for anyone to
use, no strings attached. Consider it public domain."

The software is released under the Artistic License. The
terms of the Artistic License are described at
http://www.perl.com/language/misc/Artistic.html. 

Except where otherwise noted, URL::RegexMatching is
Copyright 2010, Timothy Appnel, tima@cpan.org. All rights
reserved.
