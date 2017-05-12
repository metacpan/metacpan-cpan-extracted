use t::TestVIC skip_all => 'incomplete implementation';#tests => 0, debug => 0;

my $input = <<'...';
PIC P16F690;

pragma variable bits = 16;
pragma $var5 bits = 8;
pragma $var6 bits = 32;
pragma $var7 bits = 64;

Main {
    digital_output PORTC;
    $var1 = 12345;
    $var2 = 67890;
    $var6 = 0;
    $var3 = 0;
    $var6 = 67890;
    $var7 = 0xCAFEFACEDEADBEEF;
    ++$var1;
    --$var2;
    $var3 = $var1 + $var2;
    $var3 = $var2 - $var1;
    $var1 = 128;
    $var2 = 32;
    $var4 = $var1 * $var2;
    $var4 = $var4 / $var2;
    $var3 = $var4 % 5;
    # sqrt is a modifier
    #$var3 = sqrt $var4;
    $var5 = $var3;
    --$var7;
    $var7 = $var3;
    --$var5;
    $var5 = ($var1 + (($var3 * ($var4 + $var7) + 5) + $var2));
}
...

my $output = << '...';
...

#compiles_ok($input, $output);
compile_fails_ok($input);
