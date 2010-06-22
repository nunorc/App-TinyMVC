#!/usr/bin/env perl

use lib '/Users/smash/playground/App-TinyMVC/lib';

use FCGI;
use App::TinyMVC;
$App::TinyMVC::CONFDIR = '/Users/smash/playground/App-TinyMVC/config';


my $request = FCGI::Request();

while($request->Accept() >= 0) {
	my $MSPApp = new App::TinyMVC(
		controller => 'test',
		action => 'test',
		args => [1,2,3],
		context => {
			sapo => $SAPO,
			params => $VAR79451,
		}
	);
	my $output = $MSPApp->process;


	print "Content-type: text/html\r\n\r\n";
	print $output;

}
