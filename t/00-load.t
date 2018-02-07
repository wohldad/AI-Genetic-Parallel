#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'AI::Genetic::Parallel' ) || print "Bail out!\n";
}

diag( "Testing AI::Genetic::Parallel $AI::Genetic::Parallel::VERSION, Perl $], $^X" );
