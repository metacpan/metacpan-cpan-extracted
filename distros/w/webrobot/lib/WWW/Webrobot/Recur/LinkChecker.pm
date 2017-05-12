package WWW::Webrobot::Recur::LinkChecker;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


use WWW::Webrobot::HtmlAnalyzer;
use WWW::Webrobot::Tree2Postfix;

=head1 NAME

WWW::Webrobot::Recur::LinkChecker - check all links you can get.

=head1 SYNOPSIS

see L<WWW::Webrobot::pod::Testplan>

=head1 DESCRIPTION

This module allows to load an HTML page,
extract all contained frames (recursivly),
all images,
and all links.
It then follows these references

=head1 METHODS

=over

=cut

my $unary_operator = {
    'not' => sub { ! $_[0] },
};

my $binary_operator = {
    'and' => sub { $_[0] && $_[1] },
    'or'  => sub { $_[0] || $_[1] },
};

my $predicate = {
    url => sub {
        my ($uri, $tree) = @_;
        my $regex = $tree->{value};
        #print "REGEX=$regex URI=$uri\n";
        return $uri =~ /$regex/ ? 1 : 0;
    },
    scheme => sub {
        my ($uri, $tree) = @_;
        my $regex = $tree->{value};
        my $arg = URI -> new($uri) -> scheme();
        #return 0;
        return $arg =~ /$regex/ ? 1 : 0;
    },
    host => sub {
        my ($uri, $tree) = @_;
        my $regex = $tree->{value};
        my $arg = URI -> new($uri) -> host();
        return $arg =~ $regex ? 1 : 0;
    },
    port => sub {
        my ($uri, $tree) = @_;
        my $regex = $tree->{value};
        my $arg = URI -> new($uri) -> port();
        return $arg =~ $regex ? 1 : 0;
    },
    'host:port' => sub {
        my ($uri, $tree) = @_;
        my $regex = $tree->{value};
        my $host = URI -> new($uri) -> host();
        my $port = URI -> new($uri) -> port();
        my $arg = "$host:$port";
        return $arg =~ $regex ? 1 : 0;
    },
};


=item new ()

Constructor

=cut


sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    my ($tree) = @_;
    $self->{evaluator} = WWW::Webrobot::Tree2Postfix -> new(
        $unary_operator, $binary_operator, $predicate, "and"
    );
    $self->{evaluator}->tree2postfix($tree);
    $self->{follow_link} = sub {
        my ($result, $error) = $self->{evaluator}->eval_postfix($_[0]);
        return $result ? 1 : 0;
    };
    $self->{url_rejected} = sub {};
    $self->{url_accepted} = sub {};
    $self->{ignore_img} = 0;
    return $self;
}


=item $obj -> next ($r)

See L<WWW::Webrobot::pod::Recur/next>

=cut

sub next {
    my $self = shift;
    my ($r) = @_;
    my $in = $r -> {'_content'};
    my $uri = $r -> {_request} -> {_uri};
    $self -> {current_uri} = $uri;
    if ($self -> is_type("text/html", $r->{_headers}->{'content-type'})) {
	# nur in einer HTML-Seite gibt es neue Links
	my ($img, $frame, $a, $refresh) = WWW::Webrobot::HtmlAnalyzer -> get_links($uri, \$in);
        if ($self->{ignore_img}) {
            foreach my $img_url (@$img) {
                $self -> {url_rejected} -> ($img_url);
            }
            $img = [];
        }

	($img, $frame,$a) = $self -> only_allowed($img, $frame,$a);
	push @{$self -> {img}}, @$img;
	push @{$self -> {frame}}, @$frame;
	push @{$self -> {a}}, @$a;
    }
    my $e = $self -> next_link($self->{img}, $self->{frame}, $self->{a});
    $self -> {visited} -> {$e} = 1 if defined $e;
    return (defined $e) ? ($e, $self->{seen}->{$e} || []) : (undef, undef);
}


sub is_type {
    my $self = shift;
    my ($match, $obj) = @_;
    return 0 if !defined $obj;
    $obj = [$obj] if !ref($obj);
    foreach (@$obj) {
	return 1 if m/$match/;
    }
    return 0;
}


=item $obj -> allowed ($url)

See L<WWW::Webrobot::pod::Recur/allowed>

=cut

sub allowed {
    my ($self, $uri) = @_;
    return $self -> {follow_link} -> ($uri);
}


sub only_allowed {
    my $self = shift;
    my @ret = ();
    foreach my $array (@_) {
	# delete all links that are not allowed
	my @new = ();
	foreach (@$array) {
	    if (!defined($self -> {seen} -> {$_})) { # link unseen yet
		$self -> {seen} -> {$_} = [] if !defined $self -> {seen} -> {$_};
		push @{$self -> {seen} -> {$_}}, $self->{current_uri};
		if ($self -> allowed($_)) {
		    push @new, $_;
		    $self -> {url_accepted} -> ($_);
		}
		else {
		    $self -> {url_rejected} -> ($_);
		}
	    }
	}
        push @ret, \@new;
    }
    return @ret;
}


sub next_link {
    my $self = shift;
    foreach my $array (@_) {
        my $n = shift @$array;
	return $n if defined $n;
    }
    return undef;
}

=back

=cut


1;
