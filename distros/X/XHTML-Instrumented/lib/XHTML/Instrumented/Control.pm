use strict;
use warnings;

package 
    XHTML::Instrumented::Control;

use Params::Validate qw (validate ARRAYREF HASHREF );

sub new()
{
    my $class = shift;
    my %p =  Params::Validate::validate( @_, {
	    src => 0, 
	    text => 0,
	    args => 0,
	    replace => 0,
	    remove_tag => 0,
	    remove => 0,
	    id_count => 0,
	}
    );
    delete $p{remove};
    bless({args => {}, @_}, $class);
}

sub remove_self()
{
    my $self = shift;

    $self->{remove_tag} || 0;
}

sub has_name
{
    my $self = shift;

    exists $self->{args}{name};
}

sub name
{
    my $self = shift;

    $self->{args}{name};
}

sub remove()
{
    my $self = shift;

    $self->{remove};
}

sub args
{
    my $self = shift;
    my %args = @_;
    my %hash = ( %args, %{$self->{args} || {}} );

    if (my $idc = $self->id_count) {

        if ($hash{for}) {
	    $hash{for} .= '.' . $idc;
	}
        if ($hash{id}) {
	    $hash{id} .= '.' . $idc;
	}
    }

    %hash;
}

sub eq
{
    my $self = shift;
    my $ret = 0;
    
    for my $item (@_) {
	$ret = 1 if $item eq $self->{text};
    }
    return $ret;
}

sub if
{
    my $self = shift;

    !!($self->{text} || keys %{$self->{args} || {}});
}

sub _fixup
{
    my @ret;
    for my $data (@_) {
	next unless $data;
        $data =~ s/&/&amp;/g;
        my $x = $data;
#       $data = Encode::decode_utf8( $x );
        push @ret, $data;
    }
    @ret;
}

#####################
# 
#
#
sub exp_args
{
    my $self = shift;

    die ref($_[0]), caller if ref($_[0]);

    my %args = $self->args(@_);

    my $nargs = { %args };

    my $ret = join('', map({ defined($nargs->{$_}) ? qq( $_="$nargs->{$_}") : ''; } sort keys(%args)));
    $ret =~ s/&/&amp;/g;
    return $ret;
}

our %special_tag = ( a => 1, div => 1, textarea => 1 );

sub expand_content
{
    my $self = shift;

    if ($self->{remove}) {
	return '';
    }
    if (defined $self->{text}) {
        $self->{text};
    } else {
	@_;
    }
}

sub children
{
    my $self = shift;
    my %p = validate(@_, {
        children => ARRAYREF,
	context => { isa => 'XHTML::Instrumented::Context' },
    });
    my $context = $p{context};
    my @ret;

    for my $element (@{$p{children}}) {
	if (UNIVERSAL::isa($element, 'XHTML::Instrumented::Entry')) {
	    push(@ret, $element->expand(context => $context));
	} else {
	    push(@ret, $element);
	}
    }
    return @ret;
}

use Data::Dumper;

sub to_text
{
    my $self = shift;
    my %p = validate(@_, {
	tag => 1,
        children => ARRAYREF,
        args => HASHREF,
	flags => HASHREF,
	context => { isa => 'XHTML::Instrumented::Context' },
	special => 0,
    });

    my $flags = $p{flags};

    if ($p{special}) {
	return @{$p{special}};
    }

    my $args = { %{$p{args}} };

    my $test = !!$p{flags}->{if};
    my @children;
    if ($p{flags}->{eq}) {
        $test++;
    }

    if ($test) {    # This is only a test of the Entry
	@children = @{$p{children}};
    } else {
	@children = $self->expand_content(@{$p{children}});
    }

    @children = $self->children(context => $p{context}, children => \@children);

    if ($self->remove) {
        return ();
    }
    if ($self->remove_self || $flags->{rs}) {
        return (
	    @children,
	);
    }

    my $tag = $p{tag};
#die Dumper \@children if $p{tag} eq 'input' and $p{args}{name} eq 'test2';

    my @ret;
    if ($special_tag{$tag} || @children) {
	@ret = ('<' . $tag . $self->exp_args(%$args) . '>',
	@children,
	'</' . $tag . '>');
    } else {
	@ret = ('<' . $tag . $self->exp_args(%$args) . '/>');
    }
    return @ret;
}

sub set_id_count
{
    my $self = shift;
    my $data = shift;

    $self->{id_count} = $data;
}

sub id_count
{
    my $self = shift;
    my $ret;
    if ($self->in_loop) {
        $ret = $self->{id_count};
    }
    return $ret;
}

sub in_loop
{
    my $self = shift;

    defined $self->{id_count};
}

sub form
{
    undef;
}

sub required
{
    shift;

    @_;
}

sub set_tag
{
    my $self = shift;
    my %p = @_;

    $self->{tag} = $p{tag};

    $self->{_args} = {
	%{$p{args} || {}},
        %{$self->{args} || {}}
   };
}

package
    XHTML::Instrumented::Control::Dummy;

use base 'XHTML::Instrumented::Control';

sub if 
{
    0;
}

sub is_dummy
{
    1;
}

1;
__END__

=head1 NAME

XHTML::Instrumented::Control - This object is used to control an Entry object

=head1 SYNOPSIS

This is used internally by XHTML::Instrumented.

=head1 DESCRIPTION

This is used internally by XHTML::Instrumented.

=head1 API

How this object is used.

=over

=item new

=back

=head2 Methods

=over

=item remove_self()

=item remove()

=item args

=item eq

=item if

=item _fixup

=item exp_args

Get the arguments for the tag.

=item expand_content

=item children

=item to_text

=item set_id_count

=item id_count

=item form

=item required

=item if 

=item is_dummy

=item in_loop

=item has_name

=item name


=item set_tag

This methods sets the tag for the control element for testing.

=back

=head2 Functions

This Object has no functions.

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
