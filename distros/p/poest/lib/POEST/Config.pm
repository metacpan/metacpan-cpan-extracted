# $Id: Config.pm,v 1.3 2003/04/08 00:27:30 cwest Exp $
package POEST::Config;

use strict;
$^W = 1;

use vars qw[$VERSION];
$VERSION = (qw$Revision: 1.3 $)[1];

sub new {
	my ($class, %args) = @_;
	
	return bless \%args, $class;
}

sub config {
	my ($self) = @_;

	return $self;
}

sub get {
	my ($self, @configs) = @_;

	my %conf = ();
	foreach ( @configs ) {
		$conf{$_} = $self->{$_} if exists $self->{$_};
	}

	return \%conf;
}

sub set {
	my ($self, %set) = @_;
	
	my @keys = keys %set;
	
	@{$self}{@keys} = @set{@keys};
}

1;

__END__

=pod

=head1 NAME

POEST::Config - Details of Writing a POEST Configurator

=head1 ABSTRACT

Details for writing a plugin configurator.

=head1 DESCRIPTION

poest needs to be configured.  Yes folks, that means writing (or at
least editing) a configuration of some sort.  I say "of some sort"
because there may be lots of different approaches to configuration.
This is the default configuration method.  This is also the
reference implementation.

=head2 Conventions

=head3 Package setup

Configuration modules are really classes.  Yes, classes.  An object
instance is created and used to get configuration sets.  There are
a certain number of methods a configuration must provide, as well
as a certain functionality, described below.

The actual setup and type of configuration that a class accepts is
completley out in the open.  The most common is a configuration file.
There are many more avenues that can be explored, some much more useful
than a configuration file.  Consider storing configuration in a
database or LDAP directory.  Perhaps in a DBM file or something else
all together.  It's up to you.

=head3 Functionality

Plugins need to have a couple of ways to represent configuration
information.  First is a single key/value pair.  Second is a
slightly more complex key/list of values.  A plugin configurator
must provide both options.  As an example configuration file.

  # key/value
  Port 25
  
  # key/list of values
  Plugin POEST::Plugin::Queue::DiskHash
  Plugin POEST::Plugin::Deliver::Local

These configuration options should boil down to a data structure such
as this.

  {
    port   => 25,
    plugin => [
                'POEST::Plugin::Queue::DiskHash',
                'POEST::Plugin::Deliver::Local',
              ],
  };

Note that the keys, or configuration parameter names, have been
lower-cased in the data structure.  This was on purpose, because it
should always happen.

=head3 Public method API

The public API for configuration classes is pretty well set.  After all,
it is only used in one place, server initialization.

=over 4

=item new()

C<new()> is the constructor.  Arguments are passed to C<new()> as a list
of key/value pairs.  Any arguments recieved by C<new()> were what was
passes directly to C<POEST::Server-E<gt>new()>.  Arguments must be validated
and checked for accuracy, and existence.  If something is wrong, an
exception should be thrown.  This will end the server initialization and
terminate the server so the problem can be fixed.

C<new()> returnes an instance object of your configuration class.

As this is a base class for poest configuration classes, we do provide
a simple constructor.

  sub new {
    my ($class, %args) = @_;

    return bless \%args, $self;
  }

This should be overriden, to at least include configuration checking.

  sub new {
    my $self = shift->SUPER::new( @_ );
    
    # .. do validation ..
    
    return $self;
  }

=item config()

This method returns the entire configuration data structure.  Useful
for serialization, should the need arise.  This data structure should
be returned as a hash reference as described previously in the section
on functionality.

Here is a simple example.

  sub config {
    my ($self) = @_;

    return $self;
  }

This very method is provided in this base class, and that's the very
reason it should be overriden.

=item get()

This method accepts a list of configuration parameters to get.  For all
that exist in the configuration, they will be returned as a hash
reference.  This is analigous to retrieving a slice of the configuration.

Here is the example in this base class.

  sub get {
    my ($self, @configs) = @_;
    
    my %conf = ();
    foreach ( @configs ) {
      $conf{$_} = $self->{$_} if exists $self->{$_};
    }
    
    return \%conf;
  }

Again, this method should be overriden in the sub-class.

=item set()

Now you too can set configuration parameters at run time.  This goes
against everything daemon methedology believes in, but then, it's also
useful.  There may be some odd and rather insane situations where you
want to set a configration parameter (or change an existing one) during
runtime.  It will not be serialized to the original source of
configuration, that's just going too far.  Instead it is a modification
of the in-memory copy.

Here is an example.

  sub set {
    my ($self, %set) = @_;

    my @keys = keys %set;

    @{$self}{@keys} = @set{@keys};
  }

This method is provided in the base class and should be overriden.

=back

=head1 AUTHOR

Casey West, <F<casey@dyndns.org>>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 DynDNS.org

You may distribute this package under the terms of either the GNU
General Public License or the Artistic License, as specified in the Perl
README file, with the exception that it may not be placed on physical
media for distribution without the prior written approval of the author.

THIS PACKAGE IS PROVIDED WITH USEFULNESS IN MIND, BUT WITHOUT GUARANTEE
OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. USE IT AT YOUR
OWN RISK.

For more information, please visit http://opensource.dyndns.org

=head1 SEE ALSO

L<perl>, L<POEST::Server>, L<POEST::Config::General>.

=cut
