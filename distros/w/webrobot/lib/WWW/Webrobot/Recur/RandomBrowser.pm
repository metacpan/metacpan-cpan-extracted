package WWW::Webrobot::Recur::RandomBrowser;
use WWW::Webrobot::HtmlAnalyzer;
use strict;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


=head1 NAME

WWW::Webrobot::Recur::RandomBrowser - act like a user klicking urls.

B<Warning:> This module does not work currently.

=head1 SYNOPSIS

 see L<WWW::Webrobot::pod::Testplan>

=head1 DESCRIPTION

This module allows to load an HTML page,
all contained frames (recursivly),
all images,
and all links.
Then it selects randomly one of these references and follows it.

=head1 METHODS

=over

=item new(%parms)

Constructor

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %parm = (@_);
    my $self  = {
	frame => {},
        img => {},
	a => {},
	url_accept => $parm{url_accept},
	url_reject => $parm{url_reject},
    };
    bless ($self, $class);
    return $self;
}


sub match_content_type {
    my ($self, $match, $obj) = @_;
    $obj = [$obj] if !ref($obj);
    foreach (@$obj) {
	my $m = $_ =~ m/$match/;
	return $m if ($m);
    }
    return 0;
}


sub next {
    my ($self, $r) = @_;
	#print ">>> url_accept => ", $self->{url_accept},
	#    " url_reject => ", $self->{url_reject}, "\n";
    my $in = $r -> {'_content'};
    my $uri = $r -> {_request} -> {_uri};
    if ($self -> match_content_type("text/html", $r->{_headers}->{'content-type'})) {
	# nur in einer HTML-Seite gibt es neue Links
	my ($img, $frame, $a, $refresh) = WWW::Webrobot::HtmlAnalyzer -> get_links($uri, \$in);
	foreach (@$img) {
	    $self -> {img} -> {$_} = 1 if $self -> allowed($_);
	}
	foreach (@$frame) {
	    $self -> {frame} -> {$_} = 1 if $self -> allowed($_);
	}
	foreach (@$a) {
	    $self -> {a} -> {$_} = 1 if $self -> allowed($_);
	}
	#@{$self -> {img}}{@$img} = (1) x @$img;
	#@{$self -> {frame}}{@$frame} = (1) x @$frame;
	#@{$self -> {a}}{@$a} = (1) x @$a;
    }

    my $e = $self -> search_link($self -> {frame});
    return $e if defined($e);

    $e = $self -> search_link($self -> {img});
    return $e if defined($e);

    $e = $self -> search_link($self -> {a});
    $self -> {a} = {};
    return $e if defined($e);

    return undef;
}

sub allowed {
    my ($self, $item) = @_;
    my $accept = $self -> {url_accept};
    my $reject = $self -> {url_reject};
    return ($item =~ m/$accept/ && $item !~ m/$reject/);
}

sub search_link {
    my ($self, $hash) = @_;

    # Ein Element auswählen, ineffizient!
    my @array = keys %$hash;
    my $e = $array[rand @array] || undef;

    #print defined($e) ? "delete($e)" : "e=undef", "\n";
    delete($hash -> {$e}) if defined($e);
    return $e;
}

=back

=cut

1;
