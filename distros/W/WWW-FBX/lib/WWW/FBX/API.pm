package WWW::FBX::API;
use 5.014001;
use Moose();
use Carp::Clan qw/^(?:WWW::FBX|Moose|Class::MOP)/;
use Moose::Exporter;
use URI::Escape;

use namespace::autoclean;

Moose::Exporter->setup_import_methods(
    with_caller => [ qw/api_url fbx_api_method/ ],
);

my $_api_url;

sub api_url { $_api_url = $_[1]; }

sub fbx_api_method {
    my $caller = shift;
    my $name   = shift;
    my %options = (
        @_,
    );
    my $args;

    #Remove trailing _
    $name =~ s/_$//;

    my $class = Moose::Meta::Class->initialize($caller);

    my ($arg_names, $all_args) = @options{qw/required params/};

    my $code = sub {
        my $self = shift;
        my $args = ref $_[-1] eq 'HASH' ? { %{pop @_} } : {};

        croak sprintf "$name expected %d args", scalar @$all_args if @_ > @$all_args;

        # promote positional args to named args
        for ( my $i = 0; @_; ++$i ) {
            my $param = $all_args->[$i];
            croak "duplicate param $param: both positional and named"
                if exists $args->{$param};

            $args->{$param} = shift;
        }

        for my $arg (keys %$args) {
            unless ( grep { $_ eq $arg } @$all_args ) {
                die "Unknown argument $arg for $name\n" , "Description:$options{description}" ,
                    "Params:", join(",",@$all_args), "\nRequired:", join(",", @$arg_names), "\n" ;
            }
        }

        for my $req (@$arg_names) {
            unless ( grep { $_ eq $req } keys %$args or !defined ($args->{req}) ) {
                die "Missing required param $req for $name\n", "Description:$options{description}" ,
                    "Params:", join(",",@$all_args), "\nRequired:", join(",", @$arg_names), "\n" ;
            }
        }
        my $path = $options{path};
        $path .= delete $args->{suff} if exists $args->{suff};

        my $uri = URI->new( $self->base_url . "$_api_url/$path");

        return $self->_json_request(
            $options{method},
            $uri,
            $args,
            $options{content_type}
        );
    };
    #Add method with name and Class::MOP::Method
    $class->add_method(
        $name,
        WWW::FBX::Meta::Method->new(
            name         => $name,
            package_name => $caller,
            body         => $code,
            %options,
        ),
    );

}

package WWW::FBX::Meta::Method;
use Moose;
use Carp::Clan qw/^(?:WWW::FBX|Moose|Class::MOP)/;
extends 'Moose::Meta::Method';

use namespace::autoclean;

has description     => ( isa => 'Str', is => 'ro', required => 1 );
has path            => ( isa => 'Str', is => 'ro', required => 1 );
has method          => ( isa => 'Str', is => 'ro', default => 'GET' );
has params          => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has required        => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has returns         => ( isa => 'Str', is => 'ro', predicate => 'has_returns' );
has content_type    => ( isa => 'Str', is => 'ro', default => '' );
has suff            => ( isa => 'Str', is => 'ro', default => '' );

#Build hash where keys are attribute names
my %valid_attribute_names = map { $_->init_arg => 1 }
                            __PACKAGE__->meta->get_all_attributes;

sub new {
    my $class = shift;
    my %args  = @_;

    #Stack arguments that are not expected attributes
    my @invalid_attributes = grep { !$valid_attribute_names{$_} } keys %args;
    croak "unexpected argument(s): @invalid_attributes" if @invalid_attributes;

    #Create method
    $class->SUPER::wrap(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::FBX::API - Freebox API sugar

=head1 SYNOPSIS

    use WWW::FBX::API;

=head1 DESCRIPTION

WWW::FBX::API is API sugar

=head1 LICENSE

Copyright (C) Laurent Kislaire.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Laurent Kislaire E<lt>teebeenator@gmail.comE<gt>

=cut

