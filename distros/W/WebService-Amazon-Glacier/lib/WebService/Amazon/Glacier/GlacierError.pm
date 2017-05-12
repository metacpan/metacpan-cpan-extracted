use strict;
package WebService::Amazon::Glacier::GlacierError;
{
  $WebService::Amazon::Glacier::GlacierError::VERSION = '0.001';
}
use Moose;
use 5.010;

# ABSTRACT: This class encompasses Glacier errors.

has 'error_code' => (
    is       => 'rw',
    isa      => 'Int',
    required => 1,
    );

has 'error_message' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    );

sub BUILD{

}

1;

__END__

=pod

=head1 NAME

WebService::Amazon::Glacier::GlacierError - This class encompasses Glacier errors.

=head1 VERSION

version 0.001

=for Pod::Coverage BUILD

=head1 AUTHOR

Charles A. Wimmer <charles@wimmer.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Charles A. Wimmer.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
