package WWW::YNAB::ModelHelpers;
our $AUTHORITY = 'cpan:DOY';
$WWW::YNAB::ModelHelpers::VERSION = '0.02';

use 5.010;
use Moose::Role;

sub model_from_data {
    my $self = shift;
    my ($class, $data, $server_knowledge) = @_;

    my @init_args = grep {
        $_ !~ /^_/
    } map {
        $_->init_arg
    } $class->meta->get_all_attributes;

    my %args = map {
        $_ => $data->{$_}
    } grep {
        exists $data->{$_}
    } @init_args;

    if (defined $server_knowledge) {
        $args{server_knowledge} = $server_knowledge;
    }

    $class->new(%args, _ua => $self->_ua);
}

no Moose::Role;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::YNAB::ModelHelpers

=head1 VERSION

version 0.02

=for Pod::Coverage   model_from_data

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
