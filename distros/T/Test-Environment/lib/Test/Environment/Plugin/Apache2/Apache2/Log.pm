package Test::Environment::Plugin::Apache2::Apache2::Log;

our $VERSION = "0.07";

1;

package Apache2::Log;

=head1 NAME

Test::Environment::Plugin::Apache2::Apache2::Log - fake Apache2::Log for Test::Environment

=head1 SYNOPSIS

    use Test::Environment qw{
        Apache2
    };

    $request->log->info('no info');

=head1 DESCRIPTION

Will add log method to the Apache2::RequestRec. 

=cut

use warnings;
use strict;

our $VERSION = "0.07";

use Log::Log4perl;


=head1 METHODS

=head2 Apache2::RequestRec::log

Returns Log::Log4perl::get_logger().

=cut

sub Apache2::RequestRec::log {
    my $self   = shift;
    
    return Log::Log4perl::get_logger();
}


'tdtdddddt';

__END__

=head1 AUTHOR

Jozef Kutej

=cut
