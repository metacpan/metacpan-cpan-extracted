
function foo() {

    let addr = new URL("https://example.ցithub.com");

    let text = "This оne is allowed."; // ## Test::MixedScripts Latin,Cyrillic,Common
    addr.searchParameters.append("q", text);

    return addr;
}
