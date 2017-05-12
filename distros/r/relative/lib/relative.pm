package relative;
use strict;
use Carp;
use UNIVERSAL::require;

{
    no strict "vars";
    $VERSION = '0.04';
}

=head1 NAME

relative - Load modules with relative names

=head1 VERSION

Version 0.04

=cut

sub import {
    return if @_ <= 1;  # called with no args
    my ($package, @args) = @_;
    my ($caller) = caller();
    my @loaded = ();

    # read the optional parameters
    my %param = ();

    if (ref $args[0] eq 'HASH') {
        %param = %{shift @args}
    }
    elsif (ref $args[0] eq 'ARRAY') {
        %param = @{shift @args}
    }

    # go through the args list, looking to parameters with the dash syntax,
    # and module names and optional arguments
    my %args_for = ();  # modules arguments
    my @modules  = ();  # will be filled with only the module names
    my $prev     = "";

    for my $item (@args) {
        # if $prev is true, the previous thing (parameter or module name)
        # is expecting a value
        if ($prev) {
            # this is a parameter
            if (index($prev, "-") == 0) {
                $param{substr($prev, 1)} = $item;
                $prev = "";
            }
            # this is a module name
            else {
                push @modules, $prev;

                # this isn't a ref, so the previous module is just stored
                # and the current item becomes the new $prev
                if (not ref $item) {
                    $prev = $item;
                }
                # this is an arrayref, which will be used as the import list
                # for the module name in $prev
                elsif (ref $item eq "ARRAY") {
                    $args_for{$prev} = $item;
                    $prev = "";
                }
                else {
                    my $that = "a ".lc(ref $item)."ref";
                    croak "error: Don't know how to deal with $that (after '$prev')";
                }
            }
        }
        else {
            if ($item eq "-aliased") {
                # -aliased is a flag, so it doesn't expect a value
                $param{aliased} = 1
            }
            else {
                $prev = $item
            }
        }
    }

    push @modules, $prev if $prev;

    # determine the base name
    my $base = exists $param{to} ? $param{to} : $caller;

    # load the modules
    for my $relname (@modules) {
        # resolve the module relative name to absolute name
        my $module = "$base\::$relname";
        1 while $module =~ s/::\w+::(?:\.\.)?::/::/g;
        $module =~ s/^:://;

        # load the module, die if it failed
        $module->require or croak _clean($@);

        # import the symbols from the loaded module into the caller module
        if (exists $args_for{$relname}) {
            my $args = $args_for{$relname};

            # an arguments list has been defined, but only call import if 
            # there are some arguments
            if (@$args) {
                my $args_str = join ", ", map {"q/\Q$_\E/"} @$args;
                eval qq{ package $caller; $module->import($args_str); 1 }
                    or croak _clean($@);
            }
        }
        else {
            # use the default import method
            eval qq{ package $caller; $module->import; 1 } or croak _clean($@);
        }

        # define alias if asked to
        if ($param{aliased}) {
            my ($alias) = $module =~ /\b(\w+)$/;
            eval qq{ package $caller; sub $alias () { q/$module/ } };
        }

        # keep a list of the loaded modules
        push @loaded, $module;
    }

    return wantarray ? @loaded : $loaded[-1]
}


sub _clean {
    my ($msg) = @_;
    $msg =~ s/ at .*relative.pm line \d+\.\s*$//s;
    return $msg
}


=head1 SYNOPSIS

    package BigApp::Report;

    use relative qw(Create Publish);
    # loads BigApp::Report::Create, BigApp::Report::Publish

    use relative qw(..::Utils);
    # loads BigApp::Utils

    use relative -to => "Enterprise::Framework" => qw(Base Factory);
    # loads Enterprise::Framework::Base, Enterprise::Framework::Factory


=head1 DESCRIPTION

This module allows you to load modules using only parts of their name, 
relatively to the current module or to a given module. Module names are 
by default searched below the current module, but can be searched upper 
in the hierarchy using the C<..::> syntax.

In order to further loosen the namespace coupling, C<import> returns 
the full names of the loaded modules, making object-oriented code easier
to write:

    use relative;

    my ($Maker, $Publisher) = import relative qw(Create Publish);
    my $report    = $Maker->new;
    my $publisher = $Publisher->new;

    my ($Base, $Factory) = import relative -to => "Enterprise::Framework"
                                => qw(Base Factory);
    my $thing = $Factory->new;

This can also be written using aliases:

    use relative -aliased => qw(Create Publish);
    my $report    = Create->new;
    my $publisher = Publisher->new;

    use relative -to => "Enterprise::Framework", -aliased => qw(Base Factory);
    my $thing = Factory->new;


=head1 IMPORT OPTIONS

Import options can be given as an hashref or an arrayref as the first 
argument:

    # options as a hashref
    import relative { param => value, ... },  qw(Name ...);

    # options as an arrayref
    import relative [ param => value, ... ],  qw(Name ...);

In order to simplyfing syntax, options can also be given as dash-prefixed
params:

    import relative -param => value, qw(name ...);

Available options:

=over

=item *

C<to> can be used to indicate another hierarchy to search modules inside.

B<Examples>

    # in a hashref:
    import relative { to => "Some::Other::Namespace" }, qw(Other Modules);

    # as dash-param:
    import relative -to => "Some::Other::Namespace", qw(Other Modules);

=item *

C<aliased> will create constants, named with the last component of each 
loaded module, returning its corresponding full name. Yes, this feature 
is very similar to what C<aliased> does as it was added per Ovid request C<:-)>

B<Examples>

    # in a hashref:
    import relative { aliased => 1 }, qw(Whack Zlonk);
    my $frob = Whack->fizzle;

    # as dash-param:
    import relative -aliased, qw(Whack Zlonk);
    my $frob = Whack->fizzle;

=back

C<import> will C<die> as soon as a module can't be loaded. 

C<import> returns the full names of the loaded modules when called in 
list context, or the last one when called in scalar context.


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-relative at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=relative>.
I will be notified, and then you'll automatically be notified of progress 
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc relative

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/relative>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/relative>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=relative>

=item * Search CPAN

L<http://search.cpan.org/dist/relative>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Aristotle Pagaltzis, Andy Armstrong, Ken Williams 
and Curtis Poe for their suggestions and ideas.


=head1 COPYRIGHT & LICENSE

Copyright 2007 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

"evitaler fo dnE" # "End of relative"
