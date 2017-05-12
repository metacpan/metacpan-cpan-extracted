#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
package Wetware::CLI;

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage qw(pod2usage); # it will export it, I want this annotated.

our $VERSION = 0.06;

#-------------------------------------------------------------------------------

sub get_options {
	my ($self, @argv) = @_;
	
    my $options_ref = $self->option_defaults();
    my @option_spec = $self->option_specifications();

    # Because GetOptions will consume ARGV - and we want to
    # test this code with what ever @argv was passed in.
    local @ARGV = @argv;
    
    GetOptions( $options_ref, @option_spec )
        or return pod2usage(
        -message => 'Error Parsing GetOptions',
        -exitval => 2
        );

    # if it is just the help or pod option, then exit there.
    $self->help_or_pod($options_ref);
    
    $self->remaining_argv($options_ref,@ARGV);
     
    return $self->verify_required_options($options_ref);
}

sub help_or_pod {
	my ($self, $options) = @_;

    pod2usage(1) if ( $options->{'help'} );
    pod2usage( -verbose => 2 ) if ( $options->{'pod'} );
 
    return $self;
}

#-------------------------------------------------------------------------------
# the Plain Vanilla form
sub new {
	my ($class, %params) = @_;	
    my $self = bless {}, $class;
    return $self;
}

sub option_defaults {
	return {};
}

sub option_specifications {
	return qw(
        verbose
        help
        pod
	);
}

sub remaining_argv {
    my ($self,$options_ref,@argv) = @_;
    return unless @argv;
    $options_ref->{'remaining_argv'} = [@argv];
    return $self;
}

sub required_settings {
	return qw() ;
}

sub verify_required_options {
    my ($self,$options_ref) = @_;

    my @missing_settings = ();
    foreach my $setting ( $self->required_settings() ) {
        if ( !$options_ref->{$setting} ) {
            push @missing_settings, $setting;
        }
    }
    if (@missing_settings) {
        pod2usage(
            -message => "Missing settings: @missing_settings",
            -exitval => 2,
        );
    }
    return $options_ref;
}

#-------------------------------------------------------------------------------

1; 

__END__

=pod

=head1 NAME

Wetware::CLI - A base class wrapper on Getopt::Long::GetOptions()

=head1 SYNOPSIS

    use Wetware::CLI;

    my $cli = Wetware::CLI->new();
    my $options_hash = $cli->get_options();

=head1 DESCRIPTION

I looked around, and there is no simple wrapper on GetOptions().

So rather than have to keep cutting and pasting the same basic set
of semi private methods. I have opted to create a CLI Object, that
will do all of the work for me.

I will discuss the question of subclassing later on.

The list of Semi Private Methods explain basically how to make
your own CLI sub class.

=head1 METHODS

=head2 new()

Takes no arguments, and creates a simple blessed has.

=head2 get_options()

This wraps the Getopt::Long function.

=head1 SEMI_PRIVATE_METHODS

If you are not planning to subclass this, do not worry about this.

=head2 help_or_pod($options_hash)

If the help or pod option is set, then this will invoke the appropriate
pod2usage() command.

=head2 option_defaults()

Returns the hash reference of option defaults. As implemented
this is an empty hash reference.

=head2 option_specifications()

Returns the list of option specificans. As implemented this
is merely the list help, pod, verbose.

=head2 remaining_argv($opts, @argv)

This is called after the C<help_or_pod()>. As implemented this
will add the 'remaining_argv' attributes to the $opts hash ref,
if @ARGV is not empty.

This should be overridden if the sub class will want to
have a named value.

It returns self, if there were any remaining values.
Otherwise it returns undef.

=head2 required_settings()

returns the list of required settings.

=head2 verify_required_options($options_hash)

Check that all of the required options are set.

=head1 AUTHOR

"drieux", C<< <"drieux [AT]  at wetware.com"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-wetware-cli at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wetware-CLI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

Getopt::Long;

use Pod::Usage;

=head1 SUPPORT

At present I do not have any support solutions.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 "drieux", all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# End of Wetware::CLI
