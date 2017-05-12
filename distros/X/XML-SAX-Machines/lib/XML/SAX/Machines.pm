package XML::SAX::Machines;
{
  $XML::SAX::Machines::VERSION = '0.46';
}

# ABSTRACT: manage collections of SAX processors


use strict;
use Carp;
use Exporter;
use vars qw( $debug @ISA @EXPORT_OK %EXPORT_TAGS );

## TODO: Load this mapping from the config file, or generalize 
## this.
my %machines = (
    ByRecord    => "XML::SAX::ByRecord",
    Machine     => "XML::SAX::Machine",
    Manifold    => "XML::SAX::Manifold",
    Pipeline    => "XML::SAX::Pipeline",
    Tap         => "XML::SAX::Tap",
);

@ISA = qw( Exporter );
@EXPORT_OK = keys %machines;
%EXPORT_TAGS = ( "all" => \@EXPORT_OK );

## Note: we don't put a constructor function in each package for two reasons.
## The first is that I want to generalize this mechanism in to a
## Class::CtorShortcut.  The second, more marginal reason is that the
## easiest way to do that
## would be to make each of the machines be @ISA( Exporter ) and I don't
## want to add to to machines' @ISA lists for speed reasons, since
## below we manually search @ISA hierarchies for config settings.
sub import {
    my $self = $_[0];
    for ( @_[1..$#_] ) {
        for ( substr( $_, 0, 1 ) eq ":" ? @{$EXPORT_TAGS{substr $_, 1}} : $_ ) {
            croak "Unknown SAX machine: '$_'" unless exists $machines{$_};
            carp "Loading SAX machine '$_'" if $debug;
            eval "use $machines{$_}; sub $_ { $machines{$_}->new( \@_ ) }; 1;"
                or die $@;
        }
    }

    goto &Exporter::import;
}


sub _read_config {
    delete $INC{"XML/SAX/Machines/ConfigDefaults.pm"};
    delete $INC{"XML/SAX/Machines/SiteConfig.pm"};

    eval "require XML::SAX::Machines::ConfigDefaults;";
    eval "require XML::SAX::Machines::SiteConfig;";

    my $xsm = "XML::SAX::Machines";

    for ( qw(
        LegalProcessorClassOptions
        ProcessorClassOptions
    ) ) {
        no strict "refs";
        
	## I don't like creating these just to default them, but perls
	## 5.005003 and older (at least) emit a "used only once, possible
	## type" warngings that local $^W = 0 doesn't silence.
	${__PACKAGE__."::ConfigDefaults::$_"} ||= {};
	${__PACKAGE__."::SiteConfig::$_"}     ||= {};
        ${__PACKAGE__."::Config::$_"} = {
            %{ ${__PACKAGE__."::ConfigDefaults::$_"} },
            %{ ${__PACKAGE__."::SiteConfig::$_"    } },
        };
    }

    ## Now check the config.
    my @errors;
    for my $class ( keys %$XML::SAX::Machines::Config::ProcessorClassOptions ) {
        push(
            @errors,
            "Illegal ProcessorClassOptions option name in $class: '$_'\n"
        ) for grep(
            ! exists $XML::SAX::Machines::Config::LegalProcessorClassOptions->{$_},
            keys %{$XML::SAX::Machines::Config::ProcessorClassOptions->{$class}}
        ) ;
    }

    die @errors,
        "    check XML::SAX::Machines::SiteConfig",
        " (or perhaps XML::SAX::Machines::ConfigDefaults)\n",
        "    Legal names are: ",
        join(
            ", ",
            map 
                "'$_'",
                keys %$XML::SAX::Machines::Config::LegalProcessorClassOptions
        )
        if @errors;
}

_read_config;


sub _config_as_string {
    require Data::Dumper;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::QuoteKeys = 1;
    Data::Dumper->Dump(
        [ $XML::SAX::Machines::Config::ProcessorClassOptions ],
        [ 'Processors' ]
    );
}

## TODO: Move the config file accessors to a Config package.
#=head2 Config File accessors
#
#Right now config files are read only.
#
#=cut
#
#=over
#
#=item processor_class_option
# 
#    if ( XML::SAX::Machines->processor_class_option
#        $class, "ConstructWithHashedOptions"
#    ) {
#        ....
#    }
##
#Sees if an option is set for a processor class or the first class in it's
#ISA hierarchy for which the option is defined.  Caches results for speed.
#The cache is cleared if the config file is re-read.
#
#$class may also be an object.
#
#Yes this is a wordy API; it shouldn't be needed too often :).
#
#=cut
#
sub processor_class_option {
    my $self = shift;
    my ( $class,  $option ) = @_;

    croak "Can't set processor class options yet"
        if @_ > 2;

    Carp::cluck
        "Unknown ProcessorClassOptions option '$option'.\n",
        "    Expected options are: ",
        join(
            ", ",
            map "'$_'",
                sort keys
                    %$XML::SAX::Machines::Config::ExpectedProcessorClassOptions
        ),
        "\n",
        "    Perhaps a call to XML::SAX::Machine->expected_processor_class_options( '$option' ) would help?"
        unless
            $XML::SAX::Machines::Config::ExpectedProcessorClassOptions->{$option};

    $class = ref $class || $class;

    return            $XML::SAX::Machines::Config::ProcessorClassOptions->{$class}->{$option}
        if    exists  $XML::SAX::Machines::Config::ProcessorClassOptions->{$class}
           && exists  $XML::SAX::Machines::Config::ProcessorClassOptions->{$class}->{$option}
           && defined $XML::SAX::Machines::Config::ProcessorClassOptions->{$class}->{$option};

    ## Hmm, gotta traipse through @ISA.
    my $isa = do {
        no strict "refs";
        eval "require $class;" unless @{"${class}::ISA"};
        \@{"${class}::ISA"};
    };

    my $value;
    for ( @$isa ) {
        next if $_ eq "Exporter" || $_ eq "DynaLoader" ;
        $value = $self->processor_class_option( $_, $option );
        last if defined $value;
    }

    return undef unless $value;

    ## Cache the result.
    $XML::SAX::Machines::Config::ProcessorClassOptions->{$class}->{$option}
        = $value;
    return $value;
}

#=item expected_processor_class_options
#
#    XML::SAX::Machine->expected_processor_class_options( MyOption );
#
#This is used to inform XML::SAX::Machines that there's an option your
#module expects to be able to retrieve.  It does *not* check the options
#in the config file, it checks options requests so as to catch typoes in
#code.
#
#Yes this is a wordy API; it shouldn't be needed too often :).
#
#=cut

sub expected_processor_class_options {
    my $self = shift;

    $XML::SAX::Machines::Config::ExpectedProcessorClassOptions->{$_} = 1
        for @_;
}

#=back
#
#=cut

1;

__END__

=pod

=head1 NAME

XML::SAX::Machines - manage collections of SAX processors

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    use XML::SAX::Machines qw( :all );

    my $m = Pipeline(
        "My::Filter1",   ## My::Filter1 autoloaded in Pipeline()
        "My::Filter2",   ## My::Filter2     "       "      "
        \*STDOUT,        ## XML::SAX::Writer also loaded
    );

    $m->parse_uri( $uri ); ## A parser is autoloaded via
                           ## XML::SAX::ParserFactory if
                           ## My::Filter1 isn't a parser.

    ## To import only individual machines:
    use XML::SAX::Machines qw( Manifold );

    ## Here's a multi-pass machine that reads one document, runs
    ## it through 5 filtering channels (one channel at a time) and
    ## reassembles it in to a single document.
    my $m = Manifold(
        "My::TableOfContentsExtractor",
        "My::AbstractExtractor",
        "My::BodyFitler",
        "My::EndNotesFilter",
        "My::IndexFilter",
    );

    $m->parse_string( $doc );

=head1 DESCRIPTION

SAX machines are a way to gather and manage SAX processors without going
nuts.  Or at least without going completely nuts.  Individual machines
can also be like SAX processors; they don't need to parse or write
anything:

   my $w = XML::SAX::Writer->new( Output => \*STDOUT );
   my $m = Pipeline( "My::Filter1", "My::Filter2", { Handler => $w } );
   my $p = XML::SAX::ParserFactory->new( handler => $p );

More documentation to come; see L<XML::SAX::Pipeline>,
L<XML::SAX::Manifold>, and L<XML::SAX::Machine> for now.

Here are the machines this module knows about:

    ByRecord  Record oriented processing of documents.
              L<XML::SAX::ByRecord>

    Machine   Generic "directed graph of SAX processors" machines.
              L<XML::SAX::Machine>

    Manifold  Multipass document processing
              L<XML::SAX::Manifold>

    Pipeline  A linear sequence of SAX processors
              L<XML::SAX::Pipeline>

    Tap       An insertable pass through that examines the
              events without altering them using SAX processors.
              L<XML::SAX::Tap>

=head2 Config file

As mentioned in L</LIMITATIONS>, you might occasionally need to edit the config
file to tell XML::SAX::Machine how to handle a particular SAX processor (SAX
processors use a wide variety of API conventions).

The config file is a the Perl module XML::SAX::Machines::SiteConfig, which
contains a Perl data structure like:

    package XML::SAX::Machines::SiteConfig;

    $ProcessorClassOptions = {
        "XML::Filter::Tee" => {
            ConstructWithHashedOptions => 1,
        },
    };

So far $Processors is the only available configuration structure.  It contains
a list of SAX processors with known special needs.

Also, so far the only special need is the ConstructWithHashes option which
tells XML::SAX::Machine to construct such classes like:

    XML::Filter::Tee->new(
        { Handler => $h }
    );

instead of

    XML::Filter::Tee->new( Handler => $h );

B<WARNING> If you modify anything, modify only
XML::SAX::Machines::SiteConfig.pm.  Don't alter
XML::SAX::Machines::ConfigDefaults.pm or you will lose your changes when you
upgrade.

TODO: Allow per-app and per-machine overrides of options.  When needed.

=head1 NAME

    XML::SAX::Machines - manage collections of SAX processors

=head1 AUTHORS

Barrie Slaymaker

=head1 LICENCE

Copyright 2002-2009 by Barrie Slaymaker.

This software is free.  It is licensed under the same terms as Perl itself.

=head1 AUTHORS

=over 4

=item *

Barry Slaymaker

=item *

Chris Prather <chris@prather.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Barry Slaymaker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
