package XML::Generator::PerlData;

use strict;
use warnings;
use XML::SAX::Base;
use vars qw($VERSION @ISA $NS_XMLNS $NS_XML);
use Scalar::Util qw(refaddr);

# some globals
$VERSION = '0.95';
@ISA = qw( XML::SAX::Base );
$NS_XML   = 'http://www.w3.org/XML/1998/namespace';
$NS_XMLNS = 'http://www.w3.org/2000/xmlns/';

sub new {
    my $proto = shift;
    my $self = $proto->SUPER::new( @_ );

    my %args = @_;

    delete $args{Handler} if defined $args{Handler};

    $self->{Namespaces} = { $NS_XMLNS => 'xmlns',
                            $NS_XML   => 'xml'
                          };
    $self->{DeclaredNamespaces} = {$NS_XMLNS => 'xmlns',
                                   $NS_XML   => 'xml'
                                  };

    $self->{InScopeNamespaceStack} = [];

    # _Parents needed for attribute vs. element fixing;
    $self->{_Parents} = [];

    $self->init( %args );
    return $self;
}

sub init {
    my $self = shift;
    my %args = @_;

    $self->{Keymap}               = $args{keymap}        if defined $args{keymap};
    $self->{RootName}             = $args{rootname}      if defined $args{rootname};
    $self->{SkipRoot}             = $args{skiproot}      if defined $args{skiproot};
    $self->{DefaultElementName}   = $args{defaultname}   if defined $args{defaultname};
    $self->{BindAttrs}            = 1                    if defined $args{bindattrs};
    $self->{Keymap}               ||= {};
    $self->{RootName}             ||= 'document';
    $self->{DefaultElementName}   ||= 'default';
    $self->{TokenReplacementChar} ||= '_';
    $self->{Seen}                 ||= {};

    if ( defined $args{namespaces} ) {
        foreach my $uri ( keys( %{$args{namespaces}} )) {
            $self->{Namespaces}->{"$uri"} = $args{namespaces}->{"$uri"};
        }
    }

    # allow perlified PIs
    if ( defined( $args{processing_instructions} )) {
        $self->{ProcessingInstructions} = [];

        if ( ref( $args{processing_instructions} ) eq 'ARRAY' ) {
            $self->{ProcessingInstructions} = $args{processing_instructions};
        }
        elsif ( ref( $args{processing_instructions} ) eq 'HASH' ) {
            foreach my $k ( keys( %{$args{processing_instructions}} )) {
                push @{$self->{ProcessingInstructions}}, ( $k => $args{processing_instructions}->{$k} );
            }
        }
    }

    # let 'em change handlers if they want.
    if ( defined $args{Handler} ) {
        $self->set_handler( $args{Handler} );
    }

    if ( defined( $args{attrmap} ) ) {
        $self->{Attrmap} = {};
        while ( my ($k, $v) = ( each( %{$args{attrmap}} ) )) {
            push @{$self->{Attrmap}->{$k}}, ref( $v ) ? @{$v} : $v;
        }
    }
    $self->{Attrmap} ||= {};

    if ( defined( $args{namespacemap} ) ) {
        $self->{Namespacemap} = {};
        while ( my ($k, $v) = ( each( %{$args{namespacemap}} ) )) {
            push @{$self->{Namespacemap}->{$k}}, ref( $v ) ? @{$v} : $v;
        }
    }
    $self->{Namespacemap} ||= {};

    if ( defined( $args{charmap} ) ) {
        $self->{Charmap} = {};
        while ( my ($k, $v) = ( each( %{$args{charmap}} ) )) {
            push @{$self->{Charmap}->{$k}}, ref( $v ) ? @{$v} : $v;
        }
    }
    $self->{Charmap} ||= {};

    # Skipelements:
    # Makes sense from an interface standpoint for the user
    # to pass an array ref, but it makes it more efficient to
    # implement if its a hash ref. Let's pull a little juju.

    my %skippers = ();
    if ( $args{skipelements} ) {
        %skippers = map { $_, 1} @{$args{skipelements}}
    }

    $self->{Skipelements} = \%skippers;

}

sub parse_start {
    my $self = shift;
    $self->init( @_ ) if scalar @_;

    $self->start_document( {} );

    if ( defined( $self->{ProcessingInstructions} ) && scalar( @{$self->{ProcessingInstructions}}) > 0 ) {
        my $pis = delete $self->{ProcessingInstructions};

        while ( my ( $target, $data ) = ( splice( @$pis, 0, 2)) ) {
            $self->parse_pi( $target, $data );
        }
    }

    unless ( defined $self->{SkipRoot} ) {
        $self->start_element( $self->_start_details( $self->{RootName} ) );
        push @{$self->{_Parents}}, $self->{RootName};
    }
}

sub parse_end {
    my $self = shift;
    unless ( defined $self->{SkipRoot} ) {
        $self->end_element( $self->_end_details( $self->{RootName} ) );
    }

    foreach my $uri ( keys( %{$self->{DeclaredNamespaces}} )) {
        next if $uri eq $NS_XMLNS;
        next if $uri eq $NS_XML;
        next if not defined $self->{DeclaredNamespaces}->{$uri};

        $self->end_prefix_mapping({ Prefix => $self->{DeclaredNamespaces}->{$uri},
                                    NamespaceURI => $uri
                                 });
    }

    return $self->end_document();
}

sub parse {
    my $self = shift;
    my $wtf = shift || die "No Data Passed!";
    $self->init( @_ );

    my $type = $self->get_type( $wtf );
    if ( defined $type ) {
        my $processor = lc( $type ) . 'ref2SAX';
        # process the document...
        $self->parse_start;
        $self->$processor( $wtf );
        $self->parse_end;
    }
    else {
        die "Data passed must be a reference.";
    }
}

sub parse_chunk {
    my $self = shift;
    my $wtf = shift || die "No Data Passed!";
    my $type = $self->get_type( $wtf );
    if ( defined $type ) {
        my $processor = lc( $type ) . 'ref2SAX';
        $self->$processor( $wtf );
    }
    else {
        die "Data passed must be a reference.";
    }
}

# Check if we have visited a given reference before
sub circular {
    my($self, $ref) = @_;
    my $addr = refaddr($ref);
    my $result = $self->{Seen}->{$addr};
    $self->{Seen}->{$addr} = 1;
    return $result;
}


sub hashref2SAX {
    my $self = shift;
    my $hashref= shift;

    my $char_data = '';

    return if $self->circular($hashref);

ELEMENT: foreach my $key (keys (%{$hashref} )) {
         my $value = $hashref->{$key};
         my $element_name = $self->_keymapped_name( $key );

         next if defined $self->{Skipelements}->{$element_name};

         if ( defined $self->{_Parents}->[-1] and defined $self->{Attrmap}->{$self->{_Parents}->[-1]} ) {
             foreach my $name ( @{$self->{Attrmap}->{$self->{_Parents}->[-1]}} ) {
                 next ELEMENT if $name eq $element_name;
             }
         }

         if ( defined $self->{_Parents}->[-1] and defined $self->{Charmap}->{$self->{_Parents}->[-1]} ) {
             if ( grep {$_ eq $element_name} @{$self->{Charmap}->{$self->{_Parents}->[-1]}}  ) {
                     $self->characters( {Data => $value });
                     next ELEMENT;
             }
         }

         my $type = $self->get_type( $value );

        if ( $type eq 'ARRAY' ) {
            push @{$self->{_Parents}}, $element_name;
            $self->arrayref2SAX( $value );
            pop (@{$self->{_Parents}});
        }
        elsif ( $type eq 'HASH' ) {
            # attr mojo
            my %attrs = ();
            if ( defined $self->{Attrmap}->{$element_name} ) {
                my @attr_names = ();
                ATTR: foreach my $child ( keys( %{$value} )) {
                    my $name = $self->_keymapped_name( $child );
                    if ( grep {$_ eq $name} @{$self->{Attrmap}->{$element_name}} ) {
                        if ( ref( $value->{$child} ) ) {
                           warn "Cannot use a reference value " . $value->{$child} . " for key '$child' as XML attribute\n";
                           next ATTR;
                        }

                       $attrs{$name} = $value->{$child};
                    }
                }
            }
            $self->start_element( $self->_start_details( $element_name, \%attrs ) );
            push @{$self->{_Parents}}, $element_name;
            $self->hashref2SAX( $value );
            pop (@{$self->{_Parents}});
            $self->end_element( $self->_end_details( $element_name ) );
        }
        else {
            $self->start_element( $self->_start_details( $element_name ) );
            $self->characters( {Data => $value} );
            $self->end_element( $self->_end_details( $element_name ) );
        }
    }
}

sub arrayref2SAX {
    my $self = shift;
    my $arrayref= shift;
    my $passed_name = shift || $self->{_Parents}->[-1];
    my $temp_name = $self->_keymapped_name( $passed_name );

    return if $self->circular($arrayref);

    my $element_name;
    my $i;

ELEMENT: for ( $i = 0; $i < @{$arrayref}; $i++ ) {
        if ( ref( $temp_name ) eq 'ARRAY' ) {
            my $ntest = $temp_name->[$i] || $self->{DefaultElementName};
            if ( ref( $ntest ) eq 'CODE' ) {
                $element_name = &{$ntest}();
            }
            else {
                $element_name = $self->_keymapped_name( $ntest );
            }
        }
        else {
            $element_name = $temp_name;
        }

        next if defined $self->{Skipelements}->{$element_name};

        my $type = $self->get_type( $arrayref->[$i] );

        my $value = $arrayref->[$i];

        if ( $type eq 'ARRAY' ) {
            push @{$self->{_Parents}}, $element_name;
            $self->arrayref2SAX( $value );
            pop (@{$self->{_Parents}});
        }
        elsif ( $type eq 'HASH' ) {
            # attr mojo
            my %attrs = ();
            if ( defined $self->{Attrmap}->{$element_name} ) {
                my @attr_names = ();
                ATTR: foreach my $child ( keys( %{$value} )) {
                    my $name = $self->_keymapped_name( $child );
                    if ( grep {$_ eq $name} @{$self->{Attrmap}->{$element_name}} ) {
                        if ( ref( $value->{$child} ) ) {
                           warn "Cannot use a reference value " . $value->{$child} . " for key '$child' as XML attribute\n";
                           next ATTR;
                        }

                       $attrs{$name} = $value->{$child};
                    }
                }
            }
            $self->start_element( $self->_start_details( $element_name, \%attrs ) );
            push @{$self->{_Parents}}, $element_name;
            $self->hashref2SAX( $arrayref->[$i] );
            pop (@{$self->{_Parents}});
            $self->end_element( $self->_end_details( $element_name ) );
        }
        else {
            $self->start_element( $self->_start_details( $element_name ) );
            $self->characters( {Data => $arrayref->[$i]} );
            $self->end_element( $self->_end_details( $element_name ) );
        }
    }
}

sub get_type {
    my $self = shift;
    my $wtf = shift;

    my $type = ref( $wtf );
    if ( $type ) {
        if ( $type eq 'ARRAY' or $type eq 'HASH' or $type eq 'SCALAR') {
            return $type;
        }
        else {
            # we were passed an object, yuk.
            # props to barrie slaymaker for the tip here... mine was much fuglier. ;-)
            if ( UNIVERSAL::isa( $wtf, "HASH" ) ) {
                return 'HASH';
            }
            elsif ( UNIVERSAL::isa( $wtf, "ARRAY" ) ) {
                return 'ARRAY';
            }
            elsif ( UNIVERSAL::isa( $wtf, "SCALAR" ) ) {
                return 'SCALAR';
            }
            else {
                die "Unhandlable reference passed: $type \n";
            }
        }

    }
    else {
        return '_plain';
    }
}

###
# Interface helpers
###

sub add_namespace {
    my $self = shift;
    my %args = @_;
    unless ( defined $args{prefix} and defined $args{uri} ) {
        warn "Invalid arguments passed to add_namespace, skipping.";
        return;
    }
    $self->{Namespaces}->{"$args{uri}"} = $args{prefix};
}

sub namespacemap {
    my $self = shift;
    my %nsmap;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            %nsmap = %{$_[0]};
        }
        else {
            %nsmap = @_;
        }

        while ( my ($k, $v) = each ( %nsmap ) ) {
            if ( ref( $v ) ) {
                $self->{Namespacemap}->{$k} = $v;
            }
            else {
                $self->{Namespacemap}->{$k} = [ $v ];
            }
        }
    }

    return wantarray ? %{$self->{Namespacemap}} : $self->{Namespacemap};
}

sub add_namespacemap {
    my $self = shift;
    my %args = @_;

    foreach my $uri ( keys( %args )) {
        push @{$self->{Namespacemap}->{"$uri"}}, $args{$uri};
    }
}

sub delete_namespacemap {
    my $self = shift;
    my @mapped;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            @mapped = @{$_[0]};
        }
        else {
            @mapped = @_;
        }
        foreach my $name ( @mapped ) {
            foreach my $uri ( keys( %{$self->{Namespacemap}} )) {
                my $i;
                for ($i = 0; $i < scalar @{$self->{Namespacemap}->{$uri}}; $i++) {
                   splice @{$self->{Namespacemap}->{$uri}}, $i, 1 if $self->{Namespacemap}->{$uri}->[$i] eq $name;
                }
                delete $self->{Namespacemap}->{$uri} unless scalar @{$self->{Namespacemap}->{$uri}} > 0;
            }
        }
    }
}

sub attrmap {
    my $self = shift;
    my %attrmap;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            %attrmap = %{$_[0]};
        }
        else {
            %attrmap = @_;
        }

        while ( my ($k, $v) = each( %attrmap )) {
            if ( ref( $v ) ) {
                $self->{Attrmap}->{$k} = $v;
            }
            else {
                $self->{Attrmap}->{$k} = [ $v ];
            }
        }
    }

    return wantarray ? %{$self->{Attrmap}} : $self->{Attrmap};
}

sub add_attrmap {
    my $self = shift;
    my %attrmap;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            %attrmap = %{$_[0]};
        }
        else {
            %attrmap = @_;
        }

        while ( my ($k, $v) = each ( %attrmap ) ) {
            if ( ref( $v ) ) {
                $self->{Attrmap}->{$k} = $v;
            }
            else {
                $self->{Attrmap}->{$k} = [ $v ];
            }
        }
    }
}

sub delete_attrmap {
    my $self = shift;
    my @mapped;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            @mapped = @{$_[0]};
        }
        else {
            @mapped = @_;
        }
        foreach my $name ( @mapped ) {
            delete $self->{Attrmap}->{$name} if $self->{Attrmap}->{$name};
        }
    }
}

sub charmap {
    my $self = shift;
    my %charmap;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            %charmap = %{$_[0]};
        }
        else {
            %charmap = @_;
        }

        while ( my ($k, $v) = each( %charmap )) {
            if ( ref( $v ) ) {
                $self->{Charmap}->{$k} = $v;
            }
            else {
                $self->{Charmap}->{$k} = [ $v ];
            }
        }
    }

    return wantarray ? %{$self->{Charmap}} : $self->{Charmap};
}

sub add_charmap {
    my $self = shift;
    my %charmap;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            %charmap = %{$_[0]};
        }
        else {
            %charmap = @_;
        }

        while ( my ($k, $v) = each ( %charmap ) ) {
            if ( ref( $v ) ) {
                $self->{Charmap}->{$k} = $v;
            }
            else {
                $self->{Charmap}->{$k} = [ $v ];
            }
        }
    }
}

sub delete_charmap {
    my $self = shift;
    my @mapped;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            @mapped = @{$_[0]};
        }
        else {
            @mapped = @_;
        }
        foreach my $name ( @mapped ) {
            delete $self->{Charmap}->{$name} if $self->{Charmap}->{$name};
        }
    }
}

sub add_keymap {
    my $self = shift;
    my %keymap;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            %keymap = %{$_[0]};
        }
        else {
            %keymap = @_;
        }

        foreach my $name ( keys( %keymap )) {
            $self->{Keymap}->{$name} = $keymap{$name};
        }
    }
}

sub delete_keymap {
    my $self = shift;
    my @mapped;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            @mapped = @{$_[0]};
        }
        else {
            @mapped = @_;
        }
        foreach my $name ( @mapped ) {
            delete $self->{Keymap}->{$name} if $self->{Keymap}->{$name};
        }
    }
}

sub add_skipelements {
    my $self = shift;
    my @skippers;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            @skippers = @{$_[0]};
        }
        else {
            @skippers = @_;
        }
        foreach my $name ( @skippers ) {
            $self->{Skipelements}->{$name} = 1;
        }
    }
}

sub delete_skipelements {
    my $self = shift;
    my @skippers;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            @skippers = @{$_[0]};
        }
        else {
            @skippers = @_;
        }
        foreach my $name ( @skippers ) {
            delete $self->{Skipelements}->{$name} if $self->{Skipelements}->{$name};
        }
    }
}

sub rootname {
    my ($self, $rootname) = @_;

    # ubu: add a check to warn them if the processing has already begun?
    if ( defined $rootname ) {
        $self->{RootName} = $rootname;
    }

    return $self->{RootName};
}

sub bindattrs {
    my $self = shift;
    my $flag = shift;
    if ( defined($flag) ) {
        if ($flag == 0) {
            $self->{BindAttrs} = undef;
        }
        else {
            $self->{BindAttrs} = 1;
        }
    }

    return $self->{BindAttrs};

}

sub defaultname {
    my ($self, $dname) = @_;

    if ( defined $dname ) {
        $self->{DefaultElementName} = $dname;
    }
    return $self->{DefaultElementName};
}

sub keymap {
    my $self = shift;
    my %keymap;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            %keymap = %{$_[0]};
        }
        else {
            %keymap = @_;
        }
        $self->{Keymap} = \%keymap;
    }

    return wantarray ? %{$self->{Keymap}} : $self->{Keymap};
}

sub skipelements {
    my $self = shift;
    my @skippers;
    if ( scalar( @_ ) > 0 ) {
        if ( ref( $_[0] )) {
            @skippers = @{$_[0]};
        }
        else {
            @skippers = @_;
        }
        my %skippers = map { $_, 1} @skippers;
        $self->{Skipelements} = \%skippers;
    }

    my @skippers_out = keys %{$self->{Skipelements}} || ();

    return wantarray ? @skippers_out : \@skippers_out;
}

#XXX
sub parse_pi {
    my $self = shift;
    my ( $target, $data_in ) = @_;

    my $data_out = '';

    my $ref = $self->get_type( $data_in );

    if ( $ref eq 'SCALAR' ) {
        $data_out = $$data_in;
    }
    elsif ( $ref eq 'ARRAY' ) {
        $data_out = join ' ', @{$data_in};
    }
    elsif ( $ref eq 'HASH' ) {
        foreach my $k (keys( %{$data_in} )) {
            $data_out .= qq|$k="| . $data_in->{$k} . qq|" |;
        }
    }
    else {
        $data_out = $data_in;
    }

    $self->processing_instruction({ Target => $target, Data => $data_out });
}

###
# Convenience helpers to make 'stream style' friendly
###

sub start_tag {
    my $self = shift;
    my $element_name = shift;
    my %attrs = @_;
    $self->start_element( $self->_start_details( $element_name, \%attrs ) );
    push @{$self->{_Parents}}, $element_name;

}

sub end_tag {
    my ($self, $tagname) = @_;
    $self->end_element( $self->_end_details( $tagname ) );
    pop (@{$self->{_Parents}});
}

####
# Internal Helpers
###

sub _keymapped_name {
    my ($self, $name) = @_;
    my $element_name;
    if ( defined $self->{Keymap}->{$name} ) {
        my $temp_name = $self->{Keymap}->{$name};

        if ( ref( $temp_name ) eq 'CODE' ) {
            $element_name = &{$temp_name}( $name );
        }
        else {
            $element_name = $temp_name;
        }
    }
    elsif ( defined $self->{Keymap}->{'*'} ) {
        my $temp_name = $self->{Keymap}->{'*'};

        if ( ref( $temp_name ) eq 'CODE' ) {
            $element_name = &{$temp_name}( $name );
        }
        else {
            $element_name = $temp_name;
        }
    }
    else {
        $element_name = $name;
    }
}

sub _start_details {
    my $self = shift;
    my ($element_name, $attrs) = @_;
    my %real_attrs;
    foreach my $attr (keys(%{$attrs})) {
        my $uri;
        my $prefix;
        my $qname;
        my $lname;

        if ( defined $self->{BindAttrs} ) {
            ($uri, $prefix, $qname, $lname) = $self->_namespace_fixer( $attr );
        }
        else {
            $lname = $self->_name_fixer( $attr );
            $qname = $lname;
        }

        my $key_uri = $uri || "";
        $real_attrs{"\{$key_uri\}$lname"} = {
                                             Name         => $qname,
                                             LocalName    => $lname,
                                             Prefix       => $prefix,
                                             NamespaceURI => $uri,
                                             Value => $attrs->{$attr} };

    }

    if ( scalar( keys( %{$self->{Namespaces}} )) > scalar( keys( %{$self->{DeclaredNamespaces}} )) ) {
        my @unseen_uris = grep { not defined $self->{DeclaredNamespaces}->{$_} } keys( %{$self->{Namespaces}} );
        foreach my $uri ( @unseen_uris ) {
            my $qname;
            my $prefix;
            my $lname;
            my $key_uri;
            my $ns_uri;

            # this, like the Java version of SAX2, explicitly follows production 5.2 of the
            # W3C Namespaces rec.-- specifically:
            # http://www.w3.org/TR/1999/REC-xml-names-19990114/#defaulting

            if ( $self->{Namespaces}->{$uri} eq '#default' ) {
                $qname = 'xmlns';
                $lname = 'xmlns';
                $prefix =  undef;
                $key_uri = "";
                $ns_uri = undef;
            }
            else {
                $lname = $self->{Namespaces}->{$uri};
                $prefix = 'xmlns';
                $qname = $prefix . ':' . $lname;
                #$key_uri = "";
                $key_uri = $NS_XMLNS;
                $ns_uri = $NS_XMLNS;
            }
            $real_attrs{"\{$key_uri\}$lname"} = {
                                            Name         => $qname,
                                            LocalName    => $lname,
                                            Prefix       => $prefix,
                                            NamespaceURI => $ns_uri,
                                            Value        => $uri };

            # internal
            $self->{DeclaredNamespaces}->{$uri} = $prefix;

            # fire events if needed.
            if ( defined $prefix ) {
                $self->start_prefix_mapping( { Prefix => $self->{Namespaces}->{$uri},
                                               NamespaceURI => $uri
                                             });
            }
        }
    }

    my ($uri, $prefix, $qname, $lname) = $self->_namespace_fixer( $element_name );
    my %element = (LocalName    => $lname,
                   Name         => $qname,
                   Prefix       => $prefix,
                   NamespaceURI => $uri,
                   Attributes   => \%real_attrs,
                  );

    if ( defined $uri and grep { $element_name eq $_ } @{$self->{Namespacemap}->{$uri}} ) {
        push @{$self->{InScopeNamespaceStack}}, [$uri, $prefix];
    }

    return \%element;
}

sub _end_details {
    my $self = shift;
    my ($element_name) = @_;
    my ( $uri, $prefix, $qname, $lname ) = $self->_namespace_fixer( $element_name );
    my %element = (LocalName    => $lname,
                   Name         => $qname,
                   Prefix       => $prefix,
                   NamespaceURI => $uri,
                  );

    if ( defined $uri and grep { $element_name eq $_ } @{$self->{Namespacemap}->{$uri}} ) {
         pop @{$self->{InScopeNamespaceStack}};
    }

    return \%element;
}

sub _namespace_fixer {
    my ( $self, $node_name ) = @_;
    my $prefix;
    my $qname;
    my $uri;
    my $lname = $self->_name_fixer( $node_name );

    foreach my $ns ( keys( %{$self->{Namespacemap}} )) {
        if ( grep { $node_name eq $_ } @{$self->{Namespacemap}->{"$ns"}} ) {
            $uri = $ns;
        }
    }

    if ( defined( $uri ) ) {
        $prefix = $self->{Namespaces}->{"$uri"};
        if ( $prefix eq '#default' ) {
            $prefix = undef;
        }
        else {
            $qname = $prefix . ':' . $lname;
        }
        $qname ||= $lname;
    }
    else {
        if ( defined $self->{InScopeNamespaceStack}->[-1] ) {
            ($uri, $prefix) = @{$self->{InScopeNamespaceStack}->[-1]};
            if ( $prefix ) {
                $qname = $prefix . ':' . $lname;
            }
        }
    }
    $qname ||= $lname;
    return ($uri, $prefix, $qname, $lname);
}


sub _name_fixer {
    my ($self, $name) = @_;
    # UNICODE WARNING
    $name =~ s|^[^a-zA-Z_:]{1}|_|g;
    $name =~ tr|a-zA-Z0-9._:-|_|c;

    return $name;
}

1;
__END__

=head1 NAME

XML::Generator::PerlData - Perl extension for generating SAX2 events from nested Perl data structures.

=head1 SYNOPSIS

  use XML::Generator::PerlData;
  use SomeSAX2HandlerOrFilter;

  ## Simple style ##

  # get a deeply nested Perl data structure...
  my $hash_ref = $obj->getScaryNestedDataStructure();

  # create an instance of a handler class to forward events to...
  my $handler = SomeSAX2HandlerOrFilter->new();

  # create an instance of the PerlData driver...
  my $driver  = XML::Generator::PerlData->new( Handler => $handler );

  # generate XML from the data structure...
  $driver->parse( $hash_ref );


  ## Or, Stream style ##

  use XML::Generator::PerlData;
  use SomeSAX2HandlerOrFilter;

  # create an instance of a handler class to forward events to...
  my $handler = SomeSAX2HandlerOrFilter->new();

  # create an instance of the PerlData driver...
  my $driver  = XML::Generator::PerlData->new( Handler => $handler );

  # start the event stream...
  $driver->parse_start();

  # pass the data through in chunks
  # (from a database handle here)
  while ( my $array_ref = $dbd_sth->fetchrow_arrayref ) {
      $driver->parse_chunk( $array_ref );
  }

  # end the event stream...
  $driver->parse_end();

and you're done...

=head1 DESCRIPTION

XML::Generator::PerlData provides a simple way to generate SAX2 events
from nested Perl data structures, while providing finer-grained control
over the resulting document streams.

Processing comes in two flavors: B<Simple Style> and B<Stream Style>:

In a nutshell, 'simple style' is best used for those cases where you have a a single
Perl data structure that you want to convert to XML as quickly and painlessly as possible. 'Stream
style' is more useful for cases where you are receiving chunks of data (like from a DBI handle)
and you want to process those chunks as they appear. See B<PROCESSING METHODS> for more info about
how each style works.

=head1 CONSTRUCTOR METHOD AND CONFIGURATION OPTIONS

=head2 new

(class constructor)

B<Accepts:> An optional hash of configuration options.

B<Returns:> A new instance of the XML::Generator::PerlData class.

Creates a new instance of XML::Generator::PerlData.

While basic usage of this module is designed to be simple and straightforward,
there is a small host of options available to help ensure that the SAX event streams
(and by extension the XML documents) that are created from the data structures you
pass are in just the format that you want.

=head3 Options

=over 4

=item * B<Handler> (required)

XML::Generator::PerlData is a SAX Driver/Generator. As such, it
needs a SAX Handler or Filter class to forward its events to. The value for this
option must be an instance of a SAX2-aware Handler or Filter.

=item * B<rootname> (optional)

Sets the name of the top-level (root) element. The default is 'document'.

=item * B<defaultname> (optional)

Sets the default name to be used for elements when no other logical name
is available (think lists-of-lists). The default is 'default'.

=item * B<keymap> (optional)

Often, the names of the keys in a given hash do not map directly to the XML
elements names that you want to appear in the resulting document. The option
contains a set of keyname->element name mappings for the current process.

=item * B<skipelements> (optional)

Passed in as an array reference, this option sets the internal list of keynames
that will be skipped over during processing. Note that any descendant structures
belonging to those keys will also be skipped.

=item * B<attrmap> (optional)

Used to determine which 'children' of a given hash key/element-name will
be forwarded as attributes of that element rather than as child elements.

(see CAVEATS for a discussion of the limitations of this method.)

=item * B<namespaces> (optional)

Sets the internal list of namespace/prefix pairs for the current process. It takes
the form of a hash, where the keys are the URIs of the given namespace and the
values are the associated prefix.

To set a default (unprefixed) namespace, set the prefix to '#default'.

=item * B<namespacemap> (optional)

Sets which elements in the result will be bound to which declared namespaces. It
takes the form of a hash of key/value pairs where the keys are one of the declared
namespace URIs that are relevant to the current process and the values are either
single key/element names or an array reference of key/element names.

=item * B<skiproot> (optional)

When set to a defined value, this option blocks the generator from adding
the top-level root element when parse() or parse_start() and parse_end()
are called.

I<Do not> use this option unless you absolutely sure you know what you
are doing and why, since the resulting event stream will most likely
produce non-well-formed XML.

=item * B<bindattrs> (optional)

When set to a defined value, this option tells the generator to bind attributes to the same namespace as element that contains them. By default
attributes will be unbound and unprefixed.

=item * B<processing_instructions> (optional)

This option provides a way to include XML processing instructions events into the generated stream before the root element is emitted. The value of this key can be either a hash reference or an array reference of hash references. For example, when connected to L<XML::SAX::Writer>:

    $pd->new( Handler => $writer_instance,
              rootname => 'document',
              processing_instructions => {
                'xml-stylesheet' => {
                     href => '/path/to/stylesheet.xsl',
                     type => 'text/xml',
                 },
              });

would generate

  <?xml version="1.0"?>
  <?xml-stylesheet href="/path/to/stylesheet.xsl" type="text/xsl" ?>
  <document>
    ...

Where multiple processing instructions will have the same target and/or where the document order of those PIs matter, an array reference should be used instead. For example:

    $pd->new( Handler => $writer_instance,
              rootname => 'document',
              processing_instructions => [
                'xml-stylesheet' => {
                    href => '/path/to/stylesheet.xsl',
                    type => 'text/xml',
                },
                'xml-stylesheet' => {
                    href => '/path/to/second/stylesheet.xsl',
                    type => 'text/xml',
                }

           ]);

would produce:

  <?xml version="1.0"?>
  <?xml-stylesheet href="/path/to/stylesheet.xsl" type="text/xsl" ?>
  <?xml-stylesheet href="/path/to/second/stylesheet.xsl" type="text/xsl" ?>
  <document>
    ...

=back

=head1 PROCESSING METHODS

=head2 Simple style processing

=over 4

=item B<parse>

B<Accepts:> A reference to a Perl data structure. Optionally, a hash of config options.

B<Returns:> [none]

The core method used during 'simple style' processing, this method accepts a reference
to a Perl data structure and, based on the options passed, produces a stream of SAX events
that can be used to transform that structure into XML. The optional second argument is
a hash of config options identical to those detailed in the OPTIONS section of the
the new() constructor description.

B<Examples:>

  $pd->parse( \%my_hash );

  $pd->parse( \%my_hash, rootname => 'recordset' );

  $pd->parse( \@my_list, %some_options );

  $pd->parse( $my_hashref );

  $pd->parse( $my_arrayref, keymap => { default => ['foo', 'bar', 'baz'] } );

=back

=head2 Stream style processing

=over 4

=item B<parse_start>

B<Accepts:> An optional hash of config options.

B<Returns:> [none]

Starts the SAX event stream and (unless configured not to)
fires the event the top-level root element. The optional argument is
a hash of config options identical to those detailed in the OPTIONS section of the
the new() constructor description.

B<Example:>

  $pd->parse_start();


=item B<parse_end>

B<Accepts:> [none].

B<Returns:> Varies. Returns what the final Handler returns.

Ends the SAX event stream and (unless configured not to)
fires the event to close the top-level root element.

B<Example:>

  $pd->parse_end();

=item B<parse_chunk>

B<Accepts:> A reference to a Perl data structure.

B<Returns:> [none]


The core method used during 'stream style' processing, this method accepts a reference
to a Perl data structure and, based on the options passed, produces a stream of SAX events
that can be used to transform that structure into XML.

B<Examples:>

  $pd->parse_chunk( \%my_hash );

  $pd->parse_chunk( \@my_list );

  $pd->parse_chunk( $my_hashref );

  $pd->parse_chunk( $my_arrayref );

=back

=head1 CONFIGURATION METHODS

All config options can be passed to calls to the new() constructor using the
typical "hash of named properties" syntax. The methods below offer direct
access to the individual options (or ways to add/remove the smaller definitions
contained by those options).

=over 4

=item B<init>

B<Accepts:> The same configuration options that can be passed to the new() constructor.

B<Returns:> [none]

See the list of B<OPTIONS> above in the definition of new() for details.

=item B<rootname>

B<Accepts:> A string or [none].

B<Returns:> The current root name.

When called with an argument, this method sets the name of the top-level (root) element. It
always returns the name of the current (or new) root name.

B<Examples:>

  $pd->rootname( $new_name );

  my $current_root = $pd->rootname();

=item B<defaultname>

B<Accepts:> A string or [none]

B<Returns:> The current default element name.

When called with an argument, this method sets the name of the default element. It
always returns the name of the current (or new) default name.

B<Examples:>

  $pd->defaultname( $new_name );

  my $current_default = $pd->defaultname();

=item B<keymap>

B<Accepts:> A hash (or hash reference) containing a series of keyname->elementname mappings or [none].

B<Returns:> The current keymap hash (as a plain hash, or hash reference depending on caller context).

When called with a hash (hash reference) as its argument, this method sets/resets the entire internal
keyname->elementname mappings definitions (where 'keyname' means the name of a given
key in the hash and 'elementname' is the name used when firing SAX events for that key).

In addition to simple name->othername mappings, value of a keymap option can also a reference
to a subroutine (or an anonymous sub). The keyname will be passed as the sole argument to
this subroutine and the sub is expected to return the new element name. In the cases of nested
arrayrefs, no keyname will be passed, but you can still generate the name from scratch.

Extending that idea, keymap will also accept a default mapping using the key '*' that will
be applied to all elements that do have an explict mapping configured.

To add new mappings or remove existing ones without having to reset the whole list of
mappings, see add_keymap() and delete_keymap() respectively.

If your are using "stream style" processing, this method should be used with caution since
altering this mapping during processing may result in not-well-formed XML.

B<Examples:>

  $pd->keymap( keyname    => 'othername',
               anotherkey => 'someothername' );

  $pd->keymap( \%mymap );

  # make all tags lower case
  $pd->keymap( '*'    => sub{ return lc( $_[0];} );

  # process keys named 'keyname' with a local sub
  $pd->keymap( keyname    => \&my_namer,

  my %kmap_hash = $pd->keymap();

  my $kmap_hashref = $pd->keymap();

=item B<add_keymap>

B<Accepts:> A hash (or hash reference) containing a series of keyname->elementname mappings.

B<Returns:> [none]

Adds a series of keyname->elementname mappings (where 'keyname' means the name of a given
key in the hash and 'elementname' is the name used when firing SAX events for that key).

B<Examples:>

  $pd->add_keymap( keyname => 'othername' );

  $pd->add_keymap( \%hash_of_mappings );

=item B<delete_keymap>

B<Accepts:> A list (or array reference) of element/keynames.

B<Returns:> [none]

Deletes a list of keyname->elementname mappings (where 'keyname' means the name of a given
key in the hash and 'elementname' is the name used when firing SAX events for that key).

This method should be used with caution since altering this mapping during processing
may result in not-well-formed XML.

B<Examples:>

  $pd->delete_keymap( 'some', 'key', 'names' );

  $pd->delete_keymap( \@keynames );

=item B<skipelements>

B<Accepts:> A list (or array reference) containing a series of key/element names or [none].

B<Returns:> The current skipelements array (as a plain list, or array reference depending on caller context).

When called with an array (array reference) as its argument, this method sets/resets the entire internal
skipelement definitions (which determines which keys will not be 'parsed' during processing).

To add new mappings or remove existing ones without having to reset the whole list of
mappings, see add_skipelements() and delete_skipelements() respectively.

B<Examples:>

  $pd->skipelements( 'elname', 'othername', 'thirdname' );

  $pd->skipelements( \@skip_names );

  my @skiplist = $pd->skipelements();

  my $skiplist_ref = $pd->skipelements();

=item B<add_skipelements>

B<Accepts:> A list (or array reference) containing a series of key/element names.

B<Returns:> [none]

Adds a list of key/element names to skip during processing.

B<Examples:>

  $pd->add_skipelements( 'some', 'key', 'names' );

  $pd->add_skipelements( \@keynames );

=item B<delete_skipelements>

B<Accepts:> A list (or array reference) containing a series of key/element names.

B<Returns:> [none]

Deletes a list of key/element names to skip during processing.

B<Examples:>

  $pd->delete_skipelements( 'some', 'key', 'names' );

  $pd->delete_skipelements( \@keynames );

=item B<charmap>

B<Accepts:> A hash (or hash reference) containing a series of parent/child keyname pairs or [none].

B<Returns:> The current charmap hash (as a plain hash, or hash reference depending on caller context).

When called with a hash (hash reference) as its argument, this method sets/resets the entire internal
keyname/elementname->characters children mappings definitions (where 'keyname' means the name of a given
key in the hash and 'characters children' is list containing the nested keynames that should be passed as
the text children of the element named 'keyname' (instead of being processed as child elements or attributes).

To add new mappings or remove existing ones without having to reset the whole list of
mappings, see add_charmap() and delete_charmap() respectively.

See CAVEATS for the limitations that relate to this method.

B<Examples:>

  $pd->charmap( elname => ['list', 'of', 'nested', 'keynames' );

  $pd->charmap( \%mymap );

  my %charmap_hash = $pd->charmap();

  my $charmap_hashref = $pd->charmap();

=item B<add_charmap>

B<Accepts:> A hash or hash reference containing a series of parent/child keyname pairs.

B<Returns:> [none]

Adds a series of parent-key -> child-key relationships that define which of the
possible child keys will be processed as text children of the created 'parent'
element.

B<Examples:>

  $pd->add_charmap( parentname =>  ['list', 'of', 'child', 'keys'] );

  $pd->add_charmap( parentname =>  'childkey' );

  $pd->add_charmap( \%parents_and_kids );

=item B<delete_charmap>

B<Accepts:> A list (or array reference) of element/keynames.

B<Returns:> [none]

Deletes a list of parent-key -> child-key relationships from the instance-wide
hash of "parent->nested names to pass as text children definitions. If you
need to alter the list of child names (without deleting the parent key) use
add_charmap() to reset the parent-key's definition.

B<Examples:>

  $pd->delete_charmap( 'some', 'parent', 'keys' );

  $pd->delete_charmap( \@parentkeynames );

=item B<attrmap>

B<Accepts:> A hash (or hash reference) containing a series of parent/child keyname pairs or [none].

B<Returns:> The current attrmap hash (as a plain hash, or hash reference depending on caller context).

When called with a hash (hash reference) as its argument, this method sets/resets the entire internal
keyname/elementname->attr children mappings definitions (where 'keyname' means the name of a given
key in the hash and 'attr children' is list containing the nested keynames that should be passed as
attributes of the element named 'keyname' (instead of as child elements).

To add new mappings or remove existing ones without having to reset the whole list of
mappings, see add_attrmap() and delete_attrmap() respectively.

See CAVEATS for the limitations that relate to this method.

B<Examples:>

  $pd->attrmap( elname => ['list', 'of', 'nested', 'keynames' );

  $pd->attr( \%mymap );

  my %attrmap_hash = $pd->attrmap();

  my $attrmap_hashref = $pd->attrmap();

=item B<add_attrmap>

B<Accepts:> A hash or hash reference containing a series of parent/child keyname pairs.

B<Returns:> [none]

Adds a series of parent-key -> child-key relationships that define which of the
possible child keys will be processed as attributes of the created 'parent'
element.

B<Examples:>

  $pd->add_attrmap( parentname =>  ['list', 'of', 'child', 'keys'] );

  $pd->add_attrmap( parentname =>  'childkey' );

  $pd->add_attrmap( \%parents_and_kids );

=item B<delete_attrmap>

B<Accepts:> A list (or array reference) of element/keynames.

B<Returns:> [none]

Deletes a list of parent-key -> child-key relationships from the instance-wide
hash of "parent->nested names to pass as attributes" definitions. If you
need to alter the list of child names (without deleting the parent key) use
add_attrmap() to reset the parent-key's definition.

B<Examples:>

  $pd->delete_attrmap( 'some', 'parent', 'keys' );

  $pd->delete_attrmap( \@parentkeynames );

=item B<bindattrs>

B<Accepts:> 1 or 0 or [none].

B<Returns:> undef or 1 based on the current state of the bindattrs option.

Consider:

  <myns:foo bar="quux"/>

and

  <myns:foo myns:bar="quux"/>

are I<not> functionally equivalent.

By default, attributes will be forwarded as I<not> being bound to the namespace
of the containing element (like the first example above). Setting this
option to a true value alters that behavior.

B<Examples:>

  $pd->bindattrs(1); # attributes now bound and prefixed.

  $pd->bindattrs(0);

  my $is_binding = $pd->bindattrs();

=item B<add_namespace>

B<Accepts:> A hash containing the defined keys 'uri' and 'prefix'.

B<Returns:> [none]

Add a namespace URI/prefix pair to the instance-wide list of XML namespaces
that will be used while processing. The reserved prefix '#default' can
be used to set the default (unprefixed) namespace declaration for elements.

B<Examples:>

  $pd->add_namespace( uri    => 'http://myhost.tld/myns',
                      prefix => 'myns' );

  $pd->add_namespace( uri    => 'http://myhost.tld/default',
                      prefix => '#default' );

See namespacemap() or the namespacemap option detailed in new() for details
about how to associate key/element name with a given namespace.

=item B<namespacemap>

B<Accepts:> A hash (or hash reference) containing a series of uri->key/element name mappings or [none].

B<Returns:> The current namespacemap hash (as a plain hash, or hash reference depending on caller context).

When called with a hash (hash reference) as its argument, this method sets/resets the entire internal
namespace URI->keyname/elementname mappings definitions (where 'keyname' means the name of a given
key in the hash and 'namespace URI' is a declared namespace URI for the given process).

To add new mappings or remove existing ones without having to reset the whole list of
mappings, see add_namespacemap() and delete_namespacemap() respectively.

If your are using "stream style" processing, this method should be used with caution since
altering this mapping during processing may result in not-well-formed XML.

B<Examples:>


  $pd->add_namespace( uri    => 'http://myhost.tld/myns',
                      prefix => 'myns' );

  $pd->namespacemap( 'http://myhost.tld/myns' => elname );

  $pd->namespacemap( 'http://myhost.tld/myns' => [ 'list',  'of',  'elnames' ] );

  $pd->namespacemap( \%mymap );

  my %nsmap_hash = $pd->namespacemap();

  my $nsmap_hashref = $pd->namespacemap();

=item B<add_namespacemap>

B<Accepts:> A hash (or hash reference) containing a series of uri->key/element name mappings

B<Returns:> [none]

Adds one or more namespace->element/keyname rule to the instance-wide
list of mappings.

B<Examples:>

  $pd->add_namespacemap( 'http://myhost.tld/foo' => ['some', 'list', 'of' 'keys'] );

  $pd->add_namespacemap( %new_nsmappings );

=item B<remove_namespacemap>

B<Accepts:> A list (or array reference) of element/keynames.

B<Returns:> [none]

Removes a list of namespace->element/keyname rules to the instance-wide
list of mappings.

B<Examples:>

  $pd->delete_namespacemap( 'foo', 'bar', 'baz' );

  $pd->delete_namespacemap( \@list_of_keynames );

=back

=head1 SAX EVENT METHODS

As a subclass of XML::SAX::Base, XML::Generator::PerlData allows you to
call all of the SAX event methods directly to insert arbitrary events
into the stream as needed. While its use in this way is probably a
I<Bad Thing> (and only relevant to "stream style" processing)  it is
good to know that such fine-grained access is there if you need it.

With that aside, there may be cases (again, using the "stream style") where
you'll want to insert single elements into the output (wrapping each
array in series of arrays in single 'record' elements, for example).

The following methods may be used to simplify this task by allowing you
to pass in simple element name strings and have the result 'just work' without
requiring an expert knowledge of the Perl SAX2 implementation or
forcing you to keep track of things like namespace context.

Take care to ensure that every call to start_tag() has a corresponding call to end_tag()
or your documents will not be well-formed.

=over 4

=item B<start_tag>

B<Accepts:> A string containing an element name and an optional hash of simple key/value attributes.

B<Returns:> [none]

B<Examples:>

  $pd->start_tag( $element_name );

  $pd->start_tag( $element_name, id => $generated_id );

  $pd->start_tag( $element_name, %some_attrs );

=item B<end_tag>

B<Accepts:> A string containing an element name.

B<Returns:> [none]

B<Examples:>

  $pd->end_tag( $element_name );

=back

=head1 CAVEATS

In general, XML is based on the idea that every bit of data is going to have a
corresponding name (Elements, Attributes, etc.). While this is not at all a
Bad Thing, it means that some Perl data structures do not map cleanly onto
an XML representation.

Consider:

  my %hash = ( foo => ['one', 'two', 'three'] );

How do you represent that as XML? Is it three 'foo' elements, or
is it a 'foo' parent element with 3 mystery children? XML::Generator::PerlData
chooses the former. Or:

  <foo>one</foo>
  <foo>two</foo>
  <foo>three</foo>

Now consider:

  my @lol = ( ['one', 'two', 'three'], ['four', 'five', 'six'] );

In this case you wind up with a pile of elements named 'default'. You can
work around this by doing $pd->add_keymap( default => ['list', 'of', 'names'] )
but that only works if you know how many entries are going to be in each nested
list.

The practical implication here is that the current version of XML::Generator::PerlData
favors data structures that are based on hashes of hashes for deeply nested structures (especally
when using B<Simple Style> processing) and some options like C<attrmap> do not work for
arrays at all. Future versions will address these issues if sanely possible.

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 COPYRIGHT

(c) Kip Hampton, 2002-2014, All Rights Reserved.

=head1 LICENSE

This module is released under the Perl Artistic Licence and
may be redistributed under the same terms as perl itself.

=head1 SEE ALSO

L<XML::SAX>, L<XML::SAX::Writer>.

=cut

