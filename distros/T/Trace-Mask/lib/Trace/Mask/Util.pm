package Trace::Mask::Util;
use strict;
use warnings;

use Carp qw/croak carp/;

use Scalar::Util qw/reftype looks_like_number/;
use B;

our $VERSION = "0.000008";

use base 'Exporter';
our @EXPORT_OK = qw{
    update_mask
    validate_mask
    get_mask
    mask_line
    mask_call
    mask_sub
    mask_frame
};

my %VALID_MASK = (
    hide     => 1,
    no_start => 1,
    shift    => 1,
    stop     => 1,
    pause    => 1,
    restart  => 1,
    lock     => 1,
);

sub _MASKS() { no warnings 'once'; \%Trace::Mask::MASKS }

sub _subname {
    my $cobj = B::svref_2object($_[0]);
    my $package = $cobj->GV->STASH->NAME;
    my $subname = $cobj->GV->NAME;
    return "$package\::$subname";
}

sub _validate_mask {
    my $mask = shift;
    my @errors = validate_mask($mask) or return;
    my @caller = caller(1);
    my $out = join "\n" => map {"    $_"} @errors;
    die "Invalid mask at $caller[1] line $caller[2].\n$out\n"
}

sub _update_mask {
    my ($file, $line, $sub, $mask) = @_;

    my $name = ref $sub ? _subname($sub) : $sub;

    my $masks = _MASKS();

    # Get existing ref, if any
    my $ref = $masks->{$file}->{$line}->{$name};

    # No ref, easy!
    return $masks->{$file}->{$line}->{$name} = {%$mask}
        unless $ref;

    # Merge new mask into old
    %$ref = (%$ref, %$mask);
    return;
}

sub update_mask {
    my ($file, $line, $sub, $mask) = @_;
    _validate_mask($mask);
    _update_mask(@_);
}

sub validate_mask {
    my ($mask) = @_;

    return ("Mask must be a hashref")
        unless $mask && ref($mask) && reftype($mask) eq 'HASH';

    my @errors;

    # Sort the keys to keep it consistent
    for my $key (sort keys %$mask) {
        next if $key =~ m/^\d+$/; # integer keys are always valid
        next if $VALID_MASK{$key};
        push @errors => "invalid mask option '$key'";
    }

    if (my $shift = $mask->{shift}) {
        push @errors => "'shift' value must be a positive integer"
            unless $shift =~ m/^\d+$/ && $shift >= 0;
    }

    if (my $hide = $mask->{hide}) {
        push @errors => "'hide' value must be a positive integer"
            unless $hide =~ m/^\d+$/ && $hide >= 0;
    }

    return @errors;
}

sub mask_line {
    my ($mask, $delta, @subs) = @_;
    my ($pkg, $file, $line) = caller(0);

    _validate_mask($mask);

    croak "The second argument to mask_line() must be an integer"
        if $delta && (ref($delta) || $delta !~ m/^-?\d+$/);

    push @subs => '*' unless @subs;
    $line += $delta if $delta;

    _update_mask($file, $line, $_, $mask) for @subs;
    return;
}

sub mask_call {
    my $mask = shift;
    my $sub = shift;
    my ($pkg, $file, $line) = caller(0);

    _validate_mask($mask);

    $sub = $pkg->can($sub) if $sub && !ref($sub);

    croak "The second argument to mask_call() must be a coderef, or the name of a sub to call"
        unless $sub && ref($sub) && reftype($sub) eq 'CODE';

    _update_mask($file, $line, $sub, $mask);

    @_ = (@_);    # Hide the shifted args
    goto &$sub;
}

sub mask_sub {
    my ($mask, $sub, $file, $line) = @_;
    $file ||= '*';
    $line ||= '*';

    _validate_mask($mask);

    $sub = caller->can($sub) if $sub && !ref($sub);

    croak "The second argument to mask_sub() must be a coderef, or the name of a sub in the calling package"
        unless $sub && ref($sub) && reftype($sub) eq 'CODE';

    my $name = _subname($sub);
    croak "mask_sub() cannot be used on an unamed sub"
        if $name =~ m/__ANON__$/;

    _update_mask($file, $line, $name, $mask);
    return;
}

sub mask_frame {
    my %mask = @_;

    _validate_mask(\%mask);

    my ($pkg, $file, $line, $name) = caller(1);
    _update_mask($file, $line, $name, \%mask);

    return;
}

sub get_mask {
    my ($file, $line, $sub) = @_;

    my $name = ref($sub) ? _subname($sub) : $sub;

    my $masks = _MASKS();

    return {lock => $1} if $sub =~ m/(?:^|:)(END|BEGIN|UNITCHECK|CHECK|INIT|DESTROY|import|unimport)$/;

    my @order = grep { defined $_ } (
        $masks->{$file}->{'*'}->{'*'},
        $masks->{$file}->{$line}->{'*'},
        $masks->{'*'}->{'*'}->{$name},
        $masks->{$file}->{'*'}->{$name},
        $masks->{$file}->{$line}->{$name},
    );

    return {} unless @order;
    return { map { %{$_} } @order };
}

1;

__END__

=pod

=head1 NAME

Trace::Mask::Util - Utilities for applying stack trace masks.

=head1 DESCRIPTION

This package provides utilities to help you apply masks for stack traces. See
L<Trace::Mask> for the specification these utilities follow.

=head2 EXPORTS

B<Note:> All exports are optional, you must request them if you want them.

=over 4

=item update_mask($file, $line, $sub, \%mask)

Update the mask for the specified C<$file>, C<$line>, and C<$sub>. The mask
hashref will be merged into any existing mask. You may use the wildcard string
C<'*'> for any 2 of the first 3 arguments. C<$sub> may be coderef, or a fully
qualified sub name.

=item @errors = validate_mask(\%mask)

This will check the mask to ensure it is valid. If the mask is valid an empty
list is returned. If there are problems with the mask then a list of error
strings will be returned.

=item $hr = get_mask($file, $line, $sub)

Get the combined mask for the specific file, line and sub. This will be a
merger of all applicable masks, including wildcards. C<$sub> may be a coderef,
or a fully qualified sub name.

=item mask_call(\%mask, $sub)

=item mask_call(\%mask, $sub, @args)

This will call C<$sub> with the specified mask and arguments. This will use
C<goto &$sub> to run your sun without C<mask_call()> itself showing up in any
stack frames. C<$sub> can be a sub reference, or the name of a sub in the
calling package.

=item mask_sub(\%mask, $sub)

=item mask_sub(\%mask, $sub, $file)

=item mask_sub(\%mask, $sub, $file, $line)

Apply the mask to the specified sub, which can be a coderef, or the name of a
sub in the calling package. C<$file> and C<$line> are optional, C<'*'> will be
used if you do not specify.

=item mask_line(\%mask)

=item mask_line(\%mask, $delta)

=item mask_line(\%mask, $delta, @subs)

This will mask calls on the current or current + C<$delta> line of the calling
package. Optionally uo can provide a list of subs to mask, C<'*'> is used if
none are specified.

This is useful if you wish to apply a mask to multiple calls on a specific
line:

    sub try(&) {
        my $code = shift;

        # Hides both the eval, and the anon-block call
        BEGIN { mask_line({hide => 1}, 1) }
        my $ok = eval { $code->(); 1 };

        ...
    }

It is best to run this in a C<BEGIN {...}> block so that the mask is added at
compile time, instead of being re-added every time your code is run.

=item mask_frame(%mask)

This applies a mask to the currently running stack frame, that is whatever sub
you use it in. This applies no matter where/how your sub was called.

=back

=head1 SOURCE

The source code repository for Trace-Mask can be found at
F<http://github.com/exodist/Trace-Mask>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
