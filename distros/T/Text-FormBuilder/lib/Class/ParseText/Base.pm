package Class::ParseText::Base;

use strict;
use warnings;
use Carp;

use base qw(Class::Base);
use vars qw($VERSION);

$VERSION = '0.01';

# (caller(0))[3] => fully qualified subname (e.g. My::Package::function)

sub parse {
    my ($self, $source) = @_;
    if (my $type = ref $source) {
        if ($type eq 'SCALAR') {
            $self->parse_text($$source);
        } elsif ($type eq 'ARRAY') {
            $self->parse_array(@$source);
        } else {
            croak '[' . (caller(0))[3] . "] Unknown ref type $type passed as source";
        }
    } else {
        $self->parse_file($source);
    }
}

sub parse_array {
    my ($self, @lines) = @_;
    # so it can be called as a class method
    $self = $self->new unless ref $self;    
    $self->parse_text(join("\n", @lines));    
    return $self;
}

sub parse_file {
    my ($self, $filename) = @_;
    
    # so it can be called as a class method
    $self = $self->new unless ref $self;
    
    local $/ = undef;
    open SRC, "< $filename" or croak '[' . (caller(0))[3] . "] Can't open $filename: $!";
    my $src = <SRC>;
    close SRC;
    
    return $self->parse_text($src);
}

sub parse_handle {
    my ($self, $fh) = @_;
    
    # so it can be called as a class method
    $self = $self->new unless ref $self;
    
    my $src;
    local $/ = undef;
    $src = readline($fh);
    close $fh;
    return $self->parse_text($src);
}

sub parse_text {
    my ($self, $src) = @_;
    
    # so it can be called as a class method
    $self = $self->new unless ref $self;
    
    croak '[' . (caller(0))[3] . '] No parser defined for this class (perhaps you need to override init?)'
        unless defined $self->{parser};
    
    # optionally ensure that the source text ends in a newline
    $src =~ /\n$/ or $src .= "\n" if $self->{ensure_newline};
    
    # get the name of the start rule
    my $start_rule = $self->{start_rule};
    croak '[' . (caller(0))[3] . '] No start rule given for the parser' unless defined $start_rule;
    
    # set the trace in RecDescent if we have the debug flag
    $::RD_TRACE = $self->{debug} ? 1 : undef;
    
    $self->{$start_rule} = $self->{parser}->$start_rule($src);
    
    # mark structures as not built (newly parsed text)
    $self->{built} = 0;
    
    return $self;
}


# module return
1;

=head1 NAME

Class::ParseText::Base - Base class for modules using Parse::RecDescent parsers

=head1 SYNOPSIS

    package My::Parser;
    use strict;
    
    use base qw(Class::ParseText::Base);
    
    # you need to provide an init method, to set the parser and start rule
    sub init {
        my $self = shift;
        
        # set the parser and start rule that should be used
        $self->{parser} = Parse::RecDescent->new($grammar);
        $self->{start_rule} = 'foo';
        $self->{ensure_newline} = 1;
        
        return $self;
    }
    
    package main;
    
    my $p = My::Parser->new;
    
    $p->parse_text($source_text);
    $p->parse(\$source_text);
    
    $p->parse_array(@source_lines);
    $p->parse(\@source_lines);
    
    $p->parse_file($filename);
    $p->parse($filename);

=head1 REQUIRES

This base class is in turn based on L<Class::Base>.

=head1 DESCRIPTION

All of the parse rules set C<< $self->{built} >> to false, to indicate that
a fresh source has been read, and (probably) needs to be analyzed.

=head2 new

    my $p = My::Parser->new;

Creates a new parser object. In general, calling C<new> explicitly is not
necessary, since all of the C<parse> methods will invoke the constructor
for you if they are called as a class method.

    # as a class method
    my $p = My::Parser->parse_file('some_source.txt');

=head2 parse_file

    $p->parse_file($filename);

Parses the contents of of the file C<$filename>. Returns the parser object.

=head2 parse_handle

    $p->parse_handle($fh);

Slurps the remainder of the file handle C<$fh> and parses the contents.
Returns the parser object.

=head2 parse_array

    $p->parse_array(@lines);

Joins C<@lines> with newlines and parses. Returns the parser object.

=head2 parse_text

    $p->parse_text($source);

Parse the literal C<$source>. Returns the parser object.

=head2 parse

    $p->parse($src);

Automagic method that tries to pick the correct C<parse_*> method to use.

    ref $src            method
    ========            ==================
    ARRAY               parse_array(@$src)
    SCALAR              parse_text($$src)
    undef               parse_file($src)

Passing other ref types in C<$src> (e.g. C<HASH>) will cause C<parse> to die.

=head1 SUBCLASSING

This class is definitely intended to be subclassed. The only method you should
need to override is the C<init> method, to set the parser object that will do the
actual work.

=head2 init

The following properties of the object should be set:

=over

=item C<parser>

The Parse::RecDescent derived parser object to use.

=item C<start_rule>

The name of the initial rule to start parsing with. The results of
the parse are stored in the object with this same name as their key.

=item C<ensure_newline>

Set to true to ensure that the text to be parsed ends in a newline.

=back

I<Be sure that you explicitly return the object!> This is a bug that
has bitten me a number of times.

=head1 TODO

C<parse_handle> method

Expand to use other sorts of parsing modules (e.g. Parse::Yapp)

=head1 AUTHOR

Peter Eichman, C<< <peichman@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright E<copy>2005 by Peter Eichman.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
