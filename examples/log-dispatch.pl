#!/usr/bin/env perl

use Black::Board;
use Moose::Autobox;

my $logger;

topic Log => (
    subscribe => sub {
        $logger->log( @{ [ level => 'debug', %{ $_->params } ] } );
        return $_->cancel_bubble;
    },
    initialize => sub {
        require Log::Dispatch;
        $logger = Log::Dispatch->new(
            outputs => [
                [ Screen => ( 'min_level' => 'debug' ) ]
            ]
        );
    }
);

topic FmtLog => (
    subscribe => sub {
        return publish Log => $_;
    }
);

subscriber FmtLog => sub {
    return $_->merge_params( {
        message => '[' . localtime . ']' . $_->params->{message}
    } );
};

subscriber FmtLog => sub {
    return $_->merge_params( {
        message => '[' . $_->with_meta->name . '] ' . $_->params->{message}
    } );
};

subscriber FmtLog => sub {
    return $_->merge_params( {
        message => $_->params->{message} . "\n"
    } ) if $_->params->{message} !~ /\n\z/;
    return $_;
};

package MyApp;
use Moose;
use Black::Board;

publish FmtLog => message => "Something that needs logging";
publish FmtLog => message => "Some other formatted message";

publish Log => message => "beginning of unformatted message ->";
publish Log => message => "-middle of message-";
publish Log => message => "<- end of message\n";

for ( 1 .. 2000 ) {
    publish FmtLog => message => "Speed logging $_";
}

