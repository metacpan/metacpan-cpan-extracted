package Test::Sweet::Runnable;
BEGIN {
  $Test::Sweet::Runnable::VERSION = '0.03';
}
# ABSTRACT: C<MooseX::Runnable> support for Test::Sweet classes
use Moose::Role;
use namespace::autoclean;

use Test::More;
use Try::Tiny;

with 'MooseX::Runnable';

eval {
    require MooseX::Getopt;
    with 'MooseX::Getopt';
};

sub run {
    my $self = shift;
    my @tests = $self->meta->get_all_tests;
    plan tests => scalar @tests; # so you get a "progress bar"
    try {
        $self->$_ for @tests;
    }
    catch {
        if( blessed $_ && $_->can('does') && $_->does('Test::Sweet::Exception') ){
            diag "Test '". $_->method. "' in '". $_->class. "' failed". (
              $_->isa('Test::Sweet::Exception::FailedMethod')               ?
                ' by throwing an exception' :
              $_->isa('Test::Sweet::Exception::FailedMetatestConstruction') ?
                ' with an error in the metatest constructor' :
              ''). ": ". $_->error;
        }
        else {
            diag "Test died: $_";
        }

        die $_; # rethrow for the "harness"
    };
    return 0;
}

1;



=pod

=head1 NAME

Test::Sweet::Runnable - C<MooseX::Runnable> support for Test::Sweet classes

=head1 VERSION

version 0.03

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
