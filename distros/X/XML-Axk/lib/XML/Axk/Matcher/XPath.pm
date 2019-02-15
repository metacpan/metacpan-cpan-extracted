#!/usr/bin/env perl
# XML::Axk::Matcher::XPath - XPath matcher
# Reminder: all matchers define test($refdata)->bool.
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.

package XML::Axk::Matcher::XPath;
use XML::Axk::Base qw(:default any);
use XML::Axk::DOM;

our $VERBOSE = 0;

use XML::Axk::Object::TinyDefaults
    {   kind => 'xpath',
        file => '(unknown source)',
        line => 0
    },
    qw(xpath);

sub _dump {
    local $Data::Dumper::Maxdepth = 2;
    Dumper @_;
} #_dump()

# Constructor and worker ================================================

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    croak "No xpath specified" unless $self->{xpath};

    return $self;
} #new()

# Determine if the record indicated in $hrCP matches the xpath we have stored.
sub test {
    my $self = shift;
    my $hrCP = shift or return false;   # Core params

    eval {
        say "XPath: Attempt to match `$self->{xpath}' in ", $self->file,
        ' at ', $self->line, ' against ', ref $hrCP->{record};
        say _dump $hrCP if $VERBOSE>1;
    } if $VERBOSE>0;

    # Works, but slow
    #my @matches = $hrCP->{document}->findnodes($self->xpath);
    #say "XPath matches: ", _dump(\@matches) if $VERBOSE>0;
    #return any { $_ == $hrCP->{record} } @matches;

    # Works.  We have to use the xp directly because XML::DOM::XPath v0.14 L59
    # (https://metacpan.org/source/MIROD/XML-DOM-XPath-0.14/XPath.pm#L59)
    # swaps the order of the document and node parameters in the call to
    # xp->matches().
    return $hrCP->{document}->xp->matches(
        $hrCP->{record},      # element
        $self->xpath,           # path
        $hrCP->{document}     # context
    );

} #test()

1;
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker: #
