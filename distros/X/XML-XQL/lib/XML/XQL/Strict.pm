package XML::XQL::Strict;

BEGIN
{
    die "Can't 'use' or 'require' XML::XQL module before XML::XQL::Strict\nJust 'us' or 'require' XML::XQL::Strict instead" if ($XML::XQL::Included);

    $XML::XQL::Restricted = 1;

    require XML::XQL;
};

1;
