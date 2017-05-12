package XAS::Base;

our $VERSION = '0.06';
our $EXCEPTION = 'XAS::Exception';

use XAS::Factory;
use XAS::Exception;

use XAS::Class
  debug    => 0,
  version  => $VERSION,
  base     => 'Badger::Base',
  utils    => ':validation xprintf dotid',
  import   => 'class',
  auto_can => '_auto_load',
  vars => {
    PARAMS => {
      -xdebug => { optional => 1, default => 0 }
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Overrides
# ----------------------------------------------------------------------

class('Badger::Base')->methods(
    message => sub {
        my $self = shift;
        my $name = shift
          || $self->fatal("message() called without format name");

        my $m1 = XAS::Base->env->get_msgs;
        my $m2 = $self->class->all_vars('MESSAGES');

        foreach my $h (@$m2) {

            while (my ($key, $value) = each(%$h)) {

                $m1->{$key} = $value;

            }

        }

        $self->class->var('MESSAGES', $m1);

        my $format = $self->class->hash_value('MESSAGES', $name)
          || $self->fatal("message() called with invalid message type: $name");

        xprintf($format, @_);

    }
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _auto_load {
    my $self = shift;
    my $name = shift;

    if ($name eq 'alert') {

        return sub { XAS::Factory->module('alert'); } 

    } elsif ($name eq 'email') {

        return sub { XAS::Factory->module('email'); } 

    } elsif ($name eq 'log') {

        return sub { XAS::Factory->module('logger'); } 

    } elsif ($name eq 'env') {

        return sub { XAS::Factory->module('environment'); }

    }

    my ($package, $filename, $line) = caller(2);
    $self->throw_msg(
        dotid($self->class) . '.auto_load.invmethod',
        'invmethod',
        $name, $filename, $line
    );

}

sub _create_methods {
    my $self = shift;
    my $p = shift;

    no strict "refs";               # to register new methods in package
    no warnings;                    # turn off warnings

    while (my ($key, $value) = each(%$p)) {

        $self->{$key} = $value;

        *$key = sub {
            my $self = shift;
            return $self->{$key};
        };

    }

}

sub init {
    my $self = shift;

    # process PARAMS

    my $class = $self->class;
    my $params = $self->class->hash_vars('PARAMS');
    my $p = validate_params(\@_, $params, $class);

    # build our object

    $self->{'config'} = $p;
    $self->_create_methods($p);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Base - The base class for the XAS environment

=head1 SYNOPSIS

 our $VERSION = '0.01';

 use XAS::Class
   debug   => 0,
   version => $VERSION,
   base    => 'XAS::Base',
   vars => {
       PARAMS => {}
   }
 ;

=head1 DESCRIPTION

This module defines a base class for the XAS Environment and inherits from
L<Badger::Base|https://metacpan.org/pod/Badger::Base>. The package variable $PARAMS is used to hold 
the parameters that this class uses for initialization. Due to the pseudo 
inheritance of package variables provided by L<Badger::Class|https://metacpan.org/pod/Badger::Class>, these 
parameters can be changed or extended by inheriting classes. The parameters 
are validated using L<Params::Validate|https://metacpan.org/pod/Params::Validate>. Any parameters defined in $PARAMS 
auto-magically become accessors toward their values.

=head1 METHODS

=head2 new($parameters)

This is used to initialized the class. These parameters are validated using 
the validate_params() method. 

=head1 AUTOLOADING

Specific modules can be auto-loaded when a method name is invoked. The 
following methods have been defined:

=head2 alert

This will auto-load L<XAS::Lib::Modules::Alerts|XAS::Lib::Modules::Alerts>.
Please see that module for more details.

=head2 env

This will auto-load L<XAS::Lib::Modules::Environment|XAS::Lib::Modules::Environment>.
Please see that module for more details.

=head2 email

This will auto load L<XAS::Lib::Modules::Email|XAS::Lib::Modules::Email>.
Please see that module for more details.

=head2 log

This will auto load L<XAS::Lib::Log|XAS::Lib::Log>.
Please see that module for more details.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
