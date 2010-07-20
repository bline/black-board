use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: publish messages and subscribe to topics

class Black::Board {

    use Scalar::Util qw( blessed reftype );

    use Moose;
    use Moose::Autobox;
    use Moose::Exporter;
    use MooseX::ClassAttribute;
    use MooseX::Types::Moose qw(
        ArrayRef
        HashRef
        CodeRef
        ClassName
        Str
    );
    use Black::Board::Types qw(
        Publisher
        Message
        Topic
        TopicName
    );
    use MooseX::Params::Validate;

    Moose::Exporter->setup_import_methods(
        as_is => [ qw( topic subscriber publish ) ]
    );

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

                if ( $logger->would_log( $_->params->{level} ) ) {

                    $logger->log( %{ $_->params } );

                    return $_->clone_with_params(

                        # Let the caller have a way to check if we logged
                        { log_sent_for => $_->params->{level} },

                        # clone_with_params passes extra parameters off to clone
                        bubble => 0
                    );
                }
                return $_->cancel_bubble;
            }
        )
    );

    $log_topic->register_subscriber(
        Black::Board::Subscriber->new(
            subscription => sub {

                return $_->clone(
                    params => $_->params->merge( {
                        message => '[Prefix] ' . $_->params->{message}
                    } )
                );

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

                    return $_->clone_with_params(

                        # Let the caller have a way to check if we logged
                        { other_log_sent_for => $_->params->{level} },

                        # clone_with_params passes extra parameters off to clone
                        bubble => 0
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

                    return $m->clone_with_params(
                        {

                            # Let the caller have a way to check if we logged
                            log_sent_for => $m->params->{level}
                        },

                        # clone_with_params passes extra parameters off to clone
                        bubble => 0
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
                other_log_sent_for => $m->params->{level}
            );
        }
        return $m;
    };

    subscriber LogDispatch => sub {
        return $_->clone_with_params(
            message => '[Prefix] ' . $_->params->{message}
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


=begin :prelude

=head1 WARNING WARNING WARNING

This module is currently considered alpha quality code by it's author, the
current maintainer. This means that anything can change in the next minor
version release. Use at your own risk!

=end :prelude

=head1 DESCRIPTION

This code is inspired by L<Bread::Board> and even a few bits were stolen from
it.

The purpose of this module is to provide a publisher/subscriber interface for
passing messages. This subscriber interface has the ability for subscribers to
act as filters on the message. Each subscriber can return a modified copy of the
message.  The message is cloned because the same message object should be able
to be sent on multiple dispatch chains.

=cut


=clattr C<Publisher>

This is the singleton L<Publisher|Black::Board::Publisher> object. You can set this to
a different Publisher object but you should do this before you start declaring Topics or
be prepared to copy the previously registered Topics into the new object.

=cut

    class_has Publisher => (
        is => 'rw',
        isa => Publisher,
        lazy_build => 1,
    );

    sub _build_Publisher {
        return __PACKAGE__->PublisherClass->new;
    }

=clattr C<SubscriberClass>

Used to create a C<Subscriber> object when one is needed. Defaults to
L<Black::Board::Subscriber>. Can be changed to a custom topic class name for
extending Black::Board.

=cut

    class_has SubscriberClass => (
        is         => 'rw',
        isa        => ClassName,
        lazy_build => 1
    );
    sub _build_SubscriberClass {
        my $class = 'Black::Board::Subscriber';
        Class::MOP::load_class( $class )
            unless Class::MOP::is_class_loaded( $class );
        return $class;
    }

=clattr C<TopicClass>

Used to create a C<Topic> object when one is needed. Defaults to
L<Black::Board::Topic>. Can be changed to a custom topic class name for
extending Black::Board.

=cut

    class_has TopicClass => (
        is         => 'rw',
        isa        => ClassName,
        lazy_build => 1
    );
    sub _build_TopicClass {
        my $class = 'Black::Board::Topic';
        Class::MOP::load_class( $class )
            unless Class::MOP::is_class_loaded( $class );
        return $class;
    }

=clattr C<PublisherClass>

Used to create a C<Publisher> object when one is needed. Defaults to
L<Black::Board::Publisher>. Can be changed to a custom topic class name for
extending Black::Board.

=cut

    class_has PublisherClass => (
        is         => 'rw',
        isa        => ClassName,
        lazy_build => 1,
    );
    sub _build_PublisherClass {
        my $class = 'Black::Board::Publisher';
        Class::MOP::load_class( $class )
            unless Class::MOP::is_class_loaded( $class );
        return $class;
    }

=func C<topic>

First argument is the topic name to create, any additional argument are passed
off to L</METHODS/subscriber> as new subscription callbacks.

If the topic name already exists in the singleton L</CLASS ATTRIBUTES/Publisher>:

=for :list
1. If subscribers are specified, the subscribers will be subscribed to the
already existing topic.
2. If no subscribers are specified this topic call is an apparent no-op but
does ensure the topic is created

=cut

    sub _get_or_create_topic {
        my $class = shift;
        my $name = shift;

        # if the topic already exists:
        #   1. If subscribers are specified, the subscribers will be
        #   subscribed to the already existing topic.
        #   2. If no subscribers are specified this topic call is an apparent
        #   no-op but does ensure the topic is created
        my $topic = $class->Publisher->get_topic( $name );
        unless ( $topic ) {
            $topic = $class->TopicClass->new( name => $name );
            $class->Publisher->add_topic( $topic );
        }
        return $topic;
    }

    sub topic ($@) {
        my ( $name, $code ) = pos_validate_list(
            [ shift, @_ == 1 && ref( $_[0] ) eq 'HASH' ? $_[0] : { @_ } ],
            { isa => TopicName, required => 1 },
            { isa => HashRef[ArrayRef[CodeRef]] }
        );

        my $topic = __PACAKGE__->_get_or_create_topic( $name );

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

=func C<subscriber>

Create a new L<Black::Board::Subscription> object and adds it to the topic
specified.  First argument is a L<Black::Board::Topic> or the name of one
already registered.  The second argument should be a code reference. The code
reference is passed off to L<Black::Board::Subscriber> as the C<subscription>
callback.

=cut

    sub subscriber ($&) {
        my ( $topic, $subscription ) = pos_validated_list(
            \@_,
            { isa => Topic, coerce => 1, required => 1 },
            { isa => CodeRef, required => 1 },
        );

        $subscription = __PACKAGE__->SubscriberClass->new(
            subscription => $subscription
        );
        $topic->register_subscription( $subscription );
        return $subscription;
    }

=func C<publish>

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


=cut

    sub _create_message {
        my $class = shift;
        my $topic = shift;
        my $opt = shift;

        # removes all parameters that start with a dash
        # these are used as top level parameters to to_Message()
        my %p = $opt->keys->grep( sub { /^-/ } )->map( sub {
            ( my $cp = $_ ) = s/^-//;
            ( $cp => $opt->delete( $_ ) );
        } );

        # all other parameters are merged with params, -params taking precedence
        $p{params} = $opt->merge( $p{params} || {} );

        # the topic gets to say what type of message it wants. so you
        # can create a custom topic with custom message types
        return $topic->message_class->new( \%p );
    }


    sub publish ($@) {
        my ( $topic, $maybe_message ) = pos_validated_list(
            [ shift, ( @_ == 1 ? $_[0] : { @_ } ) ],
            { isa => Topic, coerce => 1, required => 1 },
            { isa => Message|HashRef, required => 1 }
        );

        # this coercion has to be done by hand because we decide the Message
        # class to instanciate with the Topic object
        my $message = blessed $maybe_message
            ? $maybe_message

            # $maybe_message is a hashref with meta information about how to
            # construct a message object
            : __PACKAGE__->_create_message( $topic, $maybe_message );

        # we could add sub-topics later
        $message = $topic->parent->publish(
            topic   => $topic,
            message => $message
        );
        return $message;
    }
}

=head1 EXPORTS

=for :list
* topic
* subscriber
* publish

=head1 SEE ALSO

=for :list
* L<Black::Board::Publisher>
Dispatcher and owner of Topics
* L<Black::Board::Topic>
A Topic object is a place to subclass for custom Topics that handle something
more complicated than a C<param()> based message.
* L<Black::Board::Message>
A C<param()> based Message. Subclass for a more complicated Message.
* L<Black::Board::Subscriber>
Encapsulates subscriber hooks to maintain consistent calling conventions.
* L<Black::Board::Types>
If you are doing any subclassing, look here for the MooseX::Types.

=cut

1;

