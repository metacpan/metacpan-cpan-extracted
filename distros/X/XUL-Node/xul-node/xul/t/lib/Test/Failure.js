
JSAN.package('Test');

new Class("Test.Failure", {

initialize : function (test, error) {
	this.test  = test;
	this.error = error;
}

});
