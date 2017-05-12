package WebService::Shutterstock::DeferredData;
{
  $WebService::Shutterstock::DeferredData::VERSION = '0.006';
}

# ABSTRACT: Utility class for easy lazy-loading from the API

use strict;
use warnings;
use Sub::Exporter -setup => { exports => ['deferred'] };

sub deferred {
	my $target = caller;
	my $loader = pop;
	my @fields = @_;
	foreach my $f(@fields){
		my($src,$dst,$is);
		if(ref $f eq 'ARRAY'){
			($src,$dst,$is) = @$f;
		} else {
			($src,$dst,$is) = ($f, $f,'ro');
		}
		$is ||= 'ro';
		no strict 'refs';
		my $sub = $target . '::' . $dst;
		*$sub = sub {
			my $self = shift;
			unless ( exists $self->{$dst} ) {
				$self->load;
			}
			if($is eq 'rw' && @_){
				$self->{$dst} = shift;
			}
			return $self->{$dst};
		};
	}
	no strict 'refs';
	my $loader_target = $target . '::load';
	*$loader_target = sub {
		my $self = shift;
		my $data = $self->$loader;
		my @src  = map { ref $_ ? $_->[0] : $_ } @fields;
		my @dst  = map { ref $_ ? $_->[1] : $_ } @fields;
		@{$self}{@dst} = @{$data}{@src};
		return $self;
	};
	my $constructor_target = $target . '::new';
	my $original = \&{ $constructor_target };
	no warnings 'redefine';
	*$constructor_target = sub {
		my $class = shift;
		my %args  = @_;
		my $self = $class->$original(@_);
		foreach my $f(@fields){
			my($src,$dst);
			if(ref $f eq 'ARRAY'){
				($src,$dst) = @$f;
			} else {
				($src,$dst) = ($f, $f);
			}
			if(!exists $self->{$dst} && exists $args{$src}){
				$self->{$dst} = $args{$src};
			}
		}
		return $self;
	};
}

1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::DeferredData - Utility class for easy lazy-loading from the API

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This utility class simply enables us to load some fields in a lazy fashion.

You should not need to use this class in order to use L<WebService::Shutterstock>.

=for Pod::Coverage deferred

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
