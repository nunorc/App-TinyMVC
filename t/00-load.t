#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::TinyMVC' );
}

diag( "Testing App::TinyMVC $App::TinyMVC::VERSION, Perl $], $^X" );

