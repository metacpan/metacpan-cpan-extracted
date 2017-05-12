package Validator::Var;
use 5.006;
use strict;
use warnings;
use Carp;


=head1 NAME

Validator::Var - variable validator with expandable list of checkers.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

    use Validator::Var;
    my $var;
    
    ...

    my $num_bitween = Validator::Var->new();
    $foo->checker(Between, 0, 100);
    unless ( $foo->is_valid( $var ) ) {
        warn "variable is not bitween 0 an 100";
    }

    my $number = Validator::Var->new();
    $number->checker(Regexp, '^d+$');
    
    unless ( $bar->is_valid( $var ) ) {
        warn "variable is not a number";
    }
    
    my $ref_validator = Validator::Var->new();
    $ref_validator->checker(Ref, qw(REF Foo Bar));
    unless ( $bar->is_valid( $var ) ) {
        warn "variable is not a number";
    }

 
    ...

=cut

sub _print { print @_; }
sub _warn  { warn @_; }

sub _Def { [undef,  'Def',  'var is defined' ] }


=head1 METHODS

=head2 new( [$at_least_one] )

Creates new variable validator.
If C<at_least_one> is provided and it is true validation will be
passed if passed through at least one checker.

=cut

sub new
{
    my $class = shift;
    my $at_least_one = shift || 0;
    my $self = bless {
        'checkers'=>[],
        'checkers_not_passed'=>[],
        'at_least_one' => $at_least_one }, $class;
    $self->checker(_Def);
    return $self;
}

=head2 is_empty

Checks if variable validator has no any checker.

=cut

sub is_empty
{
    return @{$_[0]->{'checkers'}} > 1 ? 0 : 1;
}


=head2 at_least_one( $bool )

=cut

sub at_least_one
{
    $_[0]->{'at_least_one'} = $_[1];
    return $_[0];
}



=head2 checker( $checker[, $checker_args] )

Set (append) new checker.

=cut

sub checker
{
    my ($self, @args) = @_;
    $self->{'checkers'} = [] unless defined $self->{'checkers'};
    push @{$self->{'checkers'}}, \@args;
    return $self;
}


=head2 checkers_not_passed

=cut

sub checkers_not_passed
{
    my $self = shift;

    my @checkers_not_passed_spec = ();
    foreach my $i ( @{$self->{'checkers_not_passed'}} ) {
        my $checker = $self->{'checkers'}->[$i]->[0];
        push @checkers_not_passed_spec, [ $checker->[1], $checker->[2] ];
    }
    return wantarray ? @checkers_not_passed_spec : \@checkers_not_passed_spec;
}

=head2 is_valid( $var [, $do_trace]  )

Checks if variable value is valid according to specified checkers.
Trace data will be gathered if C<do_trace> is provided and it is true.

=cut

sub is_valid
{
    my ($self, $val, $do_trace) = @_;
    $do_trace = 0 unless defined $do_trace;

    $self->{'checkers_not_passed'} = [];

    unless ( defined $val ) {
        push @{$self->{'checkers_not_passed'}}, 0;
        return 0;
    }

    for( my $i = 1; $i < @{$self->{'checkers'}}; $i++ ) {
        my $checker_spec = $self->{'checkers'}->[$i];
        my ($checker, @checker_args) = @{$checker_spec};

        unless( $checker->[0]->($val, @checker_args ) ) {
            
            if( $do_trace ) {
                push @{$self->{'checkers_not_passed'}}, $i unless $self->{'at_least_one'};
                next;
            } else {
                return 0 unless $self->{'at_least_one'};
            }
        }

        if( $do_trace ) {
            push @{$self->{'checkers_not_passed'}}, $i if $self->{'at_least_one'};
        } else {
            return 1 if $self->{'at_least_one'}; # at least one checker has passed
        }
    }

    if( $do_trace ) {
        $self->{'at_least_one'} && @{$self->{'checkers_not_passed'}} > 0 && return 1;
        @{$self->{'checkers_not_passed'}} > 0 && return 0;
        return 1;
    }
    return $self->{'at_least_one'} ? 0 : 1; # all checkers has passed or no one
}


=head2 print_trace( [$format]  )

Print trace of variable checking.
C<format> specifies format string of trace messages.
Recognizes the following macro:

=over 4

=item %name%

Replaced by checker's name.

=item %args%

Replaced by checker's arguments.

=item %desc%

Replaced by checker's description.

=item %result%

Replaced by 'passed' or 'failed'.

=back

Default format string is C<"Checker %name%(%args%) - %desc% ... %result%">.

=cut

sub print_trace
{
    my $self = shift;
    my $format = shift || 'Checker %name%(%args%) - %desc% ... %result%';

    if( @{$self->{'checkers_not_passed'}} == 0 ) {
        carp 'no trace info, may be you forgot to make trace via is_valid whith trace flag enabled', "\n";
    } else {
        my $res_str = $self->{'at_least_one'} ? 'passed' : 'failed';
        my $output = $self->{'at_least_one'} ? \&_print : \&_warn;
        foreach ( @{$self->{'checkers_not_passed'}} ) {

            my $checker_spec = $self->{'checkers'}->[$_];
            my ($checker, @checker_args) = @{$checker_spec};
            my ($name, $desc, $args) = (
                $checker->[1],
                $checker->[2],
                join ';', @checker_args
            );

            my $msg = $format;
            $msg =~ s/%name%/$name/;
            $msg =~ s/%desc%/$desc/;
            $msg =~ s/%args%/$args/;
            $msg =~ s/%result%/$res_str/;
            $output->( "$msg\n") ;
        }
    }
}


=head1 AUTHOR

Fedor Semenov, C<< <fedor.v.semenov at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-validator-var at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Validator-Var>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Validator::Var


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator-Var>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Validator-Var>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Validator-Var>

=item * Search CPAN

L<http://search.cpan.org/dist/Validator-Var/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Fedor Semenov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Validator::Var
