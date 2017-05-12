package URI::Find::Rule;

use strict;
use vars qw/$VERSION $AUTOLOAD/;
use URI::Find;
use URI;
use Text::Glob 'glob_to_regex';

use Data::Dumper;

$VERSION = '0.8';

sub _force_object {
    my $object = shift;
    $object = $object->new()
      unless ref $object;
    $object;
}

sub _flatten {
    my @flat;
    while (@_) {
        my $item = shift;
        ref $item eq 'ARRAY' ? push @_, @{ $item } : push @flat, $item;
    }
    return @flat;
}

sub in {
    my $self = _force_object shift;
    my ($anonsub, $return_objects) = @_;

	my @urls;
	my $sub = sub {
		my ($original, $uri) = @_;
        my $uri_object = URI->new($uri);
        my $keep = 1;
        my $negate_next = 0;
        foreach my $i (@{ $self->{rules} }) {
            if ($i->{rule} eq 'not') {
                $negate_next = 1;
            } else {
                my $result = &{$i->{code}}($original, $uri, $uri_object);
                $keep = $keep & ($negate_next ^ $result);
                $negate_next = 0;
            }
        }
        if ($keep) {
            if ($return_objects) {
                push @urls, $uri_object;
            } else {
                push @urls, [$original, $uri];
            }
        }
		return $original;
	};
	my $finder = URI::Find->new($sub);
	$finder->find(\$anonsub);
	return @urls;
}

sub new {
    my $referent = shift;
    my $class = ref $referent || $referent;
    my $self = bless {
        rules => []
    }, $class;
    return $self;
}

sub not {
    my $self = _force_object shift;
    push @{ $self->{rules} }, { rule => 'not' };
    return $self;
}

*protocol=\&scheme;

sub AUTOLOAD
{
    (my $method = $AUTOLOAD) =~ s/^.*:://;
	return if $method eq 'DESTROY';

    # It would be nice to do this differently but I can't see any
    # easy way of working around the lack of object at this point.
    # Maybe it's best to rip this out entirely.
    if (URI->new('http://x:y@a/b#c?d')->can($method)) {
        my $code = <<'DEFINE_AUTO';
sub _FUNC_ {
    my $self = _force_object shift;
    my @names = map { ref $_ eq "Regexp" ? $_ : glob_to_regex $_ }  _flatten( @_ );
    my $regex = join( '|', @names );

    push @{ $self->{rules} }, {
        rule => '_FUNC_',
        code => sub { ( $_[2]->_FUNC_() || '' )=~ /$regex/ },
        args => \@_,
    };

    return $self;
}
DEFINE_AUTO
        $code =~ s/_FUNC_/$method/g;
        my $sub = eval $code;
        {
            no strict 'refs';
            return &$AUTOLOAD(@_);
        }
    } else {
        my $code = <<'DEFINE_SCHEME';
sub _FUNC_ {
    my $self = _force_object shift;
    if (@_) {
        $self->scheme('_FUNC_')->host(@_);
    } else {
        $self->scheme('_FUNC_');
    }
}
DEFINE_SCHEME
        $code =~ s/_FUNC_/$method/g;
        eval $code;
        {
            no strict 'refs';
            return &$AUTOLOAD(@_);
        }
    }
}

1;

__END__

=head1 NAME

URI::Find::Rule - Simpler interface to URI::Find

=head1 SYNOPSIS

  use URI::Find::Rule;
  # find all the http URIs in some text
  my @uris = URI::Find::Rule->scheme('http')->in($text);
  # or you can use anything that URI->can() for HTTP URIs
  my @uris = URI::Find::Rule->http->in($text);

  # find all the URIs referencing a host
  my @uris = URI::Find::Rule->host(qr/myhost/)->in($text);

=head1 DESCRIPTION

URI::Find::Rule is a simpler interface to URI::Find (closely
modelled on File::Find::Rule by Richard Clamp). 

Because it operates on URI objects instead of the stringified
versions of the found URIs, it's nicer than, say, grepping the 
stringified values from URI::Find::Simple's C<list_uris> method.

It returns (default) a list containing C<[$original, $uri]> for each
URI or, optionally, a list containing a L<URI> object for each URI.

=head1 METHODS

Apart from C<in>, all the methods can take multiple strings or regexps
to match against, e.g.
  
  ->scheme('http')          # match against the single string 'http'
  ->scheme('http','ftp')    # match either string 'http' or 'ftp'
  ->scheme(qr/tp$/, 'ldap') # match /tp$/ or the string 'ldap'

They can also be combined to provide more selective filtering, e.g.

  ->scheme('ftp')->host('pi.st') # match FTP URIs with a host of pi.st

The filtering is done by checking against the corresponding methods
called on the URI object so almost anything (see L<BUGS>) you can do
with a URI object, you can filter on.  

Only a few methods are listed, for more examples check the tests.

=head2 in

  URI::Find::Rule->in($text);

With a single argument, returns a list of anonymous arrays containing 
C<($original_text, $uri)> for each URI found in C<$text>.

  URI::Find::Rule->in($text, 'objects');

With a true-valued second argument, it returns a list of URI objects,
one for each URI found in C<$text>.

=head2 not

  URI::Find::Rule->http()->not()->host(qr/frottage/)->in($text);

Negates the immediately following rule.

=head2 scheme

  URI::Find::Rule->scheme('http')->in($text);

Filters the URIs found based on their scheme.  

=head2 host

  URI::Find::Rule->host('pi.st')->in($text);

Filters the URIs found based on their parsed hostname.

=head2 protocol

  URI::Find::Rule->protocol('http')->in($text);

A convenient alias for C<scheme>.

=head2 other methods

  ->ldap('pi.st') # converts to ->scheme('ldap')->host('pi.st')

Any unrecognised method will be converted to C<< ->scheme($method)->host(@_) >> for
convenience.

=head1 BUGS

C<< URI->can() >> needs a URI before it'll respond -- at the moment, this
is C<http://x:y@a/b#c?d> which means that any of the scheme-specific
methods (like C<< $uri->dn >> for LDAP URIs can't be used.)

The anonymous arrays contain the original text and the stringified URI in
reverse order when compared with URI::Find's callback.  This may confuse.

=head1 CREDITS

Richard Clamp (patches, code to cargo cult from)
John Levon (pointing out broken comments and complexity)

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2004, Rob Partington <perl-ufr@frottage.org>

=cut

