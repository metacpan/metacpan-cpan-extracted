{ package MyPack; 
    #use Sub::Exporter; # -setup => { exports => ['foo'] };
    sub foo {
        print "FFFFFFFFOOOOOO\n";
    }
}
{
    package Joe;
    use sugar 'moose';
    #use Sub::Exporter -setup => { exports => [ 'baz' ] };
    print [1,2]->push(2);
    croak 'jei';
    #use import 'Moose';
    #BEGIN { require Moose; Moose->import(); require Moose::Autobox; Moose::Autobox->import() }
    #use Moose;
    #use Moose::Autobox;

    has 'name' => ( is=>'rw', isa=>'Str' );

    sub baz {
        my $a = [1,2,3];
        $a->push(4);
        return "BAZ=" . $a;
    }
}
{
    package Charlie;
    use Try::Tiny;
    print try { [1,2]->push(2) } catch { 'try-catch ok' };
}
{
    package Again;
    use sugar 'moose';
    print [1,2]->push(2);

}
{
    package Bia;
    use sugar 'moose';
    print [1,2]->push(2);
}
{
    #use sugar 'goo';
    $x = 1;
    print "X=$x";
}
package main;
print Joe::baz();
