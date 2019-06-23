package eris::log::contexts;
# ABSTRACT: Discovery and access for context objects

use List::Util qw(any);
use Ref::Util qw(is_ref is_arrayref is_coderef is_regexpref);
use Time::HiRes qw(gettimeofday tv_interval);
use Types::Standard qw( ArrayRef HashRef );

use Moo;
use namespace::autoclean;

with qw(
    eris::role::pluggable
);

our $VERSION = '0.008'; # VERSION


sub _build_namespace { 'eris::log::context' }


my $_lookup;
sub contextualize {
    my ($self,$log) = @_;

    my %t = ();
    foreach my $ctxt ( @{ $self->plugins } ) {
        my $field   = $ctxt->field;
        my $matcher = $ctxt->matcher;

        # Initialize to the catchall condition
        my $matched = $field eq '*' && $matcher eq '*';

        if( !$matched ) {
            # log context maybe updated
            my %c  = %{ $log->context };

            if( $field eq '_exists_' ) {
                # match against the key space
                if( !is_ref($matcher) ) {
                    # simplest case string
                    $matched = exists $c{$matcher};
                }
                elsif( is_regexpref($matcher) ) {
                    # regexp match
                    $matched = any { /$matcher/ } keys %c;
                }
                elsif( is_arrayref($matcher) ) {
                    # list match
                    $matched = any { exists $c{$_} } @{ $matcher };
                }
            }
            elsif( exists $c{$field} ) {
                if( !is_ref($matcher) ) {
                    # Simplest case, we're a string
                    $matched = lc $c{$field} eq lc $matcher;
                }
                elsif( is_regexpref($matcher) ) {
                    # regexp match
                    $matched = $c{$field} =~ /$matcher/;
                }
                elsif( is_arrayref($matcher) ) {
                    # list match
                    $matched = any { lc $c{$field} eq lc $_ } @{ $matcher };
                }
                elsif( is_coderef($matcher) ) {
                    # call the code ref
                    eval {
                        $matched = $matcher->( $c{$field} );
                        1;
                    } or do {
                        # Catch an exception in the matcher
                        my $err = $@;
                        warn sprintf "[%s] matcher coderef died: %s",
                            $ctxt->name, $err;
                    };
                }
            }
        }
        if( $matched ) {
            my $t0 = [gettimeofday];
            $ctxt->contextualize_message($log);
            my $tdiff = tv_interval($t0);
            my $name = sprintf "context::%s", $ctxt->name;
            $t{$name} = $tdiff;
        }
    }

    # Record timing data
    $log->add_timing(%t);

    return $log;      # Return the log object
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::contexts - Discovery and access for context objects

=head1 VERSION

version 0.008

=head1 SYNOPSIS

This module isn't meant to be a public interface, you should probably see:
L<eris::log::contextualizer> so you're doing it right.

=head1 ATTRIBUTES

=head2 namespace

Defaults to 'eris::log::context', add more by setting C<search_path> in your
config.

    ---
    contexts:
      search_path:
        - 'my::app::context'

=head1 METHODS

=head2 contextualize

Takes an instance of an L<eris::log> object that's been returned from a
a call to L<eris::log::decoders>'s C<decode()> method.

Discovers and iterates through available contexts.  Any contexts which
successfully match will be passed the L<eris::log> instance to their
C<contextualize_message> method.

=head1 SEE ALSO

L<eris::log::contextualizer>, L<eris::role::context>, L<eris::log>,
L<eris::log::contexts::sshd>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
