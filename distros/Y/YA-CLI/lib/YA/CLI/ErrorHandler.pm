package YA::CLI::ErrorHandler;
our $VERSION = '0.007';
use Moo;
use namespace::autoclean;

# ABSTRACT: The default action handler

with 'YA::CLI::ActionRole';

sub action { 'default' }

sub run {
    my $self = shift;
    my $h = $self->as_help(1, $self->message);
    return $h->run;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

YA::CLI::ErrorHandler - The default action handler

=head1 VERSION

version 0.007

=head1 DESCRIPTION

This fallback action handler for if there isn't an action handler defined or
called.

=for Pod::Coverage action run message

=head1 METHODS

It implements all the methods defined in L<YA::CLI::ActionRole>.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
