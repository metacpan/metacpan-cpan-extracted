package WWW::Webrobot::Recur::Browser;
use WWW::Webrobot::HtmlAnalyzer;
use strict;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


=head1 NAME

WWW::Webrobot::Recur::Browser - act like a browser when selecting a url

=head1 SYNOPSIS

see L<WWW::Webrobot::pod::Testplan/"Request_<recurse>">

=head1 DESCRIPTION

This module allows to load an HTML page,
all contained frames (recursivly)
and all images.

=head1 METHODS

=over

=item Testplan -> new ()

Constructor.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %parm = (@_);
    my $self  = {
	frame      => [],
        img        => [],
	seen       => {},
	visited    => {},
	url_rejected => sub {},
	url_accepted => sub {},
    };
    bless ($self, $class);
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
    if ($self -> is_type("text/html", $r->{_headers}->{'content-type'})) {
	# nur in einer HTML-Seite gibt es neue Links
	my ($img, $frame, $a, $refresh) = WWW::Webrobot::HtmlAnalyzer -> get_links($uri, \$in);
	($img, $frame) = $self -> only_allowed($img, $frame);
	push @{$self -> {img}}, @$img;
	push @{$self -> {frame}}, @$frame;
    }
    my $e = $self -> next_link($self->{img}, $self->{frame});
    $self -> {visited} -> {$e} = 1 if defined $e;
    return $e;
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
    return 1;
}


sub only_allowed {
    my $self = shift;
    my @ret = ();
    foreach my $array (@_) {
	# delete all links that are not allowed
	my @new = ();
	foreach (@$array) {
	    if (!defined($self -> {seen} -> {$_})) { # link unseen yet
		$self -> {seen} -> {$_} = 1;
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
