use warnings;
use 5.020;
use experimental qw( signatures );
use stable qw( postderef );
use true;

package Tie::Hash::DataSection 0.01 {

    # ABSTRACT: Access __DATA__ section via tied hash


    use Data::Section::Pluggable 0.08;
    use Ref::Util qw( is_plain_arrayref );

    sub TIEHASH ($class, $package=undef, @plugins) {
        $package //= caller;
        my $dsp = Data::Section::Pluggable->new(
            package => $package,
        );
        foreach my $plugin (@plugins) {
            if(is_plain_arrayref $plugin) {
                my($name, @args) = @$plugin;
                $dsp->add_plugin($name => @args);
            } else {
                $dsp->add_plugin($plugin);
            }
        }
        return bless [$dsp], $class;
    }

    sub FETCH ($self, $key) {
        return $self->[0]->get_data_section($key);
    }

    sub EXISTS ($self, $key) {
        exists $self->[0]->get_data_section->{$key};
    }

    sub FIRSTKEY ($self) {
        $self->[1] = [keys $self->[0]->get_data_section->%*];
        return $self->NEXTKEY;
    }

    sub NEXTKEY ($self, $=undef) {
        return shift $self->[1]->@*;
    }

    sub STORE ($self, $, $) {
        require Carp;
        Carp::croak("hash is read-only");
    }

    sub DELETE ($self, $) {
        require Carp;
        Carp::croak("hash is read-only");
    }

    sub CLEAR ($self) {
        require Carp;
        Carp::croak("hash is read-only");
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Hash::DataSection - Access __DATA__ section via tied hash

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 use Tie::Hash::DataSection;
 
 tie my %ds, 'Tie::Hash::DataSection';
 
 # "Hello World\n"
 print $ds{foo};
 
 __DATA__
 @@ foo
 Hello World

=head1 DESCRIPTION

This is a simple tie class that allows you to access data section
content via a Perl hash interface.

=head1 CONSTRUCTOR

 tie %hash, 'Tie::Hash::DataSection';
 tie %hash, 'Tie::Hash::DataSection', $package;
 tie %hash, 'Tie::Hash::DataSection', $package, @plugins;

The optional C<$package> argument can be used to change which 
package's C<__DATA__> section will be read from.

The optional C<@plugins> array contains a list of L<Data::Section::Pluggable>
plugins.  These can either be a:

=over 4

=item string

 tie %hash, 'Tie::Hash::DataSection', __PACKAGE__, $plugin;

the name of the plugin, for example C<trim> or C<json>.

=item array reference

 tie %hash, 'Tie::Hash::DataSection', __PACKAGE__, [$plugin, @args];

The first element of the array is a plugin name, subsequent values
will be passed in as arguments to the plugin.

=back

=head1 SEE ALSO

=over 4

=item L<Data::Section::Pluggable>

=item L<Data::Section::Writer>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
