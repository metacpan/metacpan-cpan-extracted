package Transform::Alert::Output::SNMP;

our $VERSION = '1.00'; # VERSION
# ABSTRACT: Transform alerts to SNMP traps (base class)

use sanity;
use Moo;
use MooX::Types::MooseLike::Base qw(InstanceOf Maybe);

use Net::SNMP;

with 'Transform::Alert::Output';

has _session => (
   is        => 'rw',
   isa       => Maybe[InstanceOf['Net::SNMP']],
   lazy      => 1,
   default   => sub {
      my $self = shift;
      my ($session, $err) = Net::SNMP->session( %{$self->connopts} );
      unless ($session) {
         $self->log->error('SNMP Session failed: '.$err);
         return;
      }
      return $session;
   },
   predicate => 1,
   clearer   => 1,
);

sub open   {
   my $self = shift;
   $self->_session ||
      # maybe+default+error still creates an undef attr, which would pass an 'exists' check on predicate
      do { $self->_clear_session; return; };
}
sub opened { shift->_has_session; }
sub send   { die "Dummy method send() called for Output::SNMPTrap!  This must be overloaded!"; }
sub close  {
   my $self = shift;

   if ($self->_has_session) {
      $self->_session->close;
      $self->_clear_session;
   }

   return 1;
}

sub _translate_msg {
   my ($self, $msg) = @_;
   $msg = $$msg if (ref $msg eq 'SCALAR');

   $msg =~ s/^\s+|\s+$//g;  # remove leading/trailing ws

   return [ map { split /\s+/, $_, 3 } split /[\r\n]+/, $msg ];
}

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Transform::Alert::Output::SNMP - Transform alerts to SNMP traps (base class)

=head1 SYNOPSIS

    # In your configuration
    <Output test>
       Type          SNMP::*
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

This is actually a base class.  You should use one of the other sub-classes of this, as this class doesn't actually send anything.

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
