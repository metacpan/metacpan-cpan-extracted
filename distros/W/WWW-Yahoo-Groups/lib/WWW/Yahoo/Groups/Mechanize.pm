package WWW::Yahoo::Groups::Mechanize;
our $VERSION = '1.91';

=head1 NAME

WWW::Yahoo::Groups::Mechanize - Control WWW::Mechanize for WYG.

=head1 DESCRIPTION

This module is a subclass of L<WWW::Mechanize> that permits us a bit
more control over some aspects of the fetching behaviour.

=head1 INHERITANCE

This module inherits from L<WWW::Mechanize>, which inherits from
L<LWP::UserAgent>. As such, any method available to either of them is
available here. Any overridden methods will be explained below.

=cut

our @ISA = qw( WWW::Mechanize );
use WWW::Mechanize;
use Net::SSL;
use Params::Validate qw( validate_pos SCALAR );
use strict;
use warnings FATAL => 'all';

require WWW::Yahoo::Groups::Errors; 
Params::Validate::validation_options(
    WWW::Yahoo::Groups::Errors->import()
);

=head1 CONSTRUCTOR

=head2 new

As for L<WWW::Mechanize/"new()"> but sets the agent string
to our custom agent.

=cut

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->agent("Mozilla/5.0 (LWP; $class)");
    return $self;
}

=head1 METHODS

=head2 debug

Sets or gets whether we are in debugging mode. Returns true
if set, else false.

     warn "Awooga!" if $self->debug;
     $self->debug( 1 );

=cut

sub debug
{
    my $self = shift;
    $self->{__PACKAGE__.'-debug'} = ($_[0] ? 1 : 0) if @_;
    $self->{__PACKAGE__.'-debug'};
}

=head2 get

We override L<< get|WWW::Mechanize/"$a->get()" >> in order to
provide some behind the scenes actions.

=over 4

=item * Sleeping

We allow you to rate limit your downloading. See L</autosleep>.

=item * Automatic adult confirmation

We automatically click Accept on adult confirmation. So I hope you agree
to all that.

=item * Debugging

If L<debug|/debug> is enabled, then it will display a warning showing the
URL.

=back

I should probably shift the advertisement interruption skipping
into this method at some point, along with the redirect handling.

It will throw a C<X::WWW::Yahoo::Groups::BadFetch> if
it is unable to retrieve the specified page.

Returns 0 if success, else an exception object.

    my $rv = $y->get( 'http://groups.yahoo.com' );
    $rv->rethrow if $rv;

    # or, more idiomatically
    $rv = $y->get( 'http://groups.yahoo.com' ) and $rv->rethrow;


=cut

sub get
{
    my $self = shift;
    my $url = $_[0];
    warn "Fetching $url\n" if $self->debug;
    my $rv;
    $rv = eval {
	# Fetch page
	my $rv = $self->SUPER::get(@_);
	# Throw if problem
	X::WWW::Yahoo::Groups::BadFetch->throw(error =>
	    "Unable to fetch $url: ".
	    $self->res->code.' - '.$self->res->message)
		if ($self->res->is_error);
	# Sleep for a bit
	if (my $s = $self->autosleep() )
	{
	    sleep( $s );
	}
	# Return something
	0;
    };
    if ( $self->uri and $self->uri =~ m,/adultconf\?, )
    {
        my $form = $self->form_number( 0 );
        if ($self->debug)
        {
            for my $form ( $self->forms )
            {
                warn $form->dump;
            }
        }
        warn "Clicking accept for adultconf\n" if $self->debug;
        $self->click( 'accept' );
    }
    if ($@) {
	die $@ unless ref $@;
	$@->rethrow if $@->fatal;
	$rv = $@;
    }
    return $rv;
}

=head2 autosleep

Allows one to configure the sleep period between fetches
The default is 1 (as of 1.86).

    my $period = $ua->autosleep;
    $ua->autosleep( 10 ); # for a 10 second delay

=cut

sub autosleep
{
    my $w = shift;
    my $key = __PACKAGE__.'-sleep';
    if (@_) {
	my ($sleep) = validate_pos( @_,
	    { type => SCALAR, callbacks => {
		    'is integer' => sub { shift() =~ /^ \d+ $/x },
		} }, # number
	);
	$w->{$key} = $sleep;
    }
    return ( exists $w->{$key} ? $w->{$key} : 1 );
}

1;

__DATA__

=head1 BUGS, THANKS, LICENCE, etc.

See L<WWW::Yahoo::Groups>

=head1 AUTHOR

Iain Truskett <spoon@cpan.org>

=cut
