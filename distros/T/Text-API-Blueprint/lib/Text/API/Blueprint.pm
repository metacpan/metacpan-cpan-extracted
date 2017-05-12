use strictures 2;

package Text::API::Blueprint;

# ABSTRACT: Markdown generator for API blueprint format

use Class::Load qw(load_class);
use Exception::Delayed;
use Carp qw(croak confess);
use HTTP::Headers::Fancy 1.001 ();

our $VERSION = '0.003';    # VERSION

use namespace::clean;

use Exporter qw(import);

our $Autoprint = 0;
our $Offset    = 0;

sub _autoprint {
    my ( $wantarray, $str ) = @_;
    if ( $Autoprint and not defined $wantarray ) {
        if ( ref $Autoprint eq 'SCALAR' ) {
            $$Autoprint .= $str;
        }
        elsif ( ref $Autoprint eq 'GLOB' ) {
            print $Autoprint $str;
        }
        else {
            print $str;
        }
        return;
    }
    else {
        return $str;
    }
}

no namespace::clean;

sub _rpl {
    my ( $re, $str, $rpl ) = @_;
    $rpl //= '';
    $str =~ s{^${re}}{$rpl}seg;
    $str =~ s{${re}$}{$rpl}seg;
    return $str;
}

sub _trim {
    _rpl( qr{\s+}, +shift );
}

sub _indent {
    my ( $str, $n ) = @_;
    $n //= 4;
    my $indent = ' ' x $n;
    $str =~ s{(\r?\n)}{$1.$indent}eg;
    return $indent . $str;
}

sub _flatten {
    my ($str) = @_;
    return unless defined $str;
    my ($pre) = ( $str =~ m{^(\s*)\S} );
    return $str unless $pre;
    $str =~ s{^\Q$pre\E}{}mg;
    return $str;
}

sub _header {
    my ( $level, $title, $body, $indent ) = @_;
    my $str = '#' x ( $level + $Offset );
    $str .= " $title\n\n";
    $body = _indent( $body, $indent ) if $indent;
    if ( ref $body eq 'ARRAY' ) {
        $str .= Concat(@$body) . "\n\n";
    }
    elsif ($body) {
        $str .= "$body\n\n";
    }
    return $str;
}

sub _listitem {
    my ( $keyword, $body, $indent ) = @_;
    my $str = "+ $keyword\n\n";
    $str .= _indent( $body, $indent ) . "\n\n" if $body;
    return $str;
}

sub _list {
    my @items = @_;
    return join "\n" => map { '+ ' . _trim($_) } @items;
}

sub _arrayhashloop {
    my ( $arrayhash, $coderef ) = @_;
    return unless ref $arrayhash eq 'ARRAY';
    my @list = @$arrayhash;
    my @result;
    while (@list) {
        my ( $key, $val ) = splice @list, 0 => 2;
        push @result => $coderef->( $key, $val );
    }
    return @result;
}

sub _complain {
    my ( $name, $hash ) = @_;
    foreach my $key ( keys %$hash ) {
        die "unsupported keyword in $name: $key\n";
    }
}

use namespace::clean;

our @EXPORT_OK;

# Compile (8) Meta Intro Resource Group Concat
BEGIN { push @EXPORT_OK => qw(Compile) }

sub Compile {
    my $struct = shift;
    my @Body;

    my ( $host, $name, $description ) =
      map { delete $struct->{$_} } qw(host name description);

    push @Body => Meta($host);
    push @Body => Intro( $name, $description ) if $name;

    if ( my $resources = delete $struct->{resources} ) {
        foreach my $resource (@$resources) {
            push @Body => Resource($resource);
        }
    }
    if ( my $groups = delete $struct->{groups} ) {
        _arrayhashloop(
            $groups,
            sub {
                my ( $group, $args ) = @_;
                push @Body => Group( $group, $args );
            }
        );
    }
    _complain( Compile => $struct );
    return _autoprint( wantarray, Concat(@Body) . "\n" );
}

# Section (-)
BEGIN { push @EXPORT_OK => qw(Section) }

sub Section {
    my ( $coderef, $offset ) = @_;
    $offset //= 1;
    $Offset += $offset;
    my $autoprint = $Autoprint;
    $Autoprint = \"";
    my $X = Exception::Delayed->wantany( undef, $coderef );
    my $str = $$Autoprint;
    $Autoprint = $autoprint;
    $Offset -= $offset;
    $X->result;
    return _autoprint( wantarray, $str );
}

# Meta (0)
BEGIN { push @EXPORT_OK => qw(Meta) }

sub Meta {
    my $str = "FORMAT: 1A8\n";
    if ( my $host = shift ) {
        $str .= "HOST: $host\n";
    }
    return _autoprint( wantarray, "$str\n" );
}

# Intro (0)
BEGIN { push @EXPORT_OK => qw(Intro) }

sub Intro {
    my ( $name, $description ) = @_;
    return _autoprint( wantarray, _header( 1, $name, $description // '' ) );
}

# Concat (0)
BEGIN { push @EXPORT_OK => qw(Concat) }

sub Concat {
    return _autoprint( wantarray, join "\n\n", map { _trim($_) } grep defined,
        @_ );
}

# Text (1) Concat
BEGIN { push @EXPORT_OK => qw(Text) }

sub Text {
    return _autoprint( wantarray,
        Concat( map { _flatten($_) } map { s{[\r\n]+}{\n}gr } @_ ) );
}

# Code (0)
BEGIN { push @EXPORT_OK => qw(Code) }

sub Code {
    my ( $code, $lang ) = @_;
    $code = _flatten($code);
    $lang //= '';
    my $delimiters = 3;
    my $delimiter;
    do {
        $delimiter = '`' x $delimiters;
        $delimiters++;
    } until $code !~ m{\Q$delimiter\E};
    return _autoprint( wantarray, "$delimiter$lang\n$code\n$delimiter\n\n" );
}

# Group (2) Concat Resource
BEGIN { push @EXPORT_OK => qw(Group) }

sub Group {
    my ( $identifier, $body, $indent ) = @_;
    if ( ref $body eq 'ARRAY' ) {
        $body = Concat( map { Resource($_) } @$body );
    }
    return _autoprint( wantarray,
        _header( 1, "Group $identifier", $body, $indent ) );
}

# Resource (7) Sesction Parameters Model Attributes Action
BEGIN { push @EXPORT_OK => qw(Resource) }

sub Resource {
    my $args = shift;
    my (
        $method,     $uri,   $identifier,  $body,
        $indent,     $level, $description, $parameters,
        $attributes, $model, $actions
      )
      = delete @$args{
        qw{ method uri identifier body indent level description parameters attributes model actions }
      };
    _complain( Resource => $args );
    $level //= 2;
    $body  //= '';
    if ( ref $body eq 'CODE' ) {
        $body = Section($body);
    }
    else {
        my @body;
        if ( ref $description eq 'ARRAY' ) {
            push @body => @$description;
        }
        elsif ( defined $description ) {
            push @body => $description;
        }
        push @body => Parameters($parameters) if defined $parameters;
        push @body => Attributes($attributes) if defined $attributes;
        push @body => Model($model)           if defined $model;
        push @body => map { Action($_) } @$actions if defined $actions;
        $body = Concat(@body);
    }
    if ( $method and $uri ) {
        return _autoprint( wantarray,
            _header( $level, "$method $uri", $body, $indent ) );
    }
    elsif ( $identifier and $uri ) {
        return _autoprint( wantarray,
            _header( $level, "$identifier [$uri]", $body, $indent ) );
    }
    elsif ($uri) {
        return _autoprint( wantarray,
            _header( $level, "$uri", $body, $indent ) );
    }
    else {
        die "no method and uri or identifier and uri or single uri given";
    }
}

# Model (4) Payload
BEGIN { push @EXPORT_OK => qw(Model) }

sub Model {
    if ( @_ == 1 and ref $_[0] eq 'HASH' ) {
        my $args = shift;
        my $type = delete $args->{type};
        return _autoprint( wantarray, Model( $type, $args ) );
    }
    else {
        my ( $media_type, $payload, $indent ) = @_;
        $payload = Payload($payload) if ref $payload;
        return _autoprint( wantarray,
            _listitem( "Model ($media_type)", $payload, $indent ) );
    }
}

# Schema (0)
BEGIN { push @EXPORT_OK => qw(Schema) }

sub Schema {
    my ( $body, $indent ) = @_;
    return _autoprint( wantarray, _listitem( "Schema", $body, $indent ) );
}

# Attribute (-)
sub Attribute;
BEGIN { push @EXPORT_OK => qw(Attribute) }

sub Attribute {
    my ( $attr, $def ) = @_;
    my $str = "$attr";
    if ( ref $def eq 'HASH' ) {
        if ( my $enum = delete $def->{enum} ) {
            $def->{type} = 'enum[' . $enum . ']';
        }
        if ( my $example = delete $def->{example} ) {
            $str .= ": `$example`";
        }
        if ( my $type = delete $def->{type} ) {
            $str .= " ($type)";
        }
        if ( my $desc = delete $def->{description} ) {
            $str .= " - $desc";
        }
        if ( my $members = delete $def->{members} ) {
            $str .= "\n" . _indent( _list( map { "`$_`" } @$members ) );
        }
        _complain( "Attributes($attr)" => $def );
    }
    elsif ( ref $def eq 'ARRAY' ) {
        my @strs = _arrayhashloop(
            $def,
            sub {
                return Attribute(@_);
            }
        );
        $str .= "\n" . _indent( _list(@strs) );
    }
    else {
        croak("second argument is not a HashRef nor an ArrayRef");
    }
    return $str;
}

# Attributes (0) Attribute
BEGIN { push @EXPORT_OK => qw(Attributes) }

sub Attributes {
    my ( $attrs, $indent ) = @_;
    if ( ref $attrs ) {
        my @attrs = _arrayhashloop(
            $attrs,
            sub {
                return Attribute(@_);
            }
        );
        return _autoprint( wantarray,
            _listitem( "Attributes", _list(@attrs), $indent ) );
    }
    else {
        return _autoprint( wantarray,
            _listitem( "Attributes ($attrs)", _list(), $indent ) );
    }
}

# Action (6) Section Relation Parameters Attributes Asset Reference Request_Ref Request Response_Ref Response Concat
BEGIN { push @EXPORT_OK => qw(Action) }

sub Action {
    my $args = shift;
    my (
        $method, $uri,         $identifier, $body,       $indent,
        $level,  $description, $relation,   $parameters, $attributes,
        $assets, $requests,    $responses
      )
      = delete @$args{
        qw{ method uri identifier body indent level description relation parameters attributes assets requests responses }
      };
    _complain( Action => $args );
    $level //= 3;
    $body  //= '';
    if ( ref $body eq 'CODE' ) {
        $body = Section($body);
    }
    else {
        my @body;
        if ( ref $description eq 'ARRAY' ) {
            push @body => @$description;
        }
        elsif ( defined $description ) {
            push @body => $description;
        }
        push @body => Relation($relation)     if defined $relation;
        push @body => Parameters($parameters) if defined $parameters;
        push @body => Attributes($attributes) if defined $attributes;
        if ($assets) {
            _arrayhashloop(
                $assets,
                sub {
                    my ( $identifier, $args ) = @_;
                    my @keyword_id = split( m{\s+}, $identifier, 2 );
                    if ( ref $args ) {
                        push @body => Asset( @keyword_id, $args );
                    }
                    else {
                        push @body => Reference( @keyword_id, $args );
                    }
                }
            );
        }
        else {
            _arrayhashloop(
                $requests,
                sub {
                    my ( $identifier, $args ) = @_;
                    if ( ref $args ) {
                        push @body => Request( $identifier, $args );
                    }
                    else {
                        push @body => Request_Ref( $identifier, $args );
                    }
                }
            );
            _arrayhashloop(
                $responses,
                sub {
                    my ( $identifier, $args ) = @_;
                    if ( ref $args ) {
                        push @body => Response( $identifier, $args );
                    }
                    else {
                        push @body => Response_Ref( $identifier, $args );
                    }
                }
            );
        }
        $body = Concat(@body) if @body;
    }

    if ( $identifier and $method and $uri ) {
        return _autoprint( wantarray,
            _header( $level, "$identifier [$method $uri]", $body, $indent ) );
    }
    elsif ( $identifier and $method ) {
        return _autoprint( wantarray,
            _header( $level, "$identifier [$method]", $body, $indent ) );
    }
    elsif ($method) {
        return _autoprint( wantarray,
            _header( $level, "$method", $body, $indent ) );
    }
    else {
        die
"no identifier and method and uri or identifier and method or single method given";
    }
}

# Payload (3) Headers Attributes Body Body_CODE Body_YAML Body_JSON Schema Concat
BEGIN { push @EXPORT_OK => qw(Payload) }

sub Payload {
    my $args = shift;
    my @body;
    if ( exists $args->{description} ) {
        if ( ref $args->{description} eq 'ARRAY' ) {
            push @body => @{ delete $args->{description} };
        }
        else {
            push @body => delete $args->{description};
        }
    }
    push @body => Headers( delete $args->{headers} ) if exists $args->{headers};
    push @body => Attributes( delete $args->{attributes} )
      if exists $args->{attributes};

    if ( exists $args->{body} ) {
        push @body => Body( delete $args->{body} );
    }
    elsif ( exists $args->{code} ) {
        push @body => Body_CODE( delete $args->{code}, delete $args->{lang} );
    }
    elsif ( exists $args->{yaml} ) {
        push @body => Body_YAML( delete $args->{yaml} );
    }
    elsif ( exists $args->{json} ) {
        push @body => Body_JSON( delete $args->{json} );
    }

    push @body => Schema( delete $args->{schema} ) if exists $args->{schema};

    _complain( Payload => $args );
    return _autoprint( wantarray, Concat(@body) );
}

# Asset (4) Payload
BEGIN { push @EXPORT_OK => qw(Asset) }

sub Asset {
    my ( $keyword, $identifier, $payload ) = @_;
    my $str = "$keyword $identifier";
    if ( my $media_type = delete $payload->{type} ) {
        $str .= " ($media_type)";
    }
    return _autoprint( wantarray, _listitem( $str, Payload($payload) ) );
}

# Reference (0)
BEGIN { push @EXPORT_OK => qw(Reference) }

sub Reference {
    my ( $keyword, $identifier, $reference ) = @_;
    return _autoprint( wantarray,
        _listitem( "$keyword $identifier", "[$reference][]" ) );
}

# Request (5) Asset
BEGIN { push @EXPORT_OK => qw(Request) }

sub Request {
    unshift @_ => 'Request';
    goto &Asset;
}

# Request_Ref (1) Reference
BEGIN { push @EXPORT_OK => qw(Request_Ref) }

sub Request_Ref {
    unshift @_ => 'Request';
    goto &Reference;
}

# Response (5) Asset
BEGIN { push @EXPORT_OK => qw(Response) }

sub Response {
    unshift @_ => 'Response';
    goto &Asset;
}

# Response_Ref (1) Reference
BEGIN { push @EXPORT_OK => qw(Response_Ref) }

sub Response_Ref {
    unshift @_ => 'Response';
    goto &Reference;
}

# Parameters (2) Parameter
BEGIN { push @EXPORT_OK => qw(Parameters) }

sub Parameters {
    my $body = '';
    _arrayhashloop(
        shift,
        sub {
            my ( $name, $opts ) = @_;
            $body .= Parameter( $name, $opts );
        }
    );
    return _autoprint( wantarray, _listitem( 'Parameters', $body ) );
}

# Parameter (1) Concat
BEGIN { push @EXPORT_OK => qw(Parameter) }

sub Parameter {
    my ( $name, $opts ) = @_;
    my ( $example_value, $required, $type, $enum, $shortdesc, $longdesc,
        $default, $members )
      = delete @$opts{
        qw{ example required type enum shortdesc longdesc default members }};
    _complain( Parameter => $opts );

    my $constraint = $required ? 'required' : 'optional';

    if ( defined $enum ) {
        $type = "enum[$enum]";
    }

    my @itembody;

    if ( ref $longdesc eq 'ARRAY' ) {
        push @itembody => @$longdesc;
    }
    elsif ( defined $longdesc ) {
        push @itembody => split /(\r?\n){2,}/, $longdesc;
    }

    my $str = "$name:";
    $str .= " `$example_value`"     if defined $example_value;
    $str .= " ($type, $constraint)" if defined $type;
    $str .= " - $shortdesc"         if defined $shortdesc;

    push @itembody => _listitem("Default: `$default`") if defined $default;

    my @members = _arrayhashloop(
        $members,
        sub {
            sprintf '+ `%s` - %s' => @_;
        }
    );
    push @itembody => _listitem( "Members", join( "\n" => @members ) )
      if @members;

    my $itembody = Concat(@itembody);

    return _autoprint( wantarray, _listitem( $str, $itembody ) );
}

# Headers (0)
BEGIN { push @EXPORT_OK => qw(Headers) }

sub Headers {
    my $body  = '';
    my $fancy = HTTP::Headers::Fancy->new;
    _arrayhashloop(
        shift,
        sub {
            my ( $name, $value ) = @_;
            $name = $fancy->prettify_key( $fancy->encode_key($name) );
            $body .= "\n    $name: $value";
        }
    );
    $body =~ s{^\n+}{}s;
    return _autoprint( wantarray, _listitem( 'Headers', $body ) );
}

# Body (0)
BEGIN { push @EXPORT_OK => qw(Body) }

sub Body {
    my $body = _flatten(shift);
    return _autoprint( wantarray, _listitem( 'Body', $body, 8 ) );
}

# Body_CODE (1) Code
BEGIN { push @EXPORT_OK => qw(Body_CODE) }

sub Body_CODE {
    return _autoprint( wantarray, _listitem( 'Body', Code(@_) ) );
}

sub _yaml {
    my ($struct) = @_;
    load_class('YAML::Any');
    YAML::Any::Dump($struct);
}

# Body_YAML (2) Body_CODE
BEGIN { push @EXPORT_OK => qw(Body_YAML) }

sub Body_YAML {
    my ($struct) = @_;
    return _autoprint( wantarray, Body_CODE( _yaml($struct), 'yaml' ) );
}

sub _json {
    my ($struct) = @_;
    load_class('JSON');
    our $JSON //= JSON->new->utf8->pretty->allow_nonref->convert_blessed;
    $JSON->encode($struct);
}

# Body_JSON (2) Body_CODE
BEGIN { push @EXPORT_OK => qw(Body_JSON) }

sub Body_JSON {
    my ($struct) = @_;
    return _autoprint( wantarray, Body_CODE( _json($struct), 'json' ) );
}

# Relation (0)
BEGIN { push @EXPORT_OK => qw(Relation) }

sub Relation {
    my $link = shift;
    return _autoprint( wantarray, _listitem("Relation: $link") );
}

1;

__END__

=pod

=head1 NAME

Text::API::Blueprint - Markdown generator for API blueprint format

=head1 VERSION

version 0.003

=head1 FUNCTIONS

=head2 Compile

    Compile({
        # Meta
        host => 'hostname',
        # Intro
        name => 'title',
        description => 'short introduction',
        resources => [
            # Resource
            {
                ...
            }
        ],
        groups => [
            # Group
            name => [
                # Resource
                {
                    ...
                }
            ]
        ],
    });

=head2 Section

    Section(sub {
        ...
    })

B<Invokation>: Section( CodeRef C<$coderef>, [ Int C<$offset> = C<1> ])

Increments header offset by C<$offset> for everything executed in C<$coderef>.

=head2 Meta

    Meta();
    Meta('localhost');

B<Invokation>: Meta([ Str C<$host> ])

    FORMAT: 1A8
    HOST: $host

=head2 Intro

    Intro('Our API');
    Intro('Our API', 'With a short introduction');

B<Invokation>: Intro(Str C<$name>, [ Str C<$description> ])

    # $name
    $description

=head2 Concat

    Concat('foo', 'bar');

B<Invokation>: Concat( Str C<@blocks> )

    $block[0]

    $block[1]

    $block[2]

    ...

=head2 Text

    Text('foo', 'bar');

B<Invokation>: Text( Str C<@strings> )

    $string[0]
    $string[1]
    $string[2]
    ...

=head2 Code

    Code('foobar');
    Code('{"foo":"bar"}', 'json');

B<Invokation>: Code(Str C<$code>, [ Str C<$lang> = C<''> ])

    ```$lang
    $code
    ```

=head2 Group

    Group('header', 'body');
    Group('name', [
        # Resource
        {
            ...
        }
    ]);

B<Invokation>: Group(Str C<$identifier>, Str|ArrayRef[HashRef|Str] C<$body>)

If C<$body> is an ArrayRef, every item which is a HashRef will be passed to L</Resource>.

    # Group $identifier

    $body

=head2 Resource

    Resource({
        ...
    });

B<Invokation>: Resource(HashRef $args)

Allowed keywords for C<$args>:

=over 4

=item * I<method>, I<uri>, I<identifier>

With I<method> and I<uri>

    ## $method $uri

    $body

With I<identifier> and I<$uri>

    ## $identifier [$uri]

    $body

With I<uri>

    ## $uri

    $body

Other combinations are invalid.

=item * body

If I<body> isa CodeRef, see L</Section>. I<description>, I<parameters>, I<attributes>, I<model>, I<actions> are not allowed then.

=item * description

A short introduction as a single string.

=item * parameters

See L</Parameters>.

=item * attributes

See L</Attributes>.

=item * model

See L</Model>.

=item * actions

Isa ArrayRef.

See L</Action>.

=back

=head2 Model

    Model({
        type => 'mime/type',
        # Payload
        ...
    });
    Model('mime/type', 'payload');

B<Invokation>: Model(Str C<$media_type>, Str|HashRef C<$payload>, [ Int C<$indent> ]);

See L</Payload> if the first and only argument is a HashRef.

    + Model ($media_type)

    $payload

=head2 Schema

    Schema('body');

B<Invokation>: Schema(Str C<$body>, [ Int C<$indent> ])

    + Schema

    $body

=head2 Attribute

    Attribute('scalar', {
        type => 'string',
        example => 'foobar',
        description => 'a text',
    });
    Attribute('list', {
        enum => 'number',
        example => 3,
        description => 'a number from 1 to 5',
        members => [1,2,3,4,5],
    });
    Attribute('hash' => [
        foo => {
            type => 'string',
            ...
        },
        bar => {
            ...
        }
    ]);

=head2 Attributes

    Attributes('reference');
    Attributes([
        # Attribute
        name => {
            ...
        }
    ]);

=head2 Action

    Action({
        ...
    });

B<Invokation>: Action(HashRef $args)

Allowed keywords for C<$args>:

=over 4

=item * identifier, method, uri

With C<$identifier> C<$method> and C<$uri>:

    ### $identifier [$method $uri]

    $body

With C<$identifier> and C<$method>:

    ### $identifier [$method]

    $body

With C<$method>:

    ### $method

    $body

Other combinations are invalid.

=item * description

=item * relation

See L</Relation>.

=item * parameters

See L</Parameters>.

=item * attributes

See L</Attributes>.

=item * assets

Isa ArrayRef interpreted as a key/value paired associative list.

The key is splited into two parts by the first whitespace, named I<keyword> and I<id>.

If the value isa string, L</Reference> is called with C<<<(keyword, id, value)>>>

If the value is anything else, L</Asset> is called with C<<<(keyword, id, value)>>>

=item * requests

See L</Request_Ref> if the value isa string. See L</Request> otherwise.

=item * responses

See L</Response_Ref> if the value isa string. See L</Response> otherwise.

=back

=head2 Payload

    Payload({
        ...
    });

B<Invokation>: Payload(HashRef $args)

Allowed keywords for C<$args>:

=over 4

=item * description

A short introduction as a single string.

=item * headers

See L</Headers>.

=item * attributes

See L</Attributes>.

=item * body

See L</Body>.

=item * code, lang

See L</Bode_CODE>.

=item * yaml

See L</Body_YAML>.

=item * json

See L</Body_JSON>.

=item * schema

See L</Schema>.

=back

=head2 Asset

    Asset('Request', 'foo', {
        type => 'mime/type',
        # Payload
        ...
    });

B<Invokation>: Asset( Str C<$keyword>, Str C<$identifier>, HashRef C<$payload> )

See L</Payload> for C<%payload>

    # $keyword $identifier ($type)

    $payload

=head2 Reference

    Reference('Request', 'foo', 'bar');
    Reference('Response', 'foo', 'bar');

B<Invokation>: Reference(Str C<$keyword>, Str C<$identifier>, Str C<$reference>)

    # $keyword $identifier

        [$reference][]

=head2 Request

    Request('foo', { ... });

B<Invokation>: Request(C<@args>)

Calls L</Asset>( C<'Request'>, C<@args> )

=head2 Request_Ref

    Request_Ref('foo', 'bar');

B<Invokation>: Request_Ref(C<@args>)

Calls L</Reference>( C<'Request'>, C<@args> )

=head2 Response

    Response('foo', { ... });

B<Invokation>: Response(
    C<@args>
)

Calls L</Asset>( C<'Response'>, C<@args> )

=head2 Response_Ref

    Response_Ref('foo', 'bar');

B<Invokation>: Response_Ref(C<@args>)

Calls L</Reference>( C<'Response'>, C<@args> )

=head2 Parameters

    Parameters([
        foo => {
            # Parameter
            ...
        },
        bar => {
            # Parameter
            ...
        }
    ]);

B<Invokation>: Parameters(ArrayRef[Str|HashRef] $parameters)

For every keypair in C<@$parameters> L</Parameter>(C<$key>, C<$value>) will be called

=head2 Parameter

    Parameter('foo', {
        example => 'foobar',
        required => 1,
        type => 'string',
        shortdesc => 'a string',
        longdesc => 'this is a string',
        default => 'none',
    });
    Parameter('foo', {
        example => '3',
        required => 0,
        enum => 'number',
        shortdesc => 'an optional number',
        longdesc => 'an integer between 1 and 5 (both inclusive)',
        default => 1,
        members => [1,2,3,4,5],
    });

B<Invokation>: Parameter( Str C<$name>, HashRef C<$args> )

    + $name: `$example` ($type, $required_or_optional) - $shortdesc

        $longdesc

        + Default: `$default`

        + Members
            + `$key` - $value
            + ...

=head2 Headers

    Headers([
        FooBar => '...', # Foo-Bar
        -foof  => '...', # X-Foof
    ]);

B<Invokation>: Headers(ArrayRef[Str] $headers)

The headers are encoded and prettified in a fancy way. See L<HTTP::Headers::Fancy> for more information.

=head2 Body

    Body('foobar');

B<Invokation>: Body( Str C<$body> )

    + Body

            $body

=head2 Body_CODE

    Body_CODE('foobar');
    Body_CODE('foo', 'bar');

B<Invokation>: Body_CODE( Str C<$code>, Str C<$lang> )

    + Body

        ```$lang
        $code
        ```

=head2 Body_YAML

    Body_YAML({ ... });
    Body_YAML([ ... ]);

B<Invokation>: Body_YAML( HashRef|ArrayRef C<$struct> )

    + Body

        ```yaml
        $struct
        ```

=head2 Body_JSON

    Body_JSON({ ... });
    Body_JSON([ ... ]);

B<Invokation>: Body_JSON( HashRef|ArrayRef C<$struct> )

    + Body

        ```json
        $struct
        ```

=head2 Relation

    Relation('foo');

B<Invokation>: Relation( Str C<$link> )

    + Relation: $link

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libtext-api-blueprint-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
