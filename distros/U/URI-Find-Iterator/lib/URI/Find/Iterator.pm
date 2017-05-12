package URI::Find::Iterator;

use strict;
require URI;
use URI::Find;
use URI::URL;
use UNIVERSAL::require;

use vars qw($VERSION);

$VERSION = "0.6";


# Identifying characters accidentally picked up with a URI.
my($cruft_set) = q{),.'";}; #'#
my($scheme_re) = $URI::scheme_re;

=pod

=head1 NAME

URI::Find::Iterator - provides an iterator interface to B<URI::Find>

=head1 SYNOPSIS

    use URI::Find::Iterator;

    my $string = "foo http://thegestalt.org/simon/ bar\n";
    my $it     = URI::Find::Iterator->new($string);

    while (my ($uri, $orig_match) = $it->match()) {
        print "Matched $uri\n";
        $it->replace("<a href='$uri'>$uri</a>");
    }

    # prints
    # foo <a href='http://thegestalt.org/simon/'>http://thegestalt.org/simon</a> bar
    print $it->result();



=head1 DESCRIPTION

Inspired by Mark Jason Dominus' talk I<Programming with Iterators and Generators> 
(available from http://perl.plover.com/yak/iterators/) this is an iterative 
version of B<URI::Find> that hopefully makes code a little easier to understand 
and works slightly better with people's brains than callbacks do.


=head1 METHODS

=head2 new <string> [%opts]
    
Takes a string checking as an argument. Optionally can also take a 
class name to extract regexes from (the class must have uri_re and 
schemeless_uri_re methods).

    URI::Find::Iterator->new($string, class => "URI::Find::Schemeless"); 

would be the canonical example.

Alterantively it could take a straight regexp of your own devising 

    URI::Find::Iterator->new($string, re => "http://[^ ]+");

=cut


sub new {
    my ($class, $string, %opts) = @_;

    my $re;

    if (defined $opts{'re'}) {
        $re = $opts{'re'};
    } else {
    
        my $re_class = $opts{'class'} || "URI::Find";
        
        $re_class->require() || die "No such class $re_class\n";
        $re_class->can('uri_re') || die "$re_class has no method uri_re\n";
        $re_class->can('schemeless_uri_re') || die "$re_class has no method schemeless_uri_re\n";
    
        $re = sprintf '(?:%s|%s)', $re_class->uri_re, $re_class->schemeless_uri_re;
        $re = "(<$re>|$re)";
    }


    my $self          = {};
    $self->{_re}      = $re;
    $self->{_result}  = "";
    $self->{_remain}  = $string;
    $self->{_match}   = undef;
    

    return bless $self, $class;

}

=head2 match

Returns the current match as a tuple - the first element of which is 
a B<URI::URL> object and the second is the original text of the URI found.

Just like B<URI::Find>. 

It then advances to the next one.

=cut 


sub match {
        my $self = shift;
        return undef unless defined $self->{_remain};
        $self->_next();

        my $re = $self->{_re};

        $self->{_remain}   =~ /(<$re>|$re)/;

        return undef unless defined $1;

        # stolen from URI::Find
        my $orig = $1;
        my $pre  = $` || "";
        my $post = $' || "";
    

           # A heruristic.  Often you'll see things like:
        # "I saw this site, http://www.foo.com, and its really neat!"
        # or "Foo Industries (at http://www.foo.com)"
        # We want to avoid picking up the trailing paren, period or comma.
        # Of course, this might wreck a perfectly valid URI, more often than
        # not it corrects a parse mistake.
        my $clean_match = $self->_decruft($orig);
        
        # Translate schemeless to schemed if necessary.
        my $uri = $self->_schemeless_to_schemed($clean_match) unless
                              $clean_match =~ /^<?${scheme_re}:/;

        eval {
            $uri = URI::URL->new($uri);
        };

        if (!$@ && defined $uri) {
            $self->{_result}  .= $pre;
            $self->{_remain}   = $post; 
            $self->{_match}    = $orig;
        }


        return ($uri, $clean_match);
}

sub _schemeless_to_schemed {
    my($self, $uri_cand) = @_;

    $uri_cand =~ s|^(<?)ftp\.|$1ftp://ftp\.|
        or $uri_cand =~ s|^(<?)|${1}http://|;

    return $uri_cand;
}



sub _decruft {
    my($self, $orig_match) = @_;

    $self->{start_cruft} = '';
    $self->{end_cruft} = '';

    if( $orig_match =~ s/([${cruft_set}]+)$// ) {
        $self->{end_cruft} = $1;
    }

    return $orig_match;
}



=head2 replace <replacement>

Replaces the current match with I<replacement>

=cut




sub replace {
        my ($self, $replace) = @_;
        return unless defined $self->{_match};
        $self->{_match} = $replace;

}

=head2 result

Returns the string with all replacements.

=cut 

sub result {
    my $self = shift;
    my $start = $self->{_result} || "";
    my $match = $self->{_match}  || "";
    my $end   = $self->{_remain} || "";


    return "${start}${match}${end}";

}

sub _next {
         my $self = shift;
         return undef unless defined $self->{_match};
        
         $self->{_result}  .= $self->{_match};
         $self->{_match}    = undef;
}


=pod

=head1 BUGS

None that I know of but there are probably loads.

It could possibly be split out into a generic 
B<Regex::Iterator> module.

=head1 COPYING

Distributed under the same terms as Perl itself.

=head1 AUTHOR

Copyright (c) 2003, Simon Wistow <simon@thegestalt.org>

=head1 SEE ALSO

L<URI::Find>, http://perl.plover.com/yak/iterators/

=cut

# keep perl happy
1;
