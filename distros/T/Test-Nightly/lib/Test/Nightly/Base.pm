package Test::Nightly::Base;

use strict;
use warnings;

use Carp;

use Test::Nightly::Email;

use base 'Class::Accessor::Fast';

my @methods = qw(
	debug
	report_template
);

__PACKAGE__->mk_accessors(@methods);

our $VERSION = '0.03';

=head1 NAME

Test::Nightly::Base - Internal base methods

=head1 DESCRIPTION

Provides internal base methods for the Test::Nightly::* modules. You don't have to worry about what is here.

=cut

#
# _init()
#
# Initialises the methods that have been passed in.
#

sub _init {

    my ($self, $conf, $methods) = @_;

    $self->{_is_win32} = ( $^O =~ /^(MS)?Win32$/ );
    $self->{_is_macos} = ( $^O eq 'MacOS' );

	my @all_methods = @{$methods};
	push (@all_methods, @methods);

    my $is_obj = 1 if ref($conf) =~ /Test::Night/;
    foreach my $method (@all_methods) {

        if (defined $conf->{$method}) {
            if($is_obj) {
                $self->$method($conf->$method());
            } else {
                $self->$method($conf->{$method});
            }
        }
    }

}

#
# _debug()
#
# Carps a debug message.
#

sub _debug {

    my ($self, $msg) = @_;

    if (defined $self->debug()) {
        carp $msg;
    }

}

#
# _perl_command()
#
# Returns the command to run perl.
#

sub _perl_command {

    my $self = shift;

    return $ENV{HARNESS_PERL}           if defined $ENV{HARNESS_PERL};
    return Win32::GetShortPathName($^X) if $self->{_is_win32};
    return $^X;

}

=head1 AUTHOR

Kirstin Bettiol <kirstinbettiol@gmail.com>

=head1 COPYRIGHT

(c) 2005 Kirstin Bettiol
This library is free software, you can use it under the same terms as perl itself.

=head1 SEE ALSO

L<Test::Nightly>, 
L<Test::Nightly::Test>, 
L<Test::Nightly::Report>, 
L<Test::Nightly::Email>, 
L<perl>.

=cut

1;

