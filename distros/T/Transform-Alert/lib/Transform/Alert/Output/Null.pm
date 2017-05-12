package Transform::Alert::Output::Null;

our $VERSION = '1.00'; # VERSION
# ABSTRACT: Transform alerts to NULL space

use sanity;
use Moo;

with 'Transform::Alert::Output';

sub open   { 1 }
sub opened { 1 }
sub send   { 1 }
sub close  { 1 }

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Transform::Alert::Output::Null - Transform alerts to NULL space

=head1 SYNOPSIS

    # In your configuration
    <Output null>
       Type     Null
       Template ""
       <ConnOpts/>
    </Output>

=head1 DESCRIPTION

This output type is mainly used for testing.  It can have its uses to send messages to the bitbucket, though.

A Template can be specified here to test out how an Output gets filled in.  The resulting string will be found in the logs.

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
