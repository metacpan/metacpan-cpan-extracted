#
# Copyright (c) 2001-2003
# Giulio Motta, Ivo Marino All rights reserved.
#
# http://www-sms.sourceforge.net/
# 
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# 

package WWW::SMS;

use strict;
no strict 'refs';
use vars qw($VERSION $Error);

$VERSION = '0.09';

use Telephone::Number;

my %RELIABILITY = (
    Omnitel       => 95, # Italian Gateway
    Libero        => 90, # Italian Gateway
    Everyday      => 85, # Italian Gateway
    Gomobile      => 80, # Swiss Gateway
    Enel          => 70, # Italian Gateway
    Vizzavi       => 50,
    SFR           => 50, # French Gateway
    Beeline       => 50, # Russian Gateway
    MTS           => 50,
    LoopDE        => 50, # German Gateway
    GsmboxIT      => 20,
    GsmboxUK      => 20, # UK Gateway
    GsmboxDE      => -1,
    Clarence      =>  0,
    GoldenTelecom =>  0, # World Gateway
);

sub new {
    my ($self, $tn, $key, $value);
    my $class = shift;
    if ( (@_ > 2 ) && $_[2] =~ /^\d+$/) { # this suppose no %hash key is all numeric
        $tn = Telephone::Number->new(shift, shift, shift);
    } else {
        $tn = Telephone::Number->new(shift);
    }
    my ($smstext, %hash) = @_;
    $self = bless {
        'tn' => $tn,
        'whole_number' => $tn->whole_number(),
        'smstext' => $smstext,
        'cookie_jar' => exists $hash{cookie_jar} ? 
                        delete $hash{cookie_jar} : 
                        "lwpcookies.txt",
    }, $class;
    @{$self}{keys %{$tn}} = @{$tn}{keys %{$tn}};
    @{$self}{keys %hash} = @hash{keys %hash}; #dragonchild suggestion
    $self;
}

sub send {
    my ($sms, $gate) = @_;
    my @PREFIXES;
    my $gateway = "WWW::SMS::$gate";
    eval "use $gateway";
    if ($@) {
        $Error = "No such a gateway available: $gate ($@)";
        return;
    }
    @PREFIXES = @{ $gateway . '::PREFIXES' };
    if (@PREFIXES) {
        for (@PREFIXES) {
            return &{ $gateway . '::_send'} ($sms)
                if $sms->{tn}->fits($_);
        }
    } else {
        return &{ $gateway . '::_send' } ($sms);
    }
    $Error = "Telephone number $sms->{whole_number} not compatible with $gate gateway";
    return;         
}

sub send_sms { #for backward compatibility only
    my ($class, $sms, $gate) = @_;
    $sms->send($gate);
}

sub gateways {
    $_ = shift;
    my $sms = ref $_ ? $_ : undef;
    my %hash = @_;
    my (@gates, @realgates, @PREFIXES, %seen);
    my ($gate, $gateway);
    for (@INC) {
        opendir(DIR, "$_/WWW/SMS") || next;
            push @gates, grep {
                /^(.+)\.pm$/i and 
                !$seen{$1}++  and 
                $_ = $1
            } readdir(DIR);
        closedir(DIR);
    }
    if ($sms) {
        for $gate (@gates) {
            $gateway = "WWW::SMS::$gate";
            eval "use $gateway";
            print "$@" if ($@);
            @PREFIXES = @{ $gateway . '::PREFIXES' };
            if (@PREFIXES) {
                for (@PREFIXES) {
                    if ( $sms->{tn}->fits($_) ) {
                        push @realgates, $gate;
                        last;
                    }
                }
            } else {
                push @realgates, $gate;
            }
        }
        @gates = @realgates;
    }
    if (%hash and $hash{sorted} eq 'reliability') {
        @gates = sort {$RELIABILITY{$b} <=> $RELIABILITY{$a}} @gates;
    }
    return @gates;
}


1;

=head1 NAME

WWW::SMS - sends SMS using service provided by free websites

=head1 SYNOPSIS

    use WWW::SMS;
    my $sms = WWW::SMS->new(
        '39',                #international prefix
        '333',               #operator prefix
        '1234567',           #phone number
        'This is a test.',   #message text
        username => 'abcde', #optional parameters
        passwd => 'edcba'    #in hash fashion
    );

    #or now even just
    my $sms = WWW::SMS->new($whole_number, $smstext);
    
    for ( $sms->gateways(sorted => 'reliability') ) {
                                   #for every compatible gateway
        if ($sms->send( $_ ) {     #try to send sms
            last;                  #until it succeds
        } else {
            print $WWW::SMS:Error; #here is the error
        }
    }

=head1 DESCRIPTION

B<WWW::SMS> a Perl framework for sending free SMSs over the web.

A new B<WWW::SMS> object must be created with the I<new> method.
Once created you can send it through one of the available submodules.

=over

=item WWW::SMS->new(INTPREFIX, OPPREFIX, PHONE_NUMBER, MESSAGETEXT [, OPTIONS]);

=item WWW::SMS->new(WHOLE_NUMBER, MESSAGETEXT [, OPTIONS]);

This is the default SMS object constructor.

C<INTPREFIX> is the international prefix:
some gateways just don't use the international prefix, 
but put something in here anyway.

C<OPPREFIX> is the operator prefix

C<PHONE_NUMBER> not much to say

C<WHOLE_NUMBER> the alternative constructor use the
the whole number of your cellphone: it includes international prefix
and operator prefix. It relies on the database in I<Telephone::Number>
to split your number in its 3 basic parts.
So if unsure just use the "three-part-phone-number" constructor.

C<MESSAGETEXT> even here not much to say. Submodules are going to cut
the SMS to the maximum allowed length by the operator. You can check
anyway the maximum length directly looking for the I<MAXLENGTH> constant 
in submodules.

C<OPTIONS> are passed in a hash fashion. The useful ones to set include

=over

C<proxy> your HTTP proxy

C<cookie_jar> The file where to store cookies. If not set, every cookie goes
in the file "lwpcookies.txt" in your working directory.

C<username> and C<passwd> Used by registration based gateways

Other parameters may be required by specific submodules.

=back

=back


=head1 METHODS

=over

=item $sms->send(C<GATEWAY>)

Sends C<$sms> using C<GATEWAY>: returns I<1> if succesfull, I<0> if
there are errors. The last error is in the C<$WWW::SMS::Error> variable.

C<GATEWAY> the gateway you wish to use for sending the SMS: must be a scalar.

=item gateways([OPTIONS])

Scans @INC directories and returns an ARRAY containing the names
of the available gateway submodules. If used upon a SMS object
the submodules list returned is filtered by the PREFIX capability.
Like this:

   WWW::SMS->gateways(); #returns every available gateway

   $sms->gateways(); #returns just the gateways that can send $sms

   #compatible gateways sorted by reliability
   $sms->gateways(sorted => 'reliability');
   

=back

=head1 SUBMODULE GUIDELINES

So, now you got WWW::SMS but what's next? Well, all that's cool about it
resides in submodules. A submodule got to do the dirty work of GETting and
POSTing webpages.
How to write a submodule then?
There are a few points to observe:

=over

=item 1 Take a look at submodules provided as example first!

Yes, copying and pasting a submodule structure is a good start point.

=item 2 sub MAXLENGTH

Please set the EXPORTable constant C<MAXLENGTH> to what is the maximum length
of SMS the gateway you are scripting for allow.

=item 3 @PREFIXES

C<@PREFIXES> got to be an array of C<Telephone::Number> objects.
C<Telephone::Number>->new takes 3 parameters: each one can be a scalar
or an array reference.
Each scalar or element of referenced arrays is a regular expression.
Code will check for the phone number to match at least one of the regexp
for each of intpref, prefix and phone_number. If you don't have regexp
for one of these fields just give I<undef> to C<Telephone::Number>->new.
Take a look at other submodules to better make up your mind.

=item 4 Steps and $WWW::SMS::Error

Do GETs and POSTs as you want, using other submodules as you like.
Just remember to mark each GET or POST with a increasing step number.
And when you got an error please set the error variable C<$WWW::SMS::Error>
to something useful and include the step number in it, so debugging will
be easier. Then I<return 0>.
If everything goes alright just I<return 1>.

=item 5 Post your module back to the community!

That's important, cause having a high available number of working gateways
is difficult (websites keep changing pretty fast) so everybody should
share his/her new & cool submodules implementation. Thank you.

=back

=head1 COPYRIGHT

Copyright 2001-2003
Giulio Motta I<giulienk@cpan.org>
Ivo Marino I<eim@cpan.org>.

Project page at http://www-sms.sourceforge.net/

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
