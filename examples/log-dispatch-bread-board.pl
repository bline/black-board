#!/usr/bin/env perl

use strict;
use warnings;
package MyApp;

use Moose;
use Bread::Board;
use Black::Board;
use Moose::Autobox;

has 'log_topic' => ( is => 'ro', isa => 'Black::Board::Topic', required => 1 );
has 'log_fmt_topic' => ( is => 'ro', isa => 'Black::Board::Topic', required => 1 );

sub run {
    my $self = shift;

    my $fmt_log = $self->log_fmt_topic;
    my $log = $self->log_topic;

    publish $fmt_log => message => "Something that needs logging";
    publish $fmt_log => message => "Some other formatted message";

    publish $log => message => "beginning of unformatted message ->";
    publish $log => message => "-middle of message-";
    publish $log => message => "<- end of message\n";

    for ( 1 .. 2000 ) {
        publish $fmt_log => message => "Speed logging $_";
    }
}


my $container = container 'MyApp' => as {
    service Application => (
        lifecycle => 'Singleton',
        class => 'MyApp',
        dependencies => {
            log_topic => depends_on( 'Topics/Log' ),
            log_fmt_topic => depends_on( 'Topics/FmtLog' ),
            subscribers => depends_on( 'Subscribers' )
        }
    );
    service Logger => (
        lifecycle => 'Singleton',
        class     => 'Log::Dispatch',
        block     => sub {
            Log::Dispatch->new(
                outputs => [
                    [ Screen => ( 'min_level' => 'debug' ) ]
                ]
            );
        }
    );

    container 'Topics' => as {
        service 'Log' => (
            lifecycle => 'Singleton',
            block => sub {
                my $logger = shift->param( 'Logger' );
                topic Log => (
                    subscribe => sub {
                        $logger->log( @{ [ level => 'debug', %{ $_->params } ] } );
                        return $_->cancel_bubble;
                    }
                );
            },
            dependencies => {
                Logger => depends_on( '/MyApp/Logger' )
            }
        );

        service 'FmtLog' => (
            lifecycle => 'Singleton',
            block => sub {
                my $s = shift;
                my $topic = $s->param( 'Log' );
                topic FmtLog => (
                    subscribe => sub {
                        return publish $topic => $_;
                    }
                );
            },
            dependencies => wire_names( 'Log' )
        );
    };
    service 'Subscribers' => (
        lifecycle => 'Singleton',
        block => sub {
            my $fmt_log = shift->param( 'FmtLog' );
            subscriber $fmt_log => sub {
                return $_->merge_params( {
                    message => '[' . localtime . ']' . $_->params->{message}
                } );
            };
            subscriber $fmt_log => sub {
                return $_->merge_params( {
                    message => '[' . $_->with_meta->name . '] ' . $_->params->{message}
                } );
            };
            subscriber $fmt_log => sub {
                return $_->merge_params( {
                    message => $_->params->{message} . "\n"
                } ) if $_->params->{message} !~ /\n\z/;
                return $_;
            };
        },
        dependencies => { FmtLog => depends_on( 'Topics/FmtLog' ) }
    );
};

$container->fetch( 'MyApp/Application' )->get->run;

