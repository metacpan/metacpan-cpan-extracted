use Tie::IxHash;
$_={
    'WebDyne::Constant' => {
        WEBDYNE_ERROR_SHOW          => 1,
        WEBDYNE_ERROR_SHOW_EXTENDED => 1,
        #  Use tied hash to ensure charset=UTF-8 is first meta tag
        WEBDYNE_META => do { my %webdyne_meta; tie(%webdyne_meta, 'Tie::IxHash', (
            'charset=UTF-8' => undef,
            viewport => 'width=device-width, initial-scale=1.0',
            author => 'Bob Foobar',
            'http-equiv=X-UA-Compatible' => 'IE=edge',
            'http-equiv=refresh' => '5; url=https://www.example.com'
        )); \ %webdyne_meta },
        WEBDYNE_HTML_PARAM => {
            lang => 'en-UK'
        },
        WEBDYNE_HEAD_INSERT         => << 'END'
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.classless.min.css">
<style>
    :root { --pico-font-size: 85% } 
</style>
END
  }
};
