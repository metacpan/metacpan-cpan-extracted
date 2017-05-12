package WWW::AdServer::Database::YAML;
{
  $WWW::AdServer::Database::YAML::VERSION = '1.01';
}
use Moo::Role;
use 5.010;

use YAML ();
use Data::Dumper    qw(Dumper);
use List::Util      qw(shuffle);
use List::MoreUtils qw(none);
use Time::Local     qw(timelocal);

has data => (
    is  => 'rw',
    isa => sub { die "$_[0] is not a refernce to a hash" unless ref $_[0] eq 'HASH' },
);

sub load {
    my ($self, $path) = @_;
    my $data =  YAML::LoadFile($path);

	# TODO some tool to return the entries where the dead-line passed
	my @valid_ads;
	my $now = time;
	foreach my $ad (@{ $data->{ads} }) {
        if ($ad->{end_date}) {
            my ($year, $month, $day) = split /-/, $ad->{end_date};
            eval {
                $ad->{end_date} = timelocal(59, 59, 23, $day, $month-1, $year-1900);
            };
            if ($@) {
                #print STDERR "$ad->{text}\n";
                #print STDERR "$ad->{end_date}\n";
                #print STDERR "$@\n";
                $ad->{end_date} = 0;
            }
			next if $ad->{end_date} < $now;
		}
		push @valid_ads, $ad;
	}
	$data->{ads} = \@valid_ads;
    $self->data( $data );

    return;
}

sub count_ads {
    my ($self) = @_;
    return scalar @{ $self->data->{ads} };
}

sub get_ads {
	my ($self, %args) = @_;
	my @ads;
	my @all_ads = @{ $self->data->{ads} };
	if ($args{shuffle}) {
		@all_ads = shuffle @all_ads;
	}
	for my $ad (@all_ads) {
		#warn Dumper $ad;
		if ($args{country}) {
			next if $ad->{countries} and none {$args{country} eq $_} @{ $ad->{countries} };
		}
		if (defined $args{limit}) {
			last if $args{limit} <= 0;
			$args{limit}--;
		}
		push @ads, $ad;
	}

	return \@ads;
}


1;

__END__

=pod

=head1 NAME

WWW::AdServer::Database::YAML

=head1 VERSION

version 1.01

=head1 AUTHOR

Gabor Szabo <szabgab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
