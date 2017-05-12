package XAS::Logmon::Output::Spool;

our $VERSION = '0.01';

use XAS::Factory;
use Try::Tiny::Retry ':all';

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  mixin      => 'XAS::Lib::Mixins::Handlers',
  utils      => ':validation',
  constants  => 'TRUE FALSE',
  accessors  => 'spool',
  filesystem => 'Dir',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub put {
    my $self = shift;
    my ($data) = validate_params(\@_, [1]);

    retry {

        $self->spool->write($data);

    } delay_exp {

        30, 1000    # attempts, delay in milliseconds

    } retry_if {

        my $ex = $_;
        my $ref = ref($ex);

        if ($ref && $ex->isa('XAS::Exception')) {

            return TRUE if ($ex->match_type('xas.lib.modules.spool'));

        }

        return FALSE;

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);

    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'spool'} = XAS::Factory->module('spool', {
        -directory => Dir($self->env->spool, 'logs'),
        -lock      => Dir($self->env->spool, 'logs', 'locked')->path
    });

    return $self;

}

1;

__END__

=head1 NAME

XAS::Logmon::Output::Spool - An output class for log file manipulation

=head1 SYNOPSIS

 use XAS::Logmon::Output::Spool;

  my $spool = XAS::Logmon::Output::Spool->new();

  $spool->put($data);

=head1 DESCRIPTION

This package will write data to a spool directory.

=head1 METHODS

=head2 put($data)

This method will write the data to a spool directory.

=over 4

=item B<$data>

The data to write out.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Logmon|XAS::Logmon>

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
