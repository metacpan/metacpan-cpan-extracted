package Thorium;
{
  $Thorium::VERSION = '0.510';
}
BEGIN {
  $Thorium::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Configuration management framework

1;



=pod

=head1 NAME

Thorium - Configuration management framework

=head1 VERSION

version 0.510

=head1 ABOUT

L<Thorium> is a collection of libraries for configuration management. Notable
features:

=over 4

=item * generate files from templates via L<Template>

=item * enables complex data structures from the YAML backing store

=item * optionally a console GUI to easily adjust configuration

=back

Building complex applications that are highly configurable can be difficult. You
want to balance an easy end user configuration with powerful tools. L<Thorium>
aims to fill that gap other configuration systems don't.

=begin html

<p>With Thorium this is possible:</p>

<p>Introduction screen:</p>

<img src="http://www.npjh.com/pictures/public/thorium/thorium-example-1.png" alt="introduction screen">

<p>Configuration screen:</p>

<img src="http://www.npjh.com/pictures/public/thorium/thorium-example-2.png" alt="configuration screen">

<p>Changing value screen:</p>

<img src="http://www.npjh.com/pictures/public/thorium/thorium-example-3.png" alt="changing value screen">

=end html

=head1 QUICK START

The full source code is available in this distributions F<examples> directory.

=head2 1. Choose A Namespace

We will be extending L<Thorium::BuildConf> and L<Thorium::Conf>. I suggest
something unique that won't show up on CPAN. For this example we are going to
use C<Pizza>. And our app will be creating a pizza.

=head2 2. Extend L<Thorium::BuildConf>

This example will use a fictional L<Thorium::BuildConf::Knob> for demonstration
purposes. You are free and encouraged to create your own specific knobs.

    package Pizza::BuildConf;

    use Moose;

    use Pizza::BuildConf::Knob::CrustType;

    extends 'Thorium::BuildConf';

    has '+type' => (default => 'Pizza Maker');

    has '+files' => ('default' => 'awesome-pizza.tt2');

    has '+knobs' => (
        'default' => sub {
            [
                Pizza::BuildConf::Knob::CrustType->new(
                    'conf_key_name' => 'pizza.crust_type',
                    'name'          => 'Crust type',
                    'question'      => 'What kind of crust do you want?'
                )
            ];
        }
    );

    __PACKAGE__->meta->make_immutable;
    no Moose;

We now have configurable item for the user.

=head2 3. Create conf/presets/defaults.yaml

This file will be the base for all configurable data that we will be accessing
through a derived L<Thorium::Conf> object. Use L<YAML::XS> compatible syntax.

    ---
    pizza:
        crust_type: thin

Now in your L<Template> file, F<awesome-pizza.tt2>, you have access to that data
via a C<.> separated syntax. For example, to get the crust type you'd use:

    [% pizza.crust_type %]

You may also alter this data in your own F<defaults.yaml> derived "preset". See
L<Thorium::BuildConf> for more.

=head2 4. Extend L<Thorium::Conf>

This will be our class to access to the YAML data we created in Step 3:

    package Pizza::Conf;

    use Moose;

    extends 'Thorium::Conf';

    # core
    use File::Spec;

    # CPAN
    use Dir::Self;

    has '+component_name' => ('default' => 'pizza-maker');

    has '+component_root' => ('default' => File::Spec->catdir(__DIR__, '..', '..'));

    __PACKAGE__->meta->make_immutable;
    no Moose;

F<local.yaml> is the resulting saved file of all configuration data. More about
overriding defaults in L<Thorium::Conf>.

=head2 5. Create the configure Script

    #!/usr/bin/env perl

    use strict;

    use Find::Lib '../lib';
    use Find::Lib 'lib';

    use Pizza::BuildConf;

    Pizza::BuildConf->new(
        'conf_type' => 'Pizza::Conf',
    )->run;

=head2 6. Run configure

    ./configure

At this point you should see console GUI.

If you go to the C<Configure> option you should see your crust type.

=head1 CREDITS

Thanks to Sean Quinlan for contributing design and feedback.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

