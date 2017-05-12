use Test::More 'no_plan';

##using ## first test
BEGIN { use_ok('jQuery') };

##more tests
my $doc = qq~
<!DOCTYPE html>
<html>
    <div>
        <div></div>
        <div class="test"></div>
        <div></div>
    </div>
</html>
~;

my $fragment = qq~
    <div>
        <div></div>
        <div class="test"></div>
        <span>this is a text</span>
    </div>
~;

my $ooTest = sub {
    my $j = jQuery->new($doc);
    my $nodes = $j->jQuery('div');
    $nodes->find('*:first');
    if (scalar @{ $nodes->getNodes } == 1){
        return 1;
    }
    return 0;
};

my $SimpleSelect = sub {
    my $nn = jQuery($fragment)->find('div');
    my @nodes = $nn->getNodes;
    return 1 if  ( scalar @nodes == 2 );
    return 0;
};

my $addClass = sub {
    jQuery->new($fragment);
    my $nn = jQuery('span')->addClass('testClass');
    return $nn->hasClass('testClass');
};

ok( $ooTest->(), 'OO style test' );
ok( $SimpleSelect->(), 'Simple Select Test' );
ok( $addClass->(), 'Add Class Test' );


