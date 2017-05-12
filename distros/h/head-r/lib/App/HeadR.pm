### HeadR.pm --- head-r(1) core library  -*- Perl -*-

### Copyright (C) 2013 Ivan Shmakov

## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or (at
## your option) any later version.

## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

### Code:
package App::HeadR;

use common::sense;
use English qw (-no_match_vars);

our $VERSION = 0.1;

require Carp;
# require Data::Dump;
require HTML::TreeBuilder;
require Scalar::Util;
require URI;

### Utility functions

sub info_extra_cond {
    my ($info, $limit) = @_;
    ## .
    return (($limit > 0
             && (! defined ($info)
                 || ($info->[1] // 0) < $limit)),
            ! defined ($info));
}

### Methods

sub uri_info {
    ## .
    $_[0]->{"uri-info"};
}

sub user_agent {
    ## .
    $_[0]->{"user-agent"};
}

sub str_wanted {
    my ($self, $s, $descend_extra_p, $info_extra_p) = @_;
    ## Return: ($descend_p, $info_p)
    my ($exclude_re, $include_re)
        = @$self{qw (exclude-re include-re)};
    ## .
    return
        unless (defined    ($include_re)  && $s =~ $include_re
                || defined ($exclude_re)  && $s !~ $exclude_re);
    my ($descend_re, $info_re)
        = @$self{qw (descend-re info-re)};
    # warn ("D: Consider?  ",
    #       join (", ", $s, # $descend_p,
    #             defined ($info_re),
    #             # scalar (Data::Dump::dump ($info)),
    #             scalar ($s =~ $info_re)), "\n");
    ## .
    return (1)
        if ((defined ($descend_re))
            && $descend_extra_p
            && $s =~ $descend_re);
    ## .
    return (0, (defined ($info_re)
                && $info_extra_p && $s =~ $info_re));
}

sub recurse {
    my ($self, $out, $uri_1, $limit) = @_;
    # warn ("D: ", time (),
    #       " recurse: ", scalar (Data::Dump::dump (\@_)), "\n");

    my $uri
        = $uri_1->canonical ();
    ## NB: drop the #fragment, if any
    if (defined ($uri->fragment ())) {
        $uri
            = $uri->clone ()
            if (Scalar::Util::refaddr ($uri)
                == Scalar::Util::refaddr ($uri_1));
        $uri->fragment (undef);
    }
    my $uri_s
        = $uri->as_string ();

    my $info
        = $self->uri_info ()->{$uri_s};
    my ($descend_p, $info_p)
        = $self->str_wanted ($uri_s,
                             info_extra_cond ($info, $limit));

    ## .
    return
        unless (defined ($descend_p));

    unless ($descend_p
            || $info_p) {
        $out->print ($uri_s, "\n")
            unless (defined ($info));
        ## .
        return;
    }
    my $r
        = ($descend_p
           ? $self->user_agent ()->get  ($uri_s)
           : $self->user_agent ()->head ($uri_s));
    unless (defined ($r) && $r->is_success ()) {
        warn ("W: ", $uri_s, ": ", $r->status_line (), "\n")
            if (defined ($r));
        ## .
        return;
    }

    # my $debug_headers
    #     = $r->headers ()->as_string ();
    # $debug_headers
    #     =~ s/^/D:   /mg;
    # warn ("D: Headers:\n", $debug_headers);
    # warn ("D: Descend?  ",
    #       join (", ", $descend_p, $limit > 0, $r->content () ne ""));

    ## URI, Timestamp, X-Depth, Content-Length:, Code, Options
    my @info
        = ($uri_s, time (), $limit,
           $r->content_length () // "",
           $r->code ());
    $out->print (join ("\t", @info), "\n");
    $self->uri_info ()->{$uri_s}
        = \@info;

    ## .
    return
        unless ($descend_p
                && $limit > 0
                && $r->content () ne "");

    if ($r->content_type () !~ /^text\/html/) {
        warn ("W: ", $uri_s, ": Cannot descend into non-HTML (",
              $r->content_type (), "); ignored\n");
        ## .
        return;
    }

    ## FIXME: use HTML::Parser instead?
    my $tree
        = HTML::TreeBuilder->new ();
    ## FIXME: check for errors?
    $tree->parse_content ($r->decoded_content ());
    my @elts
        = $tree->look_down ("href" => qr /./);
    ## .
    return
        unless (@elts);

    foreach my $elt (@elts) {
        my $href
            = $elt->attr ("href");
        my $new
            = URI->new_abs ($href, $uri);
        # warn ("D: ", $elt->as_HTML (), " : ", $new->as_string (), "\n");
        $self->recurse ($out, $new, -1 + $limit);
    }
}

### Constructors

sub new {
    my ($class, $options) = @_;
    ## FIXME: create a user agent object unless given
    Carp::croak ("user-agent must be given and an object")
        unless (Scalar::Util::blessed ($options->{"user-agent"}));
    my $self = {
        "uri-info"  => { }
    };
    $self->{$_}
        = $options->{$_}
        foreach (qw (user-agent),
                 qw (exclude-re include-re descend-re info-re));


    ## .
    bless ($self, $class);
}

### Emacs trailer
## Local variables:
## coding: us-ascii
## End:
### HeadR.pm ends here
