#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Twitter::Bot' );
	use_ok( 'Twitter::Bot::Timeline' );
	use_ok( 'Twitter::Bot::Set' );
}

diag( "Testing Twitter::Bot $Twitter::Bot::VERSION, Perl $], $^X" );
