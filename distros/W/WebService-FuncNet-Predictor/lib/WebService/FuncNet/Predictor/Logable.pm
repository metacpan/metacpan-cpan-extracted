package WebService::FuncNet::Predictor::Logable;

=head1 NAME

WebService::FuncNet::Predictor::Logable

=head1 SYNOPSIS

Provides logging functionality as a Moose Role

    package WebService::FuncNet::Predictor::NewClass;

    use Moose;

    with 'WebService::FuncNet::Predictor::Logable';
    
    sub do_something {
        $self = shift;
        $self->debug('debug');
        $self->info('info');
    }

=cut

use Moose::Role;
use Log::Log4perl qw(:easy);

BEGIN {
    Log::Log4perl->easy_init({
            'level'  => $INFO,
            'layout' => '[%5r] %5L:%-30c | %-20m%n',
        });
}

####
# The following was copied from MooseX::Log::Log4perl
# (I wanted to add the 'handles' and didn't have time
# to implement meta-poking)
####

has 'logger' => (
    is      => 'rw',
    isa     => 'Log::Log4perl::Logger',
    lazy    => 1,
    default => sub { my $self = shift; return Log::Log4perl->get_logger(ref($self)) },
    handles => [qw( debug info warn error fatal )],
);

1; # Magic true value required at end of module
__END__


=head1 SEE ALSO

L<Log::Log4perl>, L<MooseX::Log::Log4perl::Easy>

=head1 AUTHOR

Ian Sillitoe  C<< <sillitoe@biochem.ucl.ac.uk> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Ian Sillitoe C<< <sillitoe@biochem.ucl.ac.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 REVISION INFO

  Revision:      $Rev: 62 $
  Last editor:   $Author: isillitoe $
  Last updated:  $Date: 2009-07-06 16:01:23 +0100 (Mon, 06 Jul 2009) $

The latest source code for this project can be checked out from:

  https://funcnet.svn.sf.net/svnroot/funcnet/trunk

=cut
