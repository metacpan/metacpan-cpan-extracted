package WWW::Webrobot::Print::MakeTestplan;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    return $self;
}

sub global_start {
    #my $self = shift;
}

sub item_pre {
    #my $self = shift;
    #my ($arg) = @_;
}

sub item_post {
    my ($self, $r, $arg) = @_;
    return if $arg->{fail};

    my $first = $r;
    while (my $tmp = $first->previous) {
        $first = $tmp;
    }
    my $parameters = "";
    $parameters = " " . $first->request->content
        if ($arg->{method} eq "POST") &&
        ($first->request->headers->content_type eq 'application/x-www-form-urlencoded');
    print "$arg->{method} $arg->{url}$parameters\n";
}

sub global_end {
    #my $self = shift;
}

1;

=head1 NAME

WWW::Webrobot::Print::MakeTestplan - print a line based testplan

=head1 DESCRIPTION

This module prints all urls in a format compatible to L<webrobot-gen-plan>.
It is usefull when you use a recursive request such as
L<WWW::Webrobot::Recur::LinkChecker> or L<WWW::Webrobot::Recur::Browser>
and want to convert it to a nonrecursive test naming all urls explicitly.

This module can be used to convert an (nonrecursive) XML testplan
to a line based testplan,
though some information will usually be lost.

=head1 SYNOPSIS

 # In cfg0.prop set
 #     output=WWW::Webrobot::Print::MakeTestplan
 webrobot cfg=cfg0.prop testplan=testplan0.xml | webrobot-gen-plan

=head1 NOTE

=over

=item *

All urls will be requested via HTTP and B<must> succeed!

=item *

The data part of HTTP POSTs will be encoded according CGI.

=item *

Assertions won't be printed, they are lost (as most other parameters)

=back


=head1 METHODS

See L<WWW::Webrobot::pod::OutputListeners>.

=over

=item WWW::Webrobot::Print::MakeTestplan -> new ();

Constructor

=back
