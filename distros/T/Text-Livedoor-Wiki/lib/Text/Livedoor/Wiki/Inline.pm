package Text::Livedoor::Wiki::Inline;

use warnings;
use strict;
use UNIVERSAL::require;
use Text::Livedoor::Wiki::Utils;

sub new {
    my $class = shift;
    my $self  = shift;
    $self = bless $self, $class;
    my $plugins  = delete $self->{plugins};
    $self->_load( $plugins );
    $self->function->setup( $self );
    return $self;
}

sub function { shift->{function} }
sub _build_catchall {
    my $self = shift;

    my $regex
        = join( '|', map { '(' . $_->{regex} . ')' } @{ $self->{elements} } );
    return q{((?:.|^|$)+?(?=} . $regex . q{|$))};
}

sub _no_match {
    my ( $self, $char ) = @_;
    return Text::Livedoor::Wiki::Utils::escape($char);
}

sub parse {
    my $self  = shift;
    my $line  = shift;
    return '' unless defined $line;

    chomp($line);

    return '' if ( $line eq '' );

    my $catchall = {
        regex       => $self->_build_catchall,
        n_args      => 1,
        process     => \&_no_match,
    };

    my $formatted = '';

    do {
        for my $element ( @{$self->{elements}}, $catchall ) {
            if ( $line =~ m/\G($element->{regex})/gcis ) {
                $Text::Livedoor::Wiki::scratchpad->{core}{inline_uid}++;
                my $arg_idx = 0;
                my $matched = eval( q{$} . ( ++$arg_idx ) );
                my @args    = map { eval( q{$} . ( ++$arg_idx ) ) } ( 1 .. $element->{n_args} );
                $formatted .= &{$element->{process}}( $self, @args );
                last;
            }
        }
    } while ( pos($line) < length($line) );

    return $formatted;

}

sub on_mobile { shift->{on_mobile} }

sub _load {
    my $self    = shift;
    my $plugins = shift;
    $plugins = $self->_sort( $plugins );
    my @elements = ();
    for my $plugin (@$plugins) {
        my $element = {
            regex => $plugin->regex,
            n_args  => $plugin->n_args,
            process => sub { $self->on_mobile ? $plugin->process_mobile(@_) : $plugin->process(@_) } ,
        };
        push @elements , $element;
    }
    $self->{elements}  = \@elements;

    1;
}

# XXX this sort function is idiot but it's work for now :-p
sub _sort {
    my $self = shift;
    my $plugins = shift;
    @$plugins = sort @$plugins;
    my @sorted_plugins = ();
    my %remember_me    = ();
    my @stacks = ();
    for ( @$plugins ) {
        $_->require() or die $@;
        $remember_me{ $_ } = 1;
        my $dependency = $_->dependency ;
        if ( $dependency && !$remember_me{ $dependency }  ) {
            push @stacks , $_;
            next;
        }
        push @sorted_plugins , $_;
    }
    push @sorted_plugins , @stacks;
    return \@sorted_plugins;
}
1;

=head1 NAME

Text::Livedoor::Wiki::Inline - Wiki Inline Parser

=head1 DESCRIPTION

inline parser

=head1 METHOD 

=head2 function

=head2 new

=head2 on_mobile

=head2 parse

=head1 AUTHOR

polocky

=cut
