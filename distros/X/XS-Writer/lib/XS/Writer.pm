package XS::Writer;

use strict;
use warnings;

our $VERSION = 0.02;

use File::Basename;
use File::Path;
use Carp;
use Moose;
use Moose::Autobox;

{
    package StringWithWhitespace;
    use Moose::Role;

    sub strip_ws {
        $_[0] =~ s/^\s+//;
        $_[0] =~ s/\s+$//;
        $_[0];
    }

    sub squeeze_ws {
        $_[0] =~ s/\s+/ /g;
        $_[0];
    }
}
Moose::Autobox->mixin_additional_role("SCALAR", "StringWithWhitespace");


=head1 NAME

XS::Writer - Module to write some XS for you

=head1 SYNOPSIS

    # As part of your build process...
    use XS::Writer;

    my $writer = XS::Writer->new(
        package   => 'Some::Employee',

        # defines the employee struct
        include   => '#include "employee.h"',
    );

    $writer->struct(<<'END');
        typedef struct employee {
            char *      name;
            double      salary;
            int         id;
        };
    END

    # This will generate lib/Some/Employee_struct.xsi
    # and lib/Some/Employee_struct.h
    $writer->write_xs;


    # Then in lib/Some/Employee.xs
    #include "EXTERN.h"
    #include "perl.h"
    #include "XSUB.h"

    MODULE = Some::Employee  PACKAGE = Some::Employee

    INCLUDE: Employee_struct.xsi

    ...any other XS you like...


    # You must add this to lib/Some/typemap
    TYPEMAP
    Some::Employee          T_PTROBJ


    # And finally in lib/Some/Employee.pm
    package Some::Employee;

    our $VERSION = 1.23;

    use XSLoader;
    XSLoader::load __PACKAGE__, $VERSION;


    # And you will be able to do
    use Some::Employee;

    my $employee = Some::Employee->new;
    $employee->name("Yarrow Hock");


=head1 DESCRIPTION

I went nuts trying to figure out how to map structs into perl.  I finally
figured it out and I never want anyone else to have to go through that.
I also wanted the process to remain transparent, many of the XS writing
modules are themselves almost as complicated as XS itself.

This module helps you write XS by taking care of some of the rote things
for you.  Right now it just makes structs available as objects, writing a
constructor and accessors.  It's designed to be fairly transparent but
you still need to understand some XS.

The instructions are meant for Module::Build.  Adapt as necessary for
MakeMaker.


=head1 Example

See F<t/Some-Employee> in the source tree for an example.


=head1 Stability

It's not.  I'm writing this to fit my own needs and it's likely to change
as my knowledge of XS changes.  Also the XS it generates probably isn't the
best in the universe.  Patches welcome.


=head1 Methods

=head3 new

    my $writer = XS::Writer->new( %args );

Setup a new writer.  Arguments are...

    package         (required) The package to write your XS into.
    xs_file         (optional) Where to write the XS file.  Defaults to
                    lib/Your/Package_struct.xs
    include         (optional) Any extra code to include

=cut

has 'package',
    is          => 'rw',
    required    => 1
;
has 'xs_type',
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        my $type = $self->package;
        $type =~ s/::/__/g;
        return $type;
    }
;
has 'xs_prefix',
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->xs_type . "_";
    }
;
has 'xs_file',
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        my $file = $self->package;
        $file =~ s{::}{/}g;
        return "lib/${file}_struct.xsi";
    }
;
has 'header_file',
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        my $header_file = basename($self->xs_file);
        $header_file =~ s{\.xsi}{.h};
        return $header_file;
    }
;
has 'include',
    is          => 'rw',
    default     => '',
;
has 'struct_type',
    is          => 'rw'
;
has 'struct_elements' =>
    is          => 'rw',
    isa         => 'HashRef'
;
has 'struct_constructor' =>
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return "(malloc(sizeof(@{[ $self->struct_type ]})))";
    },
;
has 'type_accessors' =>
    is          => 'rw',
    isa         => 'HashRef',
    default     => sub { {} },
;


sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->type_accessor(int => <<'END');
$type
$accessor( $class self, ... )
    CODE:
        if( items > 1 )
            self->$key = SvIV(ST(1));
        RETVAL = self->$key;
    OUTPUT:
        RETVAL
END

    $self->type_accessor("char *" => <<'END');
$type
$accessor( $class self, ... )
    CODE:
        if( items > 1 )
            self->$key = SvPV_nolen(ST(1));
        RETVAL = self->$key;
    OUTPUT:
        RETVAL
END

    $self->type_accessor(double => <<'END');
$type
$accessor( $class self, ... )
    CODE:
        if( items > 1 )
            self->$key = SvNV(ST(1));
        RETVAL = self->$key;
    OUTPUT:
        RETVAL
END

    return $self;
}


=head3 struct

    $writer->struct($typedef);

The typedef for the struct you'd like to write a class around.

The C parser isn't too sophisticated.

=cut

sub struct {
    my $self = shift;
    my $typedef = shift;

    # Cleanup
    $typedef =~ s{/\* .* \*/}{}g;    # strip C comments
    $typedef =~ s{//.*}{}g;          # strip C++ comments
    $typedef->strip_ws;

    $typedef =~ s/^typedef\s+//;        # optional "typedef"
    $typedef =~ s/^struct\s+(\w+)//;    # struct type
    my $type = $1;

    croak "Can't figure out the type" unless $type;

    # Get the braces out of the way.
    $typedef =~ s/.*?{\s+//;
    $typedef =~ s/\s+}.*?//;

    # All we should have left is "type key;"
    my %elements = map {
                       /^(.*?)\s*(\w+)$/ ?
                            ($2 => $1) : ();
                   }
                   map { $_->strip_ws;  $_->squeeze_ws }
                       split /;/, $typedef;

    croak "Didn't see any elements in $type" unless keys %elements;

    $self->struct_type($type);
    $self->struct_elements(\%elements);
}


=head3 type_accessor

    $writer->type_accessor($type, $xs);

XS::Writer will deal with simple types, but you will have to supply
code for anything beyond that.

Here's an example for an accessor to elements with the 'double' type.

    $writer->type_accessor('double', <<'END_XS');
        $type
        $accessor( $class self, ... )
            CODE:
                if( items > 1 )  /* setting */
                    self->$key = SvNV(ST(1));

                RETVAL = self->$key;
            OUTPUT:
                RETVAL
    END_XS

Variables should be used in place of hard coding.

    $type       same as the $type you gave
    $accessor   name of the accessor function
    $class      type of the struct
    $key        the element on the struct being accessed

=cut

sub type_accessor {
    my $self = shift;
    my($type, $xs) = @_;

    my $package = $self->package;

    $xs =~ s{\$type} {$type}g;
    $xs =~ s{\$class}{$package}g;

    $self->type_accessors->{$type} = $xs;
}

=head3 make_xs

    my $xs = $self->make_xs;

Generates the XS code.

=cut

sub make_xs_header {
    my $self = shift;

    my $xs = <<END;
# Generated by XS::Writer $VERSION

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "@{[ $self->header_file ]}"

MODULE = @{[ $self->package ]}  PACKAGE = @{[ $self->package ]}  PREFIX = @{[ $self->xs_prefix ]}

@{[ $self->package ]}
@{[ $self->xs_type ]}_new( char* CLASS )
    CODE:
       RETVAL = (@{[ $self->struct_constructor ]});
        if( RETVAL == NULL ) {
           warn( "unable to create new @{[ $self->package ]}" );
       }
    OUTPUT:
       RETVAL


void
@{[ $self->xs_type ]}_free( @{[ $self->package ]} self )
    CODE:
        free(self);
END

    return $xs;
}


sub make_xs_accessors {
    my $self = shift;

    my $xs = '';

    my $elements  = $self->struct_elements;
    my $accessors = $self->type_accessors;
    my $xs_type   = $self->xs_type;
    for my $key (sort { lc $a cmp lc $b } keys %$elements) {
        my $type = $elements->{$key};

        my $accessor = $accessors->{$type}
            or croak "No accessor for type $type";
        $accessor =~ s/\$accessor/${xs_type}_${key}/g;
        $accessor =~ s/\$key/$key/g;

        $xs .= $accessor;
        $xs .= "\n\n";
    }

    return $xs;
}


sub make_xs {
    my $self = shift;

    return    $self->make_xs_header
            . "\n\n"
            . $self->make_xs_accessors;
}


=head3 write_xs

    $writer->write_xs;

Writes the XS to $writer->xs_file.

=cut

sub write_xs {
    my $self = shift;
    
    $self->write_xs_file;
    $self->write_header;
}

sub write_xs_file {
    my $self = shift;
    
    my $fh = $self->open_file(">", $self->xs_file);
    print $fh $self->make_xs;
}

sub write_header {
    my $self = shift;
    
    my $fh = $self->open_file(">", $self->header_file);
    print $fh <<"END";
/* Generated by XS::Writer $XS::Writer::VERSION */

@{[ $self->include ]}

typedef @{[ $self->struct_type ]} *     @{[ $self->xs_type ]};
END

}

sub open_file {
    my $self = shift;
    my($mode, $file) = @_;
    
    my $dir = dirname($file);
    mkpath $dir unless -d $dir;
    
    open my $fh, $mode, $file
        or die "Can't write to $file: $!";
    
    return $fh;
}


=head1 AUTHOR

Michael G Schwern E<lt>schwern@pobox.comE<gt>


=head1 LICENSE

Copyright 2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses>


=head1 THANKS

Thanks to...

Tom Heady for answering my cry for XS help and showing me how
to do struct accessors.

Simon Cozens for "Embedding and Extending Perl"


=head1 SEE ALSO

L<Inline::Struct>, L<ExtUtils::XSBuilder>, L<perlxs>

=cut

1;
