package WWW::RobotRules::Memcache;

use strict;
use warnings;

use base 'WWW::RobotRules';

use Cache::Memcached;
use Carp;

our $VERSION = '0.1';

sub new  { 
    my ($class, @mem_nodes) = @_;
    if (! @mem_nodes) {
        Carp::croak('WWW::RobotRules::Memcache servers required')
    }
    my $self = bless { }, $class;
	$self->{'memd'} = Cache::Memcached->new({
        'servers' => [ @mem_nodes ],
    });
    return $self;
}

sub no_visits {
    my ($self, $netloc) = @_;
    my $t = $self->{'memd'}->get("$netloc|vis");
    if (! $t) { return 0; }
    return ( split( /;\s*/, $t ) )[0];
}

sub last_visit {
    my ($self, $netloc) = @_;
    my $t = $self->{'memd'}->get("$netloc|vis");
    if (! $t) { return 0; }
    return ( split( /;\s*/, $t ) )[1];
}

sub fresh_until {
    my ($self, $netloc, $fresh) = @_;
    my $old = $self->{'memd'}->get("$netloc|exp");
    if ($old) {
        $old =~ s/;.*//;
    }
    if (defined $fresh) {
	    $fresh .= "; " . localtime($fresh);
	    $self->{'memd'}->set("$netloc|exp", $fresh);
    }
    return $old;
}

sub visit {
    my($self, $netloc, $time) = @_;
    $time ||= time;

    my $count = 0;
    my $old = $self->{'memd'}->get("$netloc|vis");
    if ($old) {
	    my $last;
	    ($count,$last) = split(/;\s*/, $old);
	    if ($last > $time) { $time = $last; }
    }
    $count++;
    $self->{'memd'}->set("$netloc|vis", "$count; $time; " . localtime($time));
    return 1;
}

sub push_rules {
    my($self, $netloc, @rules) = @_;
    my $cnt = 1;
    while ($self->{'memd'}->get("$netloc|r$cnt")) {
	    $cnt++;
    }
    foreach my $rule (@rules) {
        $self->{'memd'}->set("$netloc|r$cnt", $rule);
	    $cnt++;
    }
    return 1;
}

sub clear_rules {
    my ($self, $netloc) = @_;
    my $cnt = 1;
    while ($self->{'memd'}->get("$netloc|r$cnt")) {
	    $self->{'memd'}->delete("$netloc|r$cnt");
	    $cnt++;
    }
    return 1;
}

sub rules {
    my($self, $netloc) = @_;
    my @rules = ();
    my $cnt = 1;
    while (my $rule = $self->{'memd'}->get("$netloc|r$cnt")) {
        push @rules, $rule;
        $cnt++;
    }
    return @rules;
}

1;
__END__

=pod

=head1 NAME

WWW::RobotRules::Memcache - Use memcached in conjunction with WWW::RobotRules

=head1 SYNOPSIS

  use WWW::RobotRules::Memcache;

  my @memcache_servers = ('localhost:11211', '192.168.100.3:11211');

  my $rules = WWW::RobotRules::Memcache->new(@memcache_servers);
  my $ua = WWW::RobotUA->new('my-robot/1.0', 'me@foo.com', $rules);

  # Then just use $ua as usual
  $res = $ua->request($req);

=head1 DESCRIPTION

This is a subclass of WWW::RobotRules that uses Cache::Memcache to implement
persistent caching of robots.txt and host visit information.

=head1 FUNCTIONS

=head2 new(server [, server ..])

When creating this object you must pass at least one memcache server.

=head1 AUTHOR

Nick Gerakines, C<< <nick at gerakines.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-robotrules-cache at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-RobotRules-Cache>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::RobotRules::Cache

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-RobotRules-Cache>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-RobotRules-Cache>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-RobotRules-Cache>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-RobotRules-Cache>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
