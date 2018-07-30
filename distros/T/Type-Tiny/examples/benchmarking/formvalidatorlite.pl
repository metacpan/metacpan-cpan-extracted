use Modern::Perl;
use Benchmark ':all';
use CGI;
use FormValidator::Lite qw/Email Date/; 
use FormValidator::Simple;
use Types::Standard ();
 
say "Perl: $]";
say "FVS: $FormValidator::Simple::VERSION";
say "FVL: $FormValidator::Lite::VERSION";
say "TT : $Type::Tiny::VERSION";
 
my $C = -1;

my $q = CGI->new;
$q->param( param1 => 'ABCD' );
$q->param( param2 => 12345 );
$q->param( mail1  => 'lyo.kato@gmail.com' );
$q->param( mail2  => 'lyo.kato@gmail.com' );
$q->param( year   => 2005 );
$q->param( month  => 11 );
$q->param( day    => 27 );


use Types::Standard -types;
use Types::Common::String -types;
use Types::Common::Numeric -types;

sub Types::ParamsObj::object_to_hashref {
    my $object = shift;
    my @names  = $object->param;
    +{ map {
        my $name = $_;
        my @vals = $object->param($name);
        !@vals ? () : (@vals==1 ? ($name=>@vals) : ($name=>\@vals))
    } @names };
}

my $type = do {
        
    my $LooseEmail = Type::Tiny->new(
        name       => 'LooseEmail',
        parent     => Str,
        constraint => sub { Email::Valid::Loose->address($_) },
        inlined    => sub { my $var = $_[1]; (undef, "Email::Valid::Loose->address($_)") },
    );
    
    my $ParamsObj = Type::Tiny->new(
        name       => 'ParamsObj',
        parent     => HasMethods['param'],
        constraint_generator => sub {
            my $dict = (
                ($Type::Tiny::parameterize_type||{})->{'_cached_dict'} ||= Dict->of(@_)
            );
            return sub {
                my $hashref = Types::ParamsObj::object_to_hashref($_);
                $dict->check($hashref);
            };
        },
        inline_generator => sub {
            my @params = @_;
            return sub {
                my ($type, $var) = @_;
                my $dict = (
                    ($type||{})->{'_cached_dict'} ||= Dict->of(@params)
                );
                sprintf(
                    '(%s) && do { '.
                    'my $hashref = Types::ParamsObj::object_to_hashref(%s);'.
                    '%s'.
                    '}',
                    $type->parent->inline_check($var),
                    $var,
                    $dict->inline_check('$hashref'),
                );
            };
        },
    );
    
    $ParamsObj->of(
        param1  => StrLength->of(2,5)->where(q{ /^[[:ascii:]]+$/ }),
        param2  => Int,
        mail1   => $LooseEmail,
        mail2   => $LooseEmail,
        year    => IntRange[1,2999],
        month   => IntRange[1,12],
        day     => IntRange[1,31],
    )->where(q{ $_->param("mail1") ne $_->param("mail2") });
};

my $check = $type->compiled_check;

cmpthese(
    $C => {
        'FormValidator::Lite' => sub {
            my $result = FormValidator::Lite->new($q)->check(
                param1 => [ 'NOT_BLANK', 'ASCII', [ 'LENGTH', 2, 5 ] ],
                param2 => [ 'NOT_BLANK', 'INT' ],
                mail1  => [ 'NOT_BLANK', 'EMAIL_LOOSE' ],
                mail2  => [ 'NOT_BLANK', 'EMAIL_LOOSE' ],
                { mails => [ 'mail1', 'mail2' ] } => ['DUPLICATION'],
                { date => [ 'year', 'month', 'day' ] } => ['DATE'],
            );
        },
        'FormValidator::Simple' => sub {
            my $result = FormValidator::Simple->check(
                $q => [
                    param1 => [ 'NOT_BLANK', 'ASCII', [ 'LENGTH', 2, 5 ] ],
                    param2 => [ 'NOT_BLANK', 'INT' ],
                    mail1  => [ 'NOT_BLANK', 'EMAIL_LOOSE' ],
                    mail2  => [ 'NOT_BLANK', 'EMAIL_LOOSE' ],
                    { mails => [ 'mail1', 'mail2' ] } => ['DUPLICATION'],
                    { date => [ 'year', 'month', 'day' ] } => ['DATE'],
                ]
            );
        },
        'Type::Tiny' => sub { $type->check($q) },
        'Type::Tiny sub' => sub { $check->($q) },
    },
);