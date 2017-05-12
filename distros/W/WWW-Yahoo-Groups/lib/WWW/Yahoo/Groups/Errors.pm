package WWW::Yahoo::Groups::Errors;
our $VERSION = '1.91';

=head1 NAME

WWW::Yahoo::Groups::Errors - Exception classes for WYG

=head1 DESCRIPTION

This class provides assorted exceptions for the use of the other
modules.

=head1 INHERITANCE

All errors are subclasses of C<X::WWW::Yahoo::Groups> which is a
subclass of C<Exception::Class::Bass>. See L<Exception::Class>'s
documentation for methods available on the errors.

=head1 EXTRA METHODS

Beyond what L<Exception::Class> provides, there are two extra methods.

=head2 fatal

C<fatal> will return true if the error caught should be one that
terminates the process.

=head1 AVAILABLE CLASSES

These should be obvious from their name. If not, please consult the
source or use the C<description> method.

    X::WWW::Yahoo::Groups::BadParam
    X::WWW::Yahoo::Groups::BadLogin
    X::WWW::Yahoo::Groups::NoHere
    X::WWW::Yahoo::Groups::AlreadyLoggedIn
    X::WWW::Yahoo::Groups::NotLoggedIn
    X::WWW::Yahoo::Groups::NoListSet
    X::WWW::Yahoo::Groups::UnexpectedPage
    X::WWW::Yahoo::Groups::NotThere
    X::WWW::Yahoo::Groups::BadFetch
    X::WWW::Yahoo::Groups::BadProtected

=cut

require Exception::Class;

    Exception::Class->import(
	'X::WWW::Yahoo::Groups' => {
	    description => 'An error related to WWW::Yahoo::Groups',
	    fields => [qw( fatal )],
	},
	'X::WWW::Yahoo::Groups::BadParam' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'Invalid parameters specified for function',
	},
	'X::WWW::Yahoo::Groups::BadLogin' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'For some reason, your login failed',
	},
	'X::WWW::Yahoo::Groups::NoHere' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => "The ``here'' link was not found on the login page.",
	},
	'X::WWW::Yahoo::Groups::AlreadyLoggedIn' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'You are already logged in with this object.',
	},
	'X::WWW::Yahoo::Groups::NotLoggedIn' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'You must be logged in to perform that method.',
	},
	'X::WWW::Yahoo::Groups::NoListSet' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'You tried accessing a method that required the list to be set',
	},
	'X::WWW::Yahoo::Groups::UnexpectedPage' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'We received a page that I do not understand',
	},
	'X::WWW::Yahoo::Groups::NotThere' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'The message you wanted is not in the archive',
	},
	'X::WWW::Yahoo::Groups::BadFetch' => {
	    isa => 'X::WWW::Yahoo::Groups',
	    description => 'We tried fetching a page, but failed',
	},
        'X::WWW::Yahoo::Groups::BadProtected' => {
            isa => 'X::WWW::Yahoo::Groups',
            description => 'Protected string contains unknown control sequence. Table needs amending.',
        },
    );

=head1 USE OF THIS MODULE

Due to the nature of how L<Params::Validate> works, we store
common options for it in this class (as they mostly relate to
error handling). Thus, you should import this module with the
following idiom:

    require WWW::Yahoo::Groups::Errors; 
    Params::Validate::validation_options(
        WWW::Yahoo::Groups::Errors->import()
    );


=cut

sub import
{
    my ($class) = @_;
    return (
	ignore_case => 1,
	strip_leading => 1,
	on_fail => sub {
	    chomp($_[0]);
	    X::WWW::Yahoo::Groups::BadParam->throw(error => $_[0], fatal => 1);
	}
    );
}

1;

__DATA__

=head1 BUGS, THANKS, LICENCE, etc.

See L<WWW::Yahoo::Groups>

=head1 AUTHOR

Iain Truskett <spoon@cpan.org>

=cut
