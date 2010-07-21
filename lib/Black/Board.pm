use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: publish messages and subscribe to topics

class Black::Board {

    use Black::Board::Publisher;
    use Black::Board::Topic;
    use Black::Board::Subscriber;

    use Scalar::Util qw( blessed reftype );

    use Moose;
    use Moose::Autobox;
    use Moose::Exporter;
    use MooseX::Singleton;
    use MooseX::Types::Moose qw(
        ArrayRef
        HashRef
        CodeRef
        Str
    );
    use Black::Board::Types qw(
        Publisher
        Message
        Topic
        TopicName
        NamedCodeList
    );
    use MooseX::Params::Validate;

    Moose::Exporter->setup_import_methods(
        as_is     => [ qw( topic subscriber ) ],
        with_meta => [ qw( publish ) ]
    );




    has Publisher => (
        is => 'rw',
        isa => Publisher,
        lazy_build => 1,
    );

    sub _build_Publisher {
        return shift->PublisherClass->new;
    }


    has SubscriberClass => (
        is         => 'rw',
        isa        => Str,
        lazy_build => 1
    );
    sub _build_SubscriberClass {
        my $class = 'Black::Board::Subscriber';
        return $class;
    }


    has TopicClass => (
        is         => 'rw',
        isa        => Str,
        lazy_build => 1
    );
    sub _build_TopicClass {
        my $class = 'Black::Board::Topic';
        return $class;
    }


    has PublisherClass => (
        is         => 'rw',
        isa        => Str,
        lazy_build => 1,
    );
    sub _build_PublisherClass {
        my $class = 'Black::Board::Publisher';
        return $class;
    }


    sub _get_or_create_topic {
        my $class = shift;
        my $name = shift;

        my $topic = $class->Publisher->get_topic( $name );
        unless ( $topic ) {
            $topic = $class->TopicClass->new( name => $name );
            $class->Publisher->add_topic( $topic );
        }
        return $topic;
    }

    sub topic ($@) {
        my ( $name, $code ) = pos_validated_list(
            [ shift, ( ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) ? $_[0] : { @_ } ) ],
            { isa => TopicName, required => 1 },
            { isa => NamedCodeList, coerce => 1 }
        );

        my $topic = __PACKAGE__->_get_or_create_topic( $name );

        # cumlative init handlers that happen the first time something
        # is published to the topic
        if ( exists $code->{initialize} ) {
            $topic->register_initializer( $_ ) for $code->{initialize}->flatten;
        }

        if ( exists $code->{subscribe} ) {
            subscriber( $topic, $_ ) for $code->{subscribe}->flatten;
        }

        return $topic;
    }


    sub subscriber ($&) {
        my ( $topic, $subscription ) = pos_validated_list(
            \@_,
            { isa => Topic, coerce => 1, required => 1 },
            { isa => CodeRef, required => 1 },
        );

        my $subscriber = __PACKAGE__->SubscriberClass->new(
            subscription => $subscription
        );
        $topic->register_subscriber( $subscriber );
        return $subscriber;
    }


#    sub _create_message {
#        my ( $class, $topic, $opt ) = @_;
#
#        # removes all parameters that start with a dash
#        # these are used as top level parameters to Message->new()
#        my %p = map {
#            ( my $cp = $_ ) =~ s/^-//;
#            ( $cp => delete $opt->{ $_ } );
#        } grep /^-/, keys %$opt;
#
#        # all other parameters are merged with params, -params taking precedence
#        $p{params} = { %$opt, %{ $p{params} || {} } };
#
#        # the topic gets to say what type of message it wants. so you
#        # can create a custom topic with custom message types
#        return $topic->{message_class}->new( \%p ); # optimized
#    }

    sub publish ($@) {
        my $meta = shift;

        # Optimization
        my ( $topic, $maybe_message ) = ( shift, ( @_ == 1 ? $_[0] : { @_ } ) );
        my $publisher;
        unless ( blessed $topic ) {
            $publisher = __PACKAGE__->Publisher;
            $topic = $publisher->get_topic( my $topic_copy = $topic );

            # can go no further without a topic to publish to
            confess "can not find topic for [" . ( $topic_copy // 'Undef' ) . "]"
                unless defined $topic;
        }


        # this coercion has to be done by hand because we decide the Message
        # class to instanciate with the Topic object
        my $message;
        if ( blessed $maybe_message ) {
            $message = $maybe_message;
        }
        else {
            my $opt = $maybe_message;

            # removes all parameters that start with a dash
            # these are used as top level parameters to Message->new()
            my %p = map {
                ( my $cp = $_ ) =~ s/^-//;
                ( $cp => delete $opt->{ $_ } );
            } grep /^-/, keys %$opt;

            # all other parameters are merged with params, -params taking precedence
            $p{params} = { %$opt, %{ $p{params} || {} } };

            # the topic gets to say what type of message it wants. so you
            # can create a custom topic with custom message types
            $message = $topic->message_class->new( \%p );
            $message->{with_meta} = $meta; # optimized
        }

        # we could add sub-topics later
        return do { $publisher // $topic->parent }->publish( $topic, $message );
    }

}


1;


__END__
=pod

=head1 NAME

Black::Board - publish messages and subscribe to topics

=head1 VERSION

version 0.0001

=head1 WARNING WARNING WARNING

This module is currently considered alpha quality code by it's author, the
current maintainer. This means that anything can change in the next minor
version release. Use at your own risk!

=head1 SYNOPSIS

    use Log::Dispatch;
    use Black::Board;

    my $publisher = Black::Board::Publisher->new;

    my $log_topic = Black::Board::Topic->new(
        name => "LogDispatch"
    );

    $publisher->add_topic( $log_topic );

    my $logger = Log::Dispatch->new(
        outputs => [
            [ Screen => ( 'min_level' => 'debug' ) ]
        ]
    );

    $log_topic->register_subscriber(
        Black::Board::Subscriber->new(
            subscription => sub {

                # $_ here is the Black::Board::Message object
                # which you can get explicitly from @_

                if ( $logger->would_log( $_->params->{level} ) ) {

                    $logger->log( %{ $_->params } );

                    # Let the caller have a way to check if we logged
                    return $_->merge_params(
                        { log_sent_for => $_->params->{level} },
                    );
                }
                return $_->cancel_bubble;
            }
        )
    );

    $log_topic->register_subscriber(
        Black::Board::Subscriber->new(
            subscription => sub {
                return $_->merge_params(
                    { message => '[Prefix] ' . $_->params->{message} }
                )
            }
        )
    );

    my $other_logger = Log::Dispatch->new(
        outputs => [
            [ File => (
                'filename'  => 'intercepted-error.log'
            ) ]
        ]
    );

    $log_topic->register_subscriber(
        Black::Board::Subscriber->new(
            subscription => sub {

                if ( $other_logger->would_log( $_->params->{level} ) ) {

                    $other_logger->log( %{ $_->params } );

                    # Let the caller have a way to check if we logged
                    return $_->merge_params(
                        { other_log_sent_for => $_->params->{level} },
                    );
                }
                return $_;
            }
        )
    );

    $publisher->publish(
        topic  => 'LogDispatch',
        message => {
            params => {
                message => "Something that needs logging",
                level   => "alert"
            }
        }
    );

    # -- OR -- #



    # any arguments beyond the first are passed off to subscriber
    my $logger;
    topic LogDispatch => 

        # Called the next time a message is delivered
        # only called once
        initialize => [
            sub {
                require Log::Dispatch;
                $logger = Log::Dispatch->(
                    outputs => [
                        [ Screen => ( 'min_level' => 'debug' ) ]
                    ]
                );
            }
        ],
        subscribe => [
            sub {
                my $m = $_;
                if ( $logger->would_log( $m->params->{level} ) ) {

                    $logger->log( %{ $m->params } );

                    # Let the caller have a way to check if we logged
                    return $m->merge_params(
                        { log_sent_for => $m->params->{level} },
                    );
                }
                return $m->cancel_bubble;
            }
        ];

    my $other_logger;
    topic LogDispatch =>

        # Called the next time a message is delivered
        # only called once
        initialize => [
        `   sub {
                $other_logger = Log::Dispatch->new(
                    outputs => [
                        [ File => (
                            'filename'  => 'intercepted-error.log'
                        ) ]
                    ]
                );
            }
        ];

    subscriber LogDispatch => sub {
        my $m = $_;
        if ( $other_logger->would_log( $m->params->{level} ) ) {

            $other_logger->log( %{ $m->params } );

            # Let the caller have a way to check if we logged
            $m = $m->clone_with_params(
                { other_log_sent_for => $m->params->{level} }
            );
        }
        return $m;
    };

    subscriber LogDispatch => sub {
        return $_->clone_with_params(
            { message => '[Prefix] ' . $_->params->{message} }
        )
    };

    publish LogDispatch => 
        message => "Something that needs logging",
        level   => "alert"

        # -params has precedence
        -params => {

            # level is now changed to debug
            level => "debug",

            more => "parameters merged with precedence"
        };

=head1 DESCRIPTION

This code is inspired by L<Bread::Board> and even a few bits were stolen from
it.

The purpose of this module is to provide a publisher/subscriber interface for
passing messages. This subscriber interface has the ability for subscribers to
act as filters on the message. Each subscriber can return a modified copy of the
message.  The message is cloned because the same message object should be able
to be sent on multiple dispatch chains.

=head1 ATTRIBUTES

=head2 C<Publisher>

This is the singleton L<Publisher|Black::Board::Publisher> object. You can set this to
a different Publisher object but you should do this before you start declaring Topics or
be prepared to copy the previously registered Topics into the new object.

=head2 C<SubscriberClass>

Used to create a C<Subscriber> object when one is needed. Defaults to
L<Black::Board::Subscriber>. Can be changed to a custom topic class name for
extending Black::Board.

=head2 C<TopicClass>

Used to create a C<Topic> object when one is needed. Defaults to
L<Black::Board::Topic>. Can be changed to a custom topic class name for
extending Black::Board.

=head2 C<PublisherClass>

Used to create a C<Publisher> object when one is needed. Defaults to
L<Black::Board::Publisher>. Can be changed to a custom topic class name for
extending Black::Board.

=head1 FUNCTIONS

=head2 C<topic>

First argument is the topic name to create, any additional arguments are passed
off to L</METHODS/subscriber> as new subscription callbacks.

If the topic name already exists in the singleton L</CLASS ATTRIBUTES/Publisher>:

=over 4

=item 1

If subscribers are specified, the subscribers will be subscribed to the

already existing topic.

=item 2

If no subscribers are specified this topic call is an apparent no-op but

does ensure the topic has been created

=back

=head2 C<subscriber>

Create a new L<Black::Board::Subscriber> object and adds it to the topic
specified.  The first argument is a L<Black::Board::Topic> object or the name
of one which is already registered to the Singleton that lives in
C<<Black::Board->Publisher()>>.  The second argument should be a code reference.
The code reference is passed off to L<Black::Board::Subscriber> as the
C<subscription> callback.

=head2 C<publish>

Publishes the given message to the given topic.

Takes two conceptual arguments:

The first argument can be the L<Black::Board::Topic> object. If the first
argument is a L<Black::Board::Types/TYPES/TopicName>, it will be coerced by
looking up the C<TopicName> in the L</CLASS ATTRIBUTES/Publisher>.  That
failing, an exception will be thrown.

Next you can pass in either a C<HashRef> or a C<Hash> (list of key/value pairs)
which is converted into a C<HashRef>.  This C<HashRef> is taken as meta
information for creating a L<Black::Board::Message> object. All keys except
those which start with a dash C<-> are treated as C<<Mmessage->params>>
key/value pairs.

These are roughly equivalent:

    # simplest
    publish LogDispatch =>
        message => "I got here",
        level   => "debug";

and

    # can use a hash reference
    publish LogDispatch => {
        message => "I got here",
        level   => "debug"
    };

Keys which start with a dash C<->, have the dash removed and are passed along
to the C<Black::Board::Message> constructor. for example:

    publish Foo =>
        -params => {
            hi => "there"
        };

Here are some more equivalent examples matching the ones above:

    # ditch sugar completely
    Black::Board->Publisher->publish(
        topic   => Black::Board->Publisher->topic(
            "LogDispatch"
        ),
        message => Black::Board::Message->new(
            params => {
                message => "I got here",
                level   => "debug"
            }
        )
    );

and

    # pass in the message as an object, maybe the same object from a previous
    # call to publish
    publish LogDispatch =>
        Black::Board::Message->new(
            params => {
                message => "I got here",
                level   => "debug"
            }
        );

and

    # pass in the topic and message as objects
    publish
        Black::Board->Publisher->topic(
            "LogDispatch"
        ),
        Black::Board::Message->new(
            params => {
                message => "I got here",
                level   => "debug"
            }
        );

NB: If you have a C<-params> argument as well as non-dash arguments, the
C<-params> argument will be merged and will take precedence.

=head1 EXPORTS

=over 4

=item *

topic

=item *

subscriber

=item *

publish

=back

=head1 SEE ALSO

=over 4

=item *

L<Black::Board::Publisher>

Dispatcher and owner of Topics

=item *

L<Black::Board::Topic>

A Topic object is a place to subclass for custom Topics that handle something
more complicated than a C<param()> based message.

=item *

L<Black::Board::Message>

A C<param()> based Message. Subclass for a more complicated Message.

=item *

L<Black::Board::Subscriber>

Encapsulates subscriber hooks to maintain consistent calling conventions.

=item *

L<Black::Board::Types>

If you are doing any subclassing, look here for the MooseX::Types.

=back

=head1 AUTHOR

Scott Beck <sabeck@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <sabeck@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

