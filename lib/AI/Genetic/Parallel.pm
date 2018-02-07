package AI::Genetic::Parallel;

use Moose;
use namespace::autoclean;

use MooseX::Event;

=head1 NAME

AI::Genetic::Parallel - Run GA's using parallelization and moduable logic.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use AI::Genetic::Parallel;

    my $gen = AI::Genetic::Parallel->new(

        population => AI::ParaX::Populaiton::BitVector->new(
            individual_count => 100,
            bits             => 100,
        ),

    );

    $gen->on(
        selection => sub {
            my ( $self ) = @_;

            $self->population->keep(
                $self->population->best(1),
                $self->population->elites,
            );
        },
    );


    $gen->on(
        crossover => sub {
            my ( $self ) = @_;

            $self->population->keep(
                $self->population->best(1),
                $self->population->elites,
            );
        },
    );


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
                my $dna = mutate( $individual->dna );
                $individual->dna( $dna );
            }
        },
    );

    $gen->on(
        fitness => sub {
            my $self = shift;
            my $individual = shift;

            my $binary = $individual->dna;
            $individual->fitness( oct "0b$binary" );
        }
    );

    $gen->on(
        parallel => sub {
            my $self = shift;
            foreach my $individual ( @{ $gen->population->individuals } ) {
                #  parallel process here
                $individual = $self->fitness( $individual );
            }
        }
    );

    $gen->on(
        terminate => sub {
            my $self = shift;
            $self->terminated(1) if $end_this;
        }

    );

    $ga->on(
        epoch => sub {
            my $self = shift;
            print "another generation complete";
        },
    );


    #  run 200 times
    $ga->run(200);

    #  the same as $gen->run(200);
    for ( 1 .. 200 ) {
        $self->select;
        $self->crossover;
        $self->mutate;
        $self->parallel;
        $self->epoch;
        last if $self->terminate;
    }

=head1 DESCRIPTION

This module provides is designed to be parallel and plug-in-play.  It enforces
compatibilty and extending features by using Moose roles.  

The AI::Genetic::Parallel module is designed to be a wrapper around modularized
behavior as to lend itself to ultimate flexibiilty.

=head1 METHODS

=head2 new

=over 4

=item population

Takes an object that implements the 'AI::ParaX::Role::NewPopulation' and returns an AI::Genetic::Parallel::Populaiton object.

=cut

has population => ( is => 'rw', isa => 'AI::Genetic::Parallel::Population' );

=back

=head2 on

On specific phases of the evolution, specify behavior via an event

=over 4

=item selection

On the selection phase act on the AI::Genetic::Parallel object.

In this example we are replacing the population with the most fit and elite members.

    $gen->on(
        selection => sub {
            my ( $self ) = @_;

            $self->population->keep(
                $self->population->best(1),
                $self->population->elites,
            );
        },
    );

=cut

has_event 'selection';
sub select {
    my $self = shift;
    $self->emit( selection => ( $self ) );
    return $self;
}

=item crossover

On the selection phase define behavior using code reference

In this example we are replacing the population with the most fit and elite members.

    $gen->on(
        crossover => sub {
            my ( $self ) = @_;

            $self->population->keep(
                $self->population->best(1),
                $self->population->elites,
            );
        },
    );

=cut

has_event 'crossover';
sub crossover {
    my $self = shift;
    $self->emit( crossover => ( $self ) );
    return $self;
}

=item mutation

On the mutation phase define behavior using code reference

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
                my $dna = mutate( $individual->dna );
                $individual->dna( $dna );
            }
        },
    );

=cut

has_event 'mutation';
sub mutate {
    my $self = shift;
    $self->emit( mutation => ( $self ) );
    return $self;
}

=item parallel

put parallel processing code here, this is where we call the fitness function

    $gen->on(
        parallel => sub {
            my $self = shift;
            foreach my $individual ( @{ $gen->population->individuals } ) {
                #  parallel process here
                $individual = $self->fitness( $individual );
            }
        }
    );

=cut


has_event 'parallel';
sub parallel {
    my $self = shift;
    $self->emit( parallel => ( $self ) );
    return $self;
}

=item fitness

get the fitness of an individual, to be called by the paralell method

    $gen->on(
        fitness => sub {
            my $self = shift;
            my $individual = shift;

            my $binary = $individual->dna;
            $individual->fitness( oct "0b$binary" );
        }
    );

=cut

has_event 'fitness';
sub fitness {
    my $self       = shift;
    my $individual = shift;
    $self->emit( fitness => ( $individual ) );
    return $individual;
}

=item terminate

Terminate is called at the end of the run processing loop.  If it returns true then it finishes processing.

=cut

has_event 'terminate';
sub terminate {
    my $self = shift;
    $self->emit( terminate => ( $self ) );
    return $self;
}

=item epoch

on finishing generation, do something at the end, call'ed from run method

=cut

has_event 'epoch';
sub epoch {
    my $self = shift;
    $self->emit( epoch => ( $self ) );
    return $self;
}

=item error

=cut

has error => ( is => 'rw', isa => 'AI::ParaX::Role::Crossover' );

=head2 run

Run the algorithim for $x number of iterations.  Equivalent to :

    foreach my $iteration ( 1 .. $iterations ) {
        $self->select;
        $self->crossover;
        $self->mutate;
        $self->parallel;
        $self->epoch;
        last if $self->terminate;
    }

=cut

sub run {

    my $self = shift;
    my $iterations = shift;

    foreach my $iteration ( 1 .. $iterations ) {
        $self->select;
        $self->crossover;
        $self->mutate;
        $self->parallel;
        $self->epoch;
        last if $self->terminate;
    }

    return $self;
}

=head2 terminated

Flag to to set for run loop to tell us if the process is to be terminated.  Needs to be set from the terminate code ref.

=cut

has terminated => ( is => 'rw', isa => 'Bool', default => 0 );

=head1 AUTHOR

Adam Wohld, C<< <adam at radarlabs.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-genetic-parallel at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-Genetic-Parallel>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::Genetic::Parallel


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-Genetic-Parallel>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AI-Genetic-Parallel>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AI-Genetic-Parallel>

=item * Search CPAN

L<http://search.cpan.org/dist/AI-Genetic-Parallel/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Adam Wohld.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable;

1; # End of AI::Genetic::Parallel
