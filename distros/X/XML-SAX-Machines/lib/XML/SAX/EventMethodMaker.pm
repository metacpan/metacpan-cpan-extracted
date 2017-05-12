package XML::SAX::EventMethodMaker;
{
  $XML::SAX::EventMethodMaker::VERSION = '0.46';
}
# ABSTRACT: SAX event names, creation of methods from templates


@ISA = qw( Exporter );
@EXPORT_OK = qw(
    sax_event_names 
    missing_methods 
    compile_methods 
    compile_missing_methods
);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

use strict ;

## First, a table in easy to maintain format :)
##
## Key to flags field:
##    <int>   = SAX versions supported in.  We'll need to make this more
##              powerful (support ranges) if we get in to subversions.
my %event_flags = (
    Han      => "Handler",
    DTD      => "DTDHandler",
    Cnt      => "ContentHandler",
    Doc      => "DocumentHandler",
    Dec      => "DeclHandler",
    Err      => "ErrorHandler",
    Ent      => "EntityResolver",
    Lex      => "LexicalHandler",
);


my %parse_method_flags = (
    Parse    => "ParseMethods",
);


my %event_table = qw(
    start_document            Han;1Doc;Cnt
    end_document              Han;1Doc;Cnt
    start_element             Han;1Doc;Cnt
    end_element               Han;1Doc;Cnt
    characters                Han;1Doc;Cnt
    start_prefix_mapping      Han;----;Cnt
    end_prefix_mapping        Han;----;Cnt
    processing_instruction    Han;1Doc;Cnt
    ignorable_whitespace      Han;1Doc;Cnt
    skipped_entity            Han;----;Cnt
    set_document_locator      Han;1Doc;Cnt
    notation_decl             Han;----;----;DTD
    unparsed_entity_decl      Han;----;----;DTD
    element_decl              Han;----;----;----;----;Dec
    attribute_decl            Han;----;----;----;----;Dec
    internal_entity_decl      Han;----;----;----;----;Dec
    external_entity_decl      Han;----;----;----;----;Dec
    comment                   Han;----;----;----;Lex
    start_dtd                 Han;----;----;----;Lex
    end_dtd                   Han;----;----;----;Lex
    start_cdata               Han;----;----;----;Lex
    end_cdata                 Han;----;----;----;Lex
    start_entity              Han;----;----;----;Lex
    end_entity                Han;----;----;----;Lex
    warning                   Han;----;----;----;----;----;Err
    error                     Han;----;----;----;----;----;Err
    fatal_error               Han;----;----;----;----;----;Err
    resolve_entity            Han;----;----;----;----;----;----;Ent

    xml_decl                  1Han;----;----;1DTD
    attlist_decl              1Han;----;----;1DTD
    doctype_decl              1Han;----;----;1DTD
    entity_decl               1Han;----;----;1DTD
    entity_reference          1Han;1Doc
);

my %parse_methods_table = qw(
    parse                     1:2Parse
    parse_file                2Parse
    parse_string              2Parse
    parse_uri                 2Parse
);


use Carp;

## Now, tear that apart so it's queryable
my %events_db;

for my $event ( keys %event_table, keys %parse_methods_table ) {
    my $flags = exists $event_table{$event}
        ? $event_table{$event}
        : $parse_methods_table{$event};

    for ( split /[;-]+/, $flags ) {
        my ( $versions, $type ) = /^([\d:]*)(.*)/
            or die "Couldn't parse '$_'";

        my @versions = split /\D+/, $versions;

        die "Unknown flag '$_'"
            unless exists $event_flags{$type}
                || exists $parse_method_flags{$type};

        @versions = ( 1, 2 ) unless @versions;

        $type = exists $event_flags{$type}
            ? $event_flags{$type} 
            : $parse_method_flags{$type};

        push @{$events_db{$type}}, $event;
        for my $version ( @versions ) {
            push @{$events_db{"$version,$type"}}, $event;
            $events_db{$version}->{$event} = undef
                unless $type eq "ParseMethods";
        }
    }
}

#use Data::Dumper; local $Data::Dumper::Indent=1; warn Dumper( \%events_db );


my %legal_query_terms = map {
    ( $_ => undef );
} ( 1, 2, values %event_flags, values %parse_method_flags );
   

sub sax_event_names {
    ## This should be really common
    return keys %event_table unless @_;

    {
        my @baduns  = grep ! exists $legal_query_terms{$_}, @_;
        croak "Illegal sax_event_name query term(s): ",
            join ", ", map "'$_'", @baduns
            if @baduns;
    }

    my @versions;
    my @types;
    while (@_) {
        $_[0] =~ /^\d+$/
            ? push @versions, shift
            : push @types,    shift;
    }

    ## These might be relatively common as well.
    return keys %{$events_db{$versions[0]}}
        if @versions == 1 && ! @types;

    return @{$events_db{$types[0]}}
        if ! @versions && @types == 1;

    @versions = (1,2)               unless @versions;
    @types    = values %event_flags unless @types;

    my @keys = map {
        my $version = $_;
        map {
            my $type = $_;
            "$version,$type";
        } @types
    } @versions ;

    return keys %{{
        map {
            map {
                ( $_ => undef );
            } @{$events_db{$_}}
        } @keys
    }};
}



sub missing_methods {
    my $where = shift;
    $where = ref $where || $where;
    no strict 'refs';
    return grep ! exists ${"${where}::"}{$_}, @_;
}



sub compile_methods {
    my ( $where, $template ) = ( shift, shift );
    $where = ref $where || $where;

    my @code;

    for ( @_ ) {
        push @code, $template;
        $code[-1] =~ s/<EVENT>|<METHOD>/$_/g;
    }

    eval join "", "package $where;", @code, "1" or die $@;
}



sub compile_missing_methods {
    my ( $where, $template ) = ( shift, shift );

    compile_methods $where, $template, missing_methods $where, @_;
}


1;

__END__

=pod

=head1 NAME

XML::SAX::EventMethodMaker - SAX event names, creation of methods from templates

=head1 VERSION

version 0.46

=head1 SYNOPSIS

    use XML::SAX::EventMethodMaker qw(
        sax_event_names missing_methods compile_methods
    );

  ## Getting event names by handler type and SAX version
    my @events          = sax_event_names;
    my @dtd_events      = sax_event_names "DTDHandler";
    my @sax1_events     = sax_event_names 1;
    my @sax1_dtd_events = sax_event_names 1, "DTDHandler";

  ## Figuring out what events a class or object does not provide
    my @missing = missing_methods $class, @events ;

  ## Creating all SAX event methods
    compile_methods $class, <<'TEMPLATE_END', sax_event_names;
    sub <EVENT> {
        my $self = shift;
        ... do something ...

        ## Pass the event up to the base class
        $self->SUPER::<EVENT>( @_ );
    }
    TEMPLATE_END

  ## Creating some methods
    compile_methods $class, <<'TEMPLATE_END', @method_names;
    ...
    TEMPLATE_END

  ## Creating only missing event handlers
    compile_missing_methods $class, <<'TEMPLATE_END';
    ...
    TEMPLATE_END

=head1 DESCRIPTION

In building SAX machines, it is often handle to build a set of event
handlers from a common template.  This helper library (or class)
provides the database of handler names, queryable by type, and

=head1 NAME

XML::SAX::EventMethodMaker - SAX event names, creation of methods from templates

=head1 Functions

=over

=item sax_event_names

    my @names = sax_event_names @query_terms;

Takes a list of query terms and returns all matching events.

Query terms may be:
    - a SAX version number: 1 or 2 (no floating point or ranges)
    - Handler
    - DTDHandler
    - ContentHandler
    - DocumentHandler
    - DeclHandler
    - ErrorHandler
    - EntityResolver
    - LexicalHandler

In addition to normal SAX events, there are also "parse" events:
    - ParseMethods

Unrecognized query terms cause exceptions.

If no query terms are provided, then all event names from all versions
are returned except for parse methods (parse, parse_uri, ...).

If any version numbers are supplied, then only events from those version
numbers are returned.  No support for noninteger version numbers is
provided, nor for ranges.  So far, only two SAX versions exist in Perl, 1 and
2.

If any handler types are provided, then only events of those types are
returned.  Handler types are case insensitive.

In other words, all returned events must match both a version number and
a handler type.

No support for boolean logic is provided.

=item missing_methods

    my @missing = missing_methods __PACKAGE__, @event_names;
    my @missing = missing_methods $object, @event_names;

This subroutine looks to see if the object or class has declared
event handler methods for the named events.  Any events that haven't
been declared are returned.

It is sufficient to use subroutine prototypes to prevent shimming AUTOLOADed
(or otherwise lazily compiled) methods:

    sub start_document ;

=item compile_methods

    compile_methods __PACKAGE__, $template, @method_names;
    compile_methods $object,     $template, @method_names;

Compiles the given template for each given event name, substituting
the event name for the string <EVENT> or <METHOD> in the template.
There is no difference between these two tags, they are provided to
only to let you make your templates more readable to you.

=item compile_missing_methods

    compile_missing_methods __PACKAGE__, $template, @method_names;
    compile_missing_methods $objects,    $template, @method_names;

Shorthand for calls like

    compile_methods __PACKAGE__, $template,
        missing_methods __PACKAGE__, @method_names;

=back

=head1 Due Credit

The database of handlers by type was developed by Kip Hampton,
modified by Robin Berjon, and pilfered and corrupted by me.

=head1 LICENSE

    Database Copyright 2002, Barrie Slaymaker, Kip Hampton, Robin Berjon
    Code Copyright 2002, Barrie Slaymaker <barries@slaysys.com>

You may use this under the terms of the Artistic, GNU Public, or BSD
licences, as you see fit.

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
