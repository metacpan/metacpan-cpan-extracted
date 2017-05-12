package t::typelibrary;
no nonsense 'type library' => 'FortyTwo';

subtype FortyTwo, as Int, where { $_ == 42 }, message { 'must be 42!' };
