package XML::XOXO::Parser;
use strict;
use base qw( XML::Parser );

my %HANDLERS;

BEGIN {
    no strict 'refs';
    map {
        $HANDLERS{ 'start_' . $_ } = \&{ __PACKAGE__ . '::start_' . $_ };
        $HANDLERS{ 'end_' . $_ }   = \&{ __PACKAGE__ . '::end_' . $_ };
    } qw( li a dl dt dd ol ul);
}

#--- constructor

sub new {
    my ( $class, %a ) = @_;
    $a{NoExpand} = 1;
    $a{ParamEnt} = 0;
    delete $a{strict};    # precautionary while not operational.
    my $self = $class->SUPER::new(%a);
    bless( $self, $class );
    no strict 'refs';
    map { $self->setHandlers( $_, \&{$_} ) } qw( Init Start Char End Final );
    $self;
}

#--- XML::Parser handlers

sub Init {
    my $xp = shift;
    $xp->{xostack}   = [];
    $xp->{textstack} = [];
    $xp->{'return'}  = [];
}

sub Start {
    $HANDLERS{ 'start_' . $_[1] }->(@_)
      if $HANDLERS{ 'start_' . $_[1] };
}

sub Char {
    $_[0]->{textstack}->[-1] .= $_[1]
      if defined( $_[0]->{textstack}->[-1] );
}

sub End {
    $HANDLERS{ 'end_' . $_[1] }->(@_)
      if $HANDLERS{ 'end_' . $_[1] };
}

sub Final {
    delete $_[0]->{textstack};
    delete $_[0]->{xostack};
    $_[0]->{'return'};
}

#--- tag handlers

{
    my $start_list = sub {
        my ( $xp, $tag, $a ) = @_;

        # strict not working, but harmless left in.
        unless ( $xp->{strict} && ( !$a->{class} || $a->{class} ne 'xoxo' ) ) {
            my $node = XML::XOXO::Node->new;
            $node->name($tag);
            my $parent = $xp->{xostack}->[-1];
            unless ($parent) {
                push( @{ $xp->{'return'} }, $node );
            } else {
                $node->parent($parent);
                $parent->contents( [] ) unless $parent->contents;
                push( @{ $parent->contents }, $node );
            }
            push( @{ $xp->{xostack} }, $node );
        } else {

            # $xp->skip_until($xp->element_index); # why doesn't this work?
        }
    };
    *start_ol = $start_list;
    *start_ul = $start_list;
}

sub end_ol { pop( @{ $_[0]->{xostack} } ) }
sub end_ul { pop( @{ $_[0]->{xostack} } ) }

sub start_li {
    my ( $xp, $tag ) = @_;
    my $node = XML::XOXO::Node->new;
    $node->name($tag);
    my $parent = $xp->{xostack}->[-1];
    $node->parent($parent);
    $parent->contents( [] ) unless $parent->contents;
    push( @{ $xp->{xostack} },          $node );
    push( @{ $node->parent->contents }, $node );
    push( @{ $xp->{textstack} },        '' );
}

sub end_li {
    my ( $xp, $tag ) = @_;
    my $node = pop( @{ $xp->{xostack} } );
    my $val  = strip_ws( pop( @{ $xp->{textstack} } ) );
    $node->attributes->{text} = $val if length($val);
}

sub start_a {
    my ( $xp, $tag, %a ) = @_;
    map { $a{$_} = lc( $a{$_} ) if $a{$_} } qw( rel type );
    if ( $a{href} ) {
        $a{url} = $a{href};
        delete $a{href};
    }
    my $node = $xp->{xostack}->[-1];
    map { $node->attributes->{$_} = $a{$_} } keys %a;
    push( @{ $xp->{textstack} }, '' );
}

sub end_a {
    my ( $xp, $tag ) = @_;
    my $val  = strip_ws( pop( @{ $xp->{textstack} } ) );
    my $node = $xp->{xostack}->[-1];
    if ($val) {
        if ( defined $node->attributes->{title}
             && $node->attributes->{title} eq $val ) {
            $val = '';
             } elsif ( defined $node->attributes->{url}
                  && $node->attributes->{url} eq $val ) {
            $val = '';
                  } elsif ( length($val) ) {   # correct handling with end_li???
            $node->attributes->{text} = $val;
        }
    }
}

sub start_dl { }
sub end_dl   { }
sub start_dt { push( @{ $_[0]->{textstack} }, '' ) }
sub end_dt   { }

sub start_dd {
    my ( $xp, $tag ) = @_;
    push( @{ $xp->{textstack} }, '' );

    # hack to capture multi-valued properties
    my $dummy = XML::XOXO::Node->new;
    $dummy->name('DUMMY');
    push( @{ $xp->{xostack} }, $dummy );
}

sub end_dd {
    my $xp  = shift;
    my $val = strip_ws( pop( @{ $xp->{textstack} } ) );
    my $key = pop( @{ $xp->{textstack} } );

    # undo hack.
    my $dummy = pop( @{ $xp->{xostack} } );
    my $node  = $xp->{xostack}->[-1];
    if ( defined( $dummy->contents->[0] ) ) {
        $val = $dummy->contents->[0];
        $val->parent($node);
    }

    # end undo.
    return unless length($val);
    $key = strip_ws($key);
    $node->attributes->{$key} = $val;
}

#--- utility

sub strip_ws {
    $_[0] =~ s/[\n\t\r]//gs;
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
    $_[0];
}

1;

__END__

=begin

=head1 NAME

XML::XOXO::Parser - A parser for Extensible Open XHTML Outlines (XOXO) markup.

=head1 METHODS

The following objects and methods are provided in this package.

=item XML::XOXO::Parser->new

Constructor. Returns a reference to a new XML::XOXO::Parser object.

=item $parser->parse(source)

Inherited from L<XML::Parser>, the SOURCE parameter should either
open an IO::Handle or a string containing the whole XML document. A
die call is thrown if a parse error occurs otherwise it will return
an ARRAY of L<XML::XOXO::Node> root objects.

=item $parser->parsefile(file)

Inherited from L<XML::Parser>, FILE is an open handle. The file is
closed no matter how parse returns. A
die call is thrown if a parse error occurs otherwise it will return
an ARRAY of L<XML::XOXO::Node> root objects.

=head1 DEPENDENCIES

L<XML::Parser>, L<Class::XPath> 1.4

=head1 TO DO

=over

=item * Handle embedded XOXO in an XHTML document

=item * Implement strict mode

=back

=head1 AUTHOR & COPYRIGHT

Please see the XML::XOXO manpage for author, copyright, and license
information.

=cut

=end
