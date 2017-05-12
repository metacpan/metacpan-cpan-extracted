package ZMQ::FFI::Versioner;
$ZMQ::FFI::Versioner::VERSION = '1.11';
use Moo::Role;

use ZMQ::FFI::Util qw(zmq_version);

requires q(soname);

has _version_parts => (
    is      => 'ro',
    lazy    => 1,
    default => sub { [zmq_version($_[0]->soname)] }
);

sub version {
    return @{$_[0]->_version_parts};
}

sub verstr {
    return join('.', $_[0]->version);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQ::FFI::Versioner

=head1 VERSION

version 1.11

=head1 AUTHOR

Dylan Cali <calid1984@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Dylan Cali.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
