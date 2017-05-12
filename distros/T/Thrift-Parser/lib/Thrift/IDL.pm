package Thrift::IDL;

=head1 NAME

Thrift::IDL - Parser and OO representation of a Thrift interface definintion language (IDL)

=head1 SYNOPSIS

  my $idl = Thrift::IDL->parse_thrift_file('tutorial.thrift');

  foreach my $service ($idl->services) {
      printf "Offers service '%s':\n", $service->name;
  }


=head1 DESCRIPTION

The Thrift interface definition language (IDL) file is a structured file describing all the data types, services, methods, etc. of a Thrift interface.  This is necessary if you need an in-memory representation of the Thrift schema.

=cut

use strict;
use warnings;
use Parse::RecDescent;
use Cwd qw(abs_path);
use Thrift::IDL::Comment;
use Thrift::IDL::Constant;
use Thrift::IDL::CppInclude;
use Thrift::IDL::Definition;
use Thrift::IDL::DocumentHeader;
use Thrift::IDL::Document;
use Thrift::IDL::Enum;
use Thrift::IDL::Exception;
use Thrift::IDL::Field;
use Thrift::IDL::Header;
use Thrift::IDL::Include;
use Thrift::IDL::Method;
use Thrift::IDL::Namespace;
use Thrift::IDL::Senum;
use Thrift::IDL::Service;
use Thrift::IDL::Struct;
use Thrift::IDL::Type;
use Thrift::IDL::Type::Base;
use Thrift::IDL::Type::Custom;
use Thrift::IDL::Type::List;
use Thrift::IDL::Type::Map;
use Thrift::IDL::Type::Set;
use Thrift::IDL::TypeDef;

our ($wrap, $g_current_header);

our %reserved_keywords = map { $_ => 1 } qw(
    abstract and args as assert break case class continue declare def default 
    del delete do elif else elseif except exec false finally float for 
    foreach function global goto if implements import in inline instanceof interface is 
    lambda native new not or pass public print private protected raise return sizeof 
    static switch synchronized this throw transient true try unsigned var virtual volatile 
    while with union yield register
);

=head1 METHODS

=head2 parse_thrift_file ($input_filename, $debug)

  my $document = Thrift::IDL->parse_thrift_file('tutorial.thrift');

Given a filename of a Thrift IDL file and an optional boolean for debug output, parse the input file into a L<Thrift::IDL::Document> object and return it.  The debug flag will cause verbose output on STDERR.

=cut

sub parse_thrift_file {
    my ($class, $input_fn, $debug) = @_;
	return $class->_new_from_parsed({ file => $input_fn }, $debug);
}

=head2 parse_thrift ($data, $debug)

  my $document = Thrift::IDL->parse_thrift(...);

Given a scalar of a Thrift IDL file and an optional boolean for debug output, parse the input into a L<Thrift::IDL::Document> object and return it.  The debug flag will cause verbose output on STDERR.

NOTE: If the thrift references other documents via an B<include> statement, you'll need to use absolute paths

=cut

sub parse_thrift {
    my ($class, $data, $debug) = @_;
	return $class->_new_from_parsed({ buffer => $data }, $debug);
}

sub parser {
    my ($class, $debug) = @_;

    $::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
    $::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
    $::RD_HINT   = 1; # Give out hints to help fix problems.
    #$::RD_AUTOACTION = q { [@item[0..$#item]] };

    $wrap = sub {
        my $self = shift;
        my $class = delete $self->{class};
        die "No class!" unless $class;
        $class = 'Thrift::IDL::' . $class;
        my $return = bless $self, $class;
        if ($return->can('setup')) {
            $return->setup;
        }

        # Store a reference to the current global DocumentHeader
        $self->{header} = $g_current_header;

        print "Created $class $return\n" if $debug;
        return $return;
    };

    my $parser = Parse::RecDescent->new(<<'EOF') or die "Invalid grammer!";
        document: (comment | header | definition)(s)

        comment: (
                /\/[*] .*? [*]\//sx
                | /^\/\/ .*/x
                | /^[#] .*/x
            )
            { $Thrift::IDL::wrap->({ class => 'Comment', value => $item[1] }) }

        header: ( include | cpp_include | namespace )

        definition: (
                const
                | typedef
                | enum
                | senum
                | struct
                | service
            )
            { $item[1] }

        include:
            'include' quoted_string
            { $Thrift::IDL::wrap->({ class => 'Include', value => $item[2] }) }

        cpp_include:
            'cpp_include' quoted_string
            { $Thrift::IDL::wrap->({ class => 'CppInclude', value => $item[2] }) }

        namespace:
            'namespace' (word | '*') word
            { $Thrift::IDL::wrap->({ class => 'Namespace', scope => $item[2], value => $item[3] }) }

        const:
            'const' type name '=' value
            { $Thrift::IDL::wrap->({ class => 'Constant', type => $item[2], name => $item[3], value => $item[5] }) }

        typedef:
            'typedef' type name
            { $Thrift::IDL::wrap->({ class => 'TypeDef', type => $item[2], name => $item[3] }) }

        enum:
            'enum' name '{' enum_pair(s /,/) '}'
            { $Thrift::IDL::wrap->({ class => 'Enum', name => $item[2], values => $item[4] }) }

        senum:
            'senum' name '{' quoted_string(s /,/) '}'
            { $Thrift::IDL::wrap->({ class => 'Senum', name => $item[2], values => $item[4] }) }

        enum_pair:
            name ('=' number)(?)
            { [ $item[1] => $item[2][0] ] }

        struct:
            ('struct' | 'exception') name '{' field_statement(s /,?/) (',' | '') '}'
            { $Thrift::IDL::wrap->({ class => $item[1] eq 'struct' ? 'Struct' : 'Exception', name => $item[2], children => $item[4] }) }

        field_statement:
            comment | field

        field:
            number ':' ('optional')(?) type name ('=' value)(?)
            { $Thrift::IDL::wrap->({ class => 'Field', id => $item[1], optional => $item[3][0] ? 1 : undef, type => $item[4], name => $item[5], default_value => $item[6][0] }) }

        service:
            'service' name ('extends' word)(?) '{' service_statement(s) '}'
            { $Thrift::IDL::wrap->({ class => 'Service', name => $item[2], extends => $item[3][0], children => $item[5] }) }

        service_statement:
            comment | method_statement

        method_statement:
            ('oneway')(?) type name '(' field_statement(s? /,?/) (',')(?) ')' (throws)(?) (',')(?)
            #{ print "$item[0]: ".join(', ', map { "'$_'" } @item[1 .. $#item]) . "\n" }
            { $Thrift::IDL::wrap->({
                class     => 'Method',
                oneway    => $item[1][0] ? 1 : undef,
                returns   => $item[2],
                name      => $item[3],
                arguments => $item[5],
                throws    => $item[8][0] ? $item[8][0] : [],
            }) }

        throws:
            'throws' '(' field_statement(s? /,/) ')'
            #{ print "$item[0]: ".join(', ', map { "'$_'" } @item[1 .. $#item]) . "\n" }
            { $item[3] }

        type:
            base_type | container_type | custom_type
        
        base_type:
            ('bool' | 'byte' | 'i16' | 'i32' | 'i64' | 'double' | 'string' | 'binary' | 'slist' | 'void')
            { $Thrift::IDL::wrap->({ class => 'Type::Base', name => $item[1] }) }

        custom_type:
            name
            { $Thrift::IDL::wrap->({ class => 'Type::Custom', name => $item[1] }) }

        container_type:
            map_type | set_type | list_type

        map_type:
            'map' cpp_type(?) '<' type ',' type '>'
            { $Thrift::IDL::wrap->({ class => 'Type::Map', key_type => $item[4], val_type => $item[6], cpp_type => $item[2][0] }) }

        set_type:
            'set' cpp_type(?) '<' type '>'
            { $Thrift::IDL::wrap->({ class => 'Type::Set', val_type => $item[4], cpp_type => $item[2][0] }) }

        list_type:
            'list' '<' type '>' cpp_type(?)
            { $Thrift::IDL::wrap->({ class => 'Type::List', val_type => $item[3], cpp_type => $item[5][0] }) }

        cpp_type:
            'cpp_type' quoted_string
            { $item[2] }

        name:
            /[A-Za-z_][A-Za-z0-9_.]*/
            { if ($Thrift::IDL::reserved_keywords{$item[1]}) { warn "Cannot use reserved language keyword: $item[1]\n"; return undef } $item[1] }
            #{ print "$item[0]: ".join(', ', map { "'$_'" } @item[1 .. $#item]) . "\n"; $return = $item[1]; }

        word:
            /(\w|[.])+/
            #{ print "$item[0]: ".join(', ', map { "'$_'" } @item[1 .. $#item]) . "\n"; $return = $item[1]; }

        value:
            number | value_map

        value_map:
            '{' value_map_pair(s /,/) '}'
            { { map { @$_ } @{ $item[2] } } }

        value_map_pair:
            quoted_string ':' quoted_string
            { [ $item[1] => $item[3] ] }

        number:
            /[0-9]+/

        quoted_string:
            single_quoted_string | double_quoted_string

        double_quoted_string:
            '"' <skip:''> /[^"]+/ '"' 
            { $item[3] }

        single_quoted_string:
            "'" <skip:''> /[^']+/ "'"
            { $item[3] }
EOF

    return $parser;
}

sub _new_from_parsed {
	my ($class, $source, $debug) = @_;

    my ($children, $headers) = $class->_parse_thrift($source, $debug, {});

    my $document = Thrift::IDL::Document->new({ children => $children, headers => $headers });
    _set_associations($document);

    return $document;
}

sub _parse_thrift {
    my ($class, $source, $debug, $state) = @_;

	my $input_fn = $source->{file} || undef;

    if (defined $input_fn && $state->{_parse_input_fn_processed}{$input_fn}++) {
        print "Skipping repeat processing of $input_fn\n";
        return ([], []);
    }

    my $data = $source->{buffer} || undef;

    if ($input_fn) {
		# Slurp the file in
        local $/ = undef;
        open my $in, '<', $input_fn or die "Can't read from $input_fn: $!";
        $data = <$in>;
        close $in;
    }

    # Create a DocumentHeader object
    my $header = Thrift::IDL::DocumentHeader->new({ includes => [], namespaces => [] });

	if ($input_fn) {
		my ($basename) = $input_fn =~ m{([^/]+)\.thrift$};
		$header->basename($basename) if defined $basename;
	}

    # Set the global $g_current_header to this document header so all blessed objects
    # created upon parsing will have a reference to $header
    $g_current_header = $header;

    print STDERR "Parsing '$input_fn'\n" if $input_fn && $debug;

    my $parsed = $class->parser($debug)->document(\$data) or die "Bad input";

    if ($data !~ m{^\s*$}s) {
        my $error = "Parsing failed to consume all of the input; stopped at:\n";
        my @lines = grep { $_ !~ /^\s*$/ } split /\n/, $data;
        my $cropped = int @lines > 20 ? 1 : 0;
        foreach my $line (@lines[0 .. 19]) {
            #next unless $line;
            chomp $line;
            $error .= "> $line\n";
        }
        if ($cropped) {
            $error .= " (more cropped)\n";
        }
		die $error;
    }

    # Setup return of header list
    my @headers;
    push @headers, $header;

	my $include_base = '/'; # Somewhat insane default value
	if ($input_fn) {
		# Check for any Include headers and include those elements as well
		$input_fn = abs_path($input_fn);
		($include_base) = $input_fn =~ m{^(.+)/[^/]+$};
	}

    # Extract header objects and associate each non-header child object with
    # the document header (for namespacing mainly)
    my (@parsed, @comments);
    foreach my $child (@$parsed) {
        # Collect comments that come before Include and Namespace objects; dispose of them when we dispose of the object
        # Otherwise, we'll have combined comments that don't make sense (comment for now gone Namespace with comment
        # for a typedef)
        if ($child->isa('Thrift::IDL::Comment')) {
            push @comments, $child;
        }
        elsif (! $child->isa('Thrift::IDL::Header')) {
            #$child->{header} = $header;
            push @parsed, @comments, $child;
            @comments = ();
        }
        else {
            if ($child->isa('Thrift::IDL::Include')) {
                push @{ $header->{includes} }, $child;
                # Insert the included document at the same point as the 'include' declaration
                my $include_fn = abs_path($include_base . '/' . $child->value);
                if (! -f $include_fn) {
                    die "include file '".$child->value."' not found in $include_base";
                }
                my ($include_parsed, $include_headers) = $class->_parse_thrift({ file => $include_fn }, $debug, $state);
                push @parsed, @$include_parsed;
                push @headers, @$include_headers;
                @comments = ();
            }
            elsif ($child->isa('Thrift::IDL::Namespace')) {
                push @{ $header->{namespaces} }, $child;
                @comments = ();
            }
        }
    }
    return (\@parsed, \@headers);
}

sub _set_associations {
    my $element = shift;

    my @comments;
    for (my $i = 0; $i <= $#{ $element->{children} }; $i++) {
        my $child = $element->{children}[$i];

        # Reference myself in the child object
        #$child->{parent} = $element;

        $child->{service} = $element if $child->isa('Thrift::IDL::Method');

        # Associate comments with the child elements that follow the comments
        if ($child->isa('Thrift::IDL::Comment')) {
            push @comments, $child;
        }
        elsif (@comments) {
            $child->{comments} = [ @comments ];
            @comments = ();
        }

        $child->{comments} ||= [];

        if ($child->{children}) {
            _set_associations($child);
        }
    }
}
1;
