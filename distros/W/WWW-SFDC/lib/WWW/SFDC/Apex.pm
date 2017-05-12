#!/usr/bin/env perl
package WWW::SFDC::Apex;
# ABSTRACT: Interface to the salesforce.com Apex SOAP Api

use 5.12.0;
use strict;
use warnings;

our $VERSION = '0.37'; # VERSION

use Log::Log4perl ':easy';
use Method::Signatures;
use SOAP::Lite;

use WWW::SFDC::Apex::ExecuteAnonymousResult;

use Moo;
with "WWW::SFDC::Role::SessionConsumer";

has 'uri',
    is => 'ro',
    default=> "http://soap.sforce.com/2006/08/apex";

sub _extractURL {
    # NB that the // are part of the pattern
    return $_[1]->{serverUrl} =~ s{/u/}{/s/}r;
}



sub compileAndTest () {
  ...
}


sub compileClasses {
  ...
}


sub compileTriggers {
  ...
}


method executeAnonymous ($code, :$debug = 1) {

  my $callResult = $self->_call(
    'executeAnonymous',
    SOAP::Data->name(string => $code),
    (
      $debug
        ? SOAP::Header->name('DebuggingHeader' => \SOAP::Data->name(
            debugLevel => 'DEBUGONLY'
          ))->uri($self->uri)
        : ()
    ),
  );

  return WWW::SFDC::Apex::ExecuteAnonymousResult->new(
    _result => $callResult->result,
    _headers => $callResult->headers
  );
}


sub runTests {
  ...
}


sub wsdlToApex {
    ...
}

1;

__END__

=pod

=head1 NAME

WWW::SFDC::Apex - Interface to the salesforce.com Apex SOAP Api

=head1 VERSION

version 0.37

=head1 METHODS

=head2 compileAndTest

=head2 compileClasses

=head2 compileTriggers

=head2 executeAnonymous

Returns a WWW::SFDC::Apex::ExecuteAnonymousResult containing the results of the
executeAnonymous call. You must manually check whether this succeeded.

=head2 runTests

=head2 wsdlToApex

=head1 WARNING

The only implemented method from the Apex API is currently executeAnonymous.
Without a solid use-case for the other methods, I'm not sure what the return
values of those calls should be.

If you want to implement those calls, please go ahead, constructing results
as you see fit, and submit a pull request!

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
