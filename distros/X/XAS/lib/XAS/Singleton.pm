package XAS::Singleton;

our $VERSION = '0.01';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  constants => 'HASH',
;

# ----------------------------------------------------------------------
# Here be the best of cut-and-paste programming. This combines 
# the guts of Class::Singleton with Badger::Base to make singletons!
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub new {
    my $class = shift;

    # already got an object

    return $class if ref $class;

    # we store the instance in the _instance variable in the $class package.

    no strict 'refs';
    my $instance = \${ "$class\::_instance" };

    defined $$instance
      ? $$instance
      : ($$instance = $class->_new_instance(@_));

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _new_instance {
    my $class = shift;

    # install warning handling for odd number of parameters when DEBUG enabled

    local $SIG{__WARN__} = sub {
        Badger::Utils::odd_params(@_);
    } if DEBUG;

    my $args = @_ && ref $_[0] eq HASH ? shift : { @_ };
    my $self = bless { }, ref $class || $class;

    $self = $self->init($args);

    # be careful to account for object that overload the boolean comparison
    # operator and may return false to a simple truth test.

    return defined $self
      ? $self
      : $self->error("init() method failed\n");

}

1;

__END__

=head1 NAME

XAS::Singleton - A singleton class for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   version => '0.01'
   base    => 'XAS::Singleton'
 ;

=head1 DESCRIPTION

There can only be one... A singleton class for the XAS environment. 

=head1 METHODS

=head2 new

Initalize the class. 

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
