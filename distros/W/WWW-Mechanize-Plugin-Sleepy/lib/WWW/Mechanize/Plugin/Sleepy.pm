package WWW::Mechanize::Plugin::Sleepy;

our $VERSION = '0.003'; # VERSION

# ABSTRACT: A WWW::Mechanize plugin to provide the behaviour of WWW::Mechanize::Sleepy while using WWW::Mechanize::Pluggable

use strict;
use warnings;
use Carp qw/ croak /;


sub import {
    my ( $class, %args ) = @_;
    $WWW::Mechanize::Pluggable::Sleepy = $args{sleep}
        if defined $args{sleep};
}

sub init {
    my ( $class, $pluggable, %args ) = @_;

    no strict 'refs';
    *{ caller() . '::sleep' }  = \&sleep;
    *{ caller() . '::_sleep' } = \&_sleep;

    foreach my $method (
        qw/ get put reload back request follow_link submit submit_form/)
    {

        # return 0; - ensures carries on to rest of parent method
        $pluggable->pre_hook( $method, sub { $_[0]->_sleep(); 0; } );
    }

    my $sleep
        = defined $args{sleep}
        ? $args{sleep}
        : $WWW::Mechanize::Pluggable::Sleepy || 0;

    _set_sleep( $pluggable, $sleep );
}


sub sleep {
    my ( $self, $arg ) = @_;
    _set_sleep( $self, $arg ) if defined $arg;
    return $self->{Sleepy_Time};
}

# sets sleep time and method
sub _set_sleep {
    my ( $self, $arg ) = @_;

    my $method;
    if ( !defined $arg ) {
        $method = sub { };
        
    } elsif ( my ( $from, $to ) = $arg =~ m/^(\d+)\.\.(\d+)$/ ) {
        croak "sleep range (i1..i2) must have i1 < i2"
            if $1 >= $2;
        $method
            = sub { CORE::sleep( int( rand( ( $to + 1 ) - $from ) ) + $from ) };
            
    } elsif ( $arg !~ m/\D/ ) {
        $method = sub { CORE::sleep($arg); };
        
    } else {
        croak "sleep parameter must be an integer or a range i1..i2";
    }

    $self->{Sleepy_Time}   = $arg;
    $self->{Sleepy_Method} = $method;
}

# performs sleep
sub _sleep {
    my ($self) = @_;
    $self->{Sleepy_Method}->();
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

WWW::Mechanize::Plugin::Sleepy - A WWW::Mechanize plugin to provide the behaviour of WWW::Mechanize::Sleepy while using WWW::Mechanize::Pluggable

=head1 VERSION

version 0.003

=head1 SYNOPSIS

Set all Mechanize objects to sleep for 5 seconds between requests:

    use WWW::Mechanize::Pluggable Sleepy => [ sleep => 5 ];

or, set single Mechanize instance to sleep for 5 seconds between requests:

    use WWW::Mechanize::Pluggable;
    
    my $mech = WWW::Mechanize::Pluggable->new( sleep => 5 );

To change sleep time:

    $mech->sleep(2);    # now sleep for 2 seconds per request

To sleep for a random number of seconds, specify the range as a string in the
following format:

    'i1..i2'
    
    # e.g. will sleep between 5 and 10 seconds, inclusive
    $mech->sleep('5..10');

=head1 DESCRIPTION

This module makes it easy to slow down L<WWW::Mechanize> when using
L<WWW::Mechanize::Pluggable>, in the manner of L<WWW::Mechanize::Sleepy>.

The code merely adds hooks containing a C<sleep()> before several
WWW::Mechanize methods, but is possibly preferable to scattering C<sleep()>s
throughout code in order to slow down tests, for example.

=head1 METHODS

=head2 sleep

    $mech->sleep(1);
    $mech->sleep('5..10');
    
    my $sleep = $mech->sleep;

Get/set sleep time

=head1 ACKNOWLEDGEMENTS

Code and tests based on L<WWW::Mechanize::Sleepy>

=head1 SEE ALSO

=over 4

=item *

L<WWW::Mechanize::Sleepy>

=item *

L<WWW::Mechanize::Pluggable>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/mjemmeson/www-mechanize-plugin-sleepy/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mjemmeson/www-mechanize-plugin-sleepy>

  git clone git://github.com/mjemmeson/www-mechanize-plugin-sleepy.git

=head1 AUTHOR

Michael Jemmeson <michael.jemmeson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Foxtons Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
