package Transform::Alert::Output::SNMP::Set;

our $VERSION = '1.00'; # VERSION
# ABSTRACT: Transform alerts to SNMP set requests

use sanity;
use Moo;

extends 'Transform::Alert::Output::SNMP';

sub send {
   my ($self, $msg) = @_;
   my $snmp = $self->_session || return;
   
   $snmp->set_request(
      -varbindlist => $self->_translate_msg($msg),
   ) || do {
      $self->log->error('Error sending SNMP set request: '.$snmp->error);
      return;
   };
   
   return 1;
}

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Transform::Alert::Output::SNMP::Set - Transform alerts to SNMP set requests

=head1 SYNOPSIS

    # In your configuration
    <Output test>
       Type          SNMP::Set
       TemplateFile  outputs/test.tt
 
       # See Net::SNMP->new
       <ConnOpts>
          Hostname      snmp.foobar.org
          Port          161  # default
          Version       1    # default
          Community     public  # default
          # ...etc., etc., etc...
 
          # NonBlocking - DO NOT USE!
       </ConnOpts>
    </Output>

=head1 DESCRIPTION

This output type will send a SNMP set request for each converted input.  See L<Net::SNMP> for a list of the ConnOpts section parameters.

=head1 OUTPUT FORMAT

Output templates should use the following format:

    1.3.6.1.2.#.#.#.#  #  Value, blah blah blah...
    1.3.6.1.2.#.#.#.#  #  Value, blah blah blah...

In other words, each line is a set of varbinds.  Within each line is a set of 3 values, separated by whitespace:

=over

=item *

OID

=item *

Object Type (numeric form)

=item *

Value

=back

A list of object types can be found L<here|https://metacpan.org/source/Net::SNMP::Message#L75>.

=head1 TODO

Use L<Net::SNMPu>, when that gets released...

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Transform-Alert/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Transform::Alert/>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
