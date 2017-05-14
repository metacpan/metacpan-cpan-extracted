
    use Win32::Tie::Ini;

    $TiePackage = "Win32::Tie::Ini";

    @Numbers = qw(
        zero
        one
        two
        three
        four
        five
        six
        seven
        eight
        nine
        ten
    );

    $File = "c:\\temp\\win.ini" unless ($File = $ARGV[0]);
    $Section = $TiePackage;

    print "Opening a tied hash to '$File'...";
    tie %File, $TiePackage, $File  || die "failed ($!).\n";
    print "Done.\n\n";

    print "Adding a section called [$Section] with keys:\n";
    for ($iTemp = 0; $iTemp < 10; $iTemp++)
    {
        print "\tAdding key '$iTemp' with the value of '$Numbers[$iTemp]'.\n";
        $File{$Section}->{$iTemp} = $Numbers[$iTemp];
    }

    print "Now let's look at what we just added...\n";

    if (defined ($File{$Section}))
    {
        print "Keys:\n";

        @Keys = values( %{$File{$Section}} );
        print @Keys;

        foreach $Temp (@Keys)
        {
            print "$Temp\n";
        }

        print @Keys;

        foreach $Key ( keys( %{$File{$Section}} ) )
        {
            print "\t$Key = '$File{$Section}->{$Key}'\n";
        }

        print "done.\n";

    }else{
        print "OOpps! The section [$Section] was not created. Big problem!\n";
    }




    print "\n\nPress a key to continue...\n";
    getc();
    print "Done.\n";

sub Each
{
    print join("\n", (@Temp = %File));
}

sub Test
{
    my($Count) = @_;
    $Count = 10 unless ($Count);
    my($x);

    for(; $Count > 0; $Count--)
    {
        print $x = $File{drawdib};
    }

}

sub Dump
{
    foreach $Temp (keys %File)
    {
        print "[$Temp]\n";
        foreach (keys %{$File{$Temp}})
        {
            print "$_=$File{$Temp}->{$_}\n";
        }
    }
}
