use Tk;
$top = MainWindow->new();
$wine_list = $top->Listbox("-width" => 20, "-height" => 5
           )->pack();
$wine_list->insert('end', # Insert at end, the following list
           "Napa Valley Chardonnay", "Cabernet Sauvignon",
           "Dry Chenin Blanc", "Merlot",
           "Sangiovese");
$wine_list->bind('<Double-1>', \&buy_wine);

sub buy_wine {
    my $wine = $wine_list->get('active');
    return if (!$wine);
    print "Ah, '$wine'. An excellent choice\n";
    # Remove the wine from the list
    $wine_list->delete('active');
}

MainLoop();
