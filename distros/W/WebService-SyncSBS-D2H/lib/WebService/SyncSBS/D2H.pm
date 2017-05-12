package WebService::SyncSBS::D2H;

use strict;
require Exporter;

our @ISA = qw(Exporter);
our $VERSION = '0.03';

use WebService::SyncSBS::Delicious;
use WebService::SyncSBS::Hatena;


sub new {
    my $class = shift;
    my $args  = shift;

    $args->{delicious_recent_num} = 20 unless $args->{delicious_recent_num} =~ /^\d+$/;
    $args->{delicious_recent_num} = 20 if $args->{delicious_recent_num} > 100;

    my $self = bless {
	delicious => WebService::SyncSBS::Delicious->new({
	    user => $args->{delicious_user},
	    pass => $args->{delicious_pass},
	    recent_num => $args->{delicious_recent_num},
							 }),
	hatena    => WebService::SyncSBS::Hatena->new({
	    user => $args->{hatena_user},
	    pass => $args->{hatena_pass},
	}),
    }, $class;

    return $self;
}

sub sync {
    my $self = shift;

    my $delicious = $self->{delicious}->get_recent;
    my $hatena = $self->{hatena}->get_recent;

    #del.icio.us to hatena
    foreach (keys %$delicious) {
	unless ($hatena->{$_}->{url}) {
	    $self->{hatena}->add($delicious->{$_});
	}
    }

    #hatena to del.icio.us
    foreach (keys %$hatena) {
	unless ($delicious->{$_}->{url}) {
	    $self->{delicious}->add($hatena->{$_});
	}
    }
}

sub add {
}

sub delete {
    my $self = shift;
    my $url  = shift;

    $self->{delicious}->delete($url);
    $self->{hatena}->delete($url);
}

1;
__END__
=head1 NAME

WebService::SyncSBS::D2H - del.icio.us and hatena bookmark sync

=head1 SYNOPSIS

  use WebService::SyncSBS::D2H;

  my $sbsync = WebService::SyncSBS::D2H->new({
    delicious_user => $delicious_user,
    delicious_pass => $delicious_pass,
    hatena_user => $hatena_user,
    hatena_pass => $hatena_pass,
    delicious_recent_num => $delicious_recent_num,
  });
  $sbsync->sync;

=head1 DESCRIPTION

 

=head2 EXPORT




=head1 SEE ALSO

examples/sbssync.pl

use Encode;
use HTTP::Request;
use XML::Atom;
use Net::Delicious;


=head1 AUTHOR

Kazuhiro Osawa  E<lt>ko@yappo.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
