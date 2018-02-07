#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Output;

#plan tests => 45;

use AI::Genetic::Parallel;
use AI::ParaX::Population::BitVector;

use Data::Dumper;

can_ok( 'AI::Genetic::Parallel', 'new', 'select', 'crossover', 'mutate', 'parallel', 'fitness', 'terminate', 'epoch', 'error', 'run' );


my $gen = AI::Genetic::Parallel->new(
    population => AI::ParaX::Population::BitVector->new(
        individual_count => 10,
        bits             => 10,
    ),
);


#  did we get an AI::Genetic::Parallel object
isa_ok( $gen, 'AI::Genetic::Parallel' );


#  do we have a proper population
isa_ok( $gen->population, 'AI::Genetic::Parallel::Population' );

#  check each individual and set a fitness
my $fitness = 0;
foreach my $individual ( @{ $gen->population->individuals } ) {
    isa_ok( $individual, 'AI::Genetic::Parallel::Individual' );

    is( $individual->fitness($fitness), $fitness, "got fitness of $fitness for " . $individual->dna );

    $fitness++;
}


#  set the fitnesses and an elite
$gen->population->individuals->[0]->elite(1);


#  tell it on the select phase to keep the best fitness and an elite
$gen->on(
    selection => sub {

        my $self = shift;

        $self->population->keep(
            $self->population->best(1),
            $self->population->elites,
        );

    },
);


#  run the selection and make sure we got back the right object
isa_ok( $gen->select, 'AI::Genetic::Parallel' );


#  we should have gotten two individuals back
is( scalar @{ $gen->population->individuals }, 2, "got back two individuals");

#  one individual will have a fitness of 1 and the other a 9
is( ( grep { $_->fitness eq '0' or $_->fitness eq '9' } @{ $gen->population->individuals } ), 2, "got back the proper fitness values" );

#  one individual should be elite the other not
is( ( grep { $_->elite and $_->fitness eq '0' } @{ $gen->population->individuals } ), 1, "got an elite with the worst fitness" );
is( ( grep { not $_->elite and $_->fitness eq '9' } @{ $gen->population->individuals } ), 1, "got a non-elite with the best fitness" );



#  fillup the population on this crossover test for testing
$gen->on(
    crossover => sub {

        my $self = shift;

        $self->population(
            AI::ParaX::Population::BitVector->new(
                individual_count => 10,
                bits             => 10,
            ),
        );

    },
);


#  run the selection and make sure we got back the right object
isa_ok( $gen->crossover, 'AI::Genetic::Parallel' );


#  check each individual and set a fitness
$fitness = 0;
foreach my $individual ( @{ $gen->population->individuals } ) {
    isa_ok( $individual, 'AI::Genetic::Parallel::Individual' );

    is( $individual->fitness($fitness), $fitness, "got fitness of $fitness for " . $individual->dna );

    $fitness++;
}



#  test mutation, set all values to 1
$gen->on(
    mutation => sub {

        my $self = shift;

        $self->population(
            AI::ParaX::Population::BitVector->new(
                individual_count => 10,
                bits             => 10,
            ),
        );

        foreach my $individual ( @{ $gen->population->individuals } ) {

            isa_ok( $individual, 'AI::Genetic::Parallel::Individual' );

            $individual->dna('1111111111');

        }

    },
);


$gen->mutate;


foreach my $individual ( @{ $gen->population->individuals } ) {

    isa_ok( $individual, 'AI::Genetic::Parallel::Individual' );

    is( $individual->dna, '1111111111', "updated DNA" );

}


#  we're not really doing parallel for this test
$gen->on(
    parallel => sub {
        my $self = shift;

        foreach my $individual ( @{ $gen->population->individuals } ) {
            $self->fitness( $individual );
        }
    }
);


#  for each individual calculate their fitness, fitness will be the decimal value of the string
$gen->on(
    fitness => sub {

        my $self = shift;
        my $individual = shift;

        my $binary = $individual->dna;
        $individual->fitness( oct "0b$binary" );

    }

);

$gen->parallel;


foreach my $individual ( @{ $gen->population->individuals } ) {

    isa_ok( $individual, 'AI::Genetic::Parallel::Individual' );

    is( $individual->fitness, 1023, "got fitness" );

}


#  test that terminate returns true
$gen->on(
    terminate => sub {
        my $self = shift;
        $self->terminated(1);
    }

);

$gen->terminate;

is( $gen->terminated, '1', 'got termination' );

#  test on epoch
$gen->on(
    epoch => sub {
        my $self = shift;
        print "hey I'm epoch";
    }

);

sub epoch {
    $gen->epoch;
}

stdout_is( \&epoch, "hey I'm epoch", "epoch called and printed" );



#die Dumper $gen->population->individuals;


            

## left off here, start making parallel next not sure if on parallel should make sense.











































done_testing();
