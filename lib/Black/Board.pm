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

    use Black::Board::Publisher;
    use Black::Board::Subscriber;
    use Black::Board::Message;

    Moose::Exporter->setup_import_methods(
        as_as      => [ qw( topic subscriber publish ) ]
    );




    class_has Publisher => (
        is => 'rw',
        isa => Publisher,
        lazy_build => 1,
    );

    sub _build_Publisher {
        return __PACKAGE__->PublisherClass->new;
    }


    class_has TopicClass => (
        is      => 'rw',
        isa     => ClassName,
        default => 'Black::Board::Topic'
    );


    class_has PublisherClass => (
        is      => 'rw',
        isa     => ClassName,
        default => 'Black::Board::Publisher'
    );


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

    # TODO
    # cumlative init handlers that happen the first time something
    # is published to the topic
    sub topic ($@) {
        my ( $name, $subscriptions ) = pos_validate_list(
            [ shift, [ @_ ] ],
            { isa => TopicName, required => 1 },
            { isa => ArrayRef[CodeRef] }
        );

        my $topic = __PACAKGE__->_get_or_create_topic( $name );

        subscriber( $topic, $_ ) for $subscriptions->flatten;

        return $topic;
    }


    sub subscriber ($&) {
        my ( $topic, $subscription ) = pos_validated_list(
            \@_,
            { isa => Topic, coerce => 1, required => 1 },
            { isa => CodeRef, required => 1 },
        );

        $subscription = Black::Board::Subscriber->new(
            subscription => $subscription
        );
        $topic->add_subscription( $subscription );
        return $subscription;
    }


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

    $log_topic->add_subscriber(
        Black::Board::Subscriber->new(
            subscription => sub {

                if ( $logger->would_log( $_->params->{level} ) ) {

                    $logger->log( %{ $_->params } );

                    # Let the caller have a way to check if we logged
                    $_->params->{log_sent_for} = $_->params->{level};
                }
                return $_->cancel_bubble;
            }
        )
    );

    $log_topic->add_subscriber(
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

    $log_topic->add_subscriber(
        Black::Board::Subscriber->new(
            subscription => sub {

                if ( $other_logger->would_log( $_->params->{level} ) ) {

                    $other_logger->log( %{ $_->params } );

                    # Let the caller have a way to check if we logged
                    $_->params->{other_log_sent_for} = $_->params->{level};
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


    my $logger = Log::Dispatch->(
        outputs => [
            [ Screen => ( 'min_level' => 'debug' ) ]
        ]
    );

    # any arguments beyond the first are passed off to subscriber
    topic LogDispatch => sub {

        if ( $logger->would_log( $_->params->{level} ) ) {

            $logger->log( %{ $_->params } );

            # Let the caller have a way to check if we logged
            $_->params->{log_sent_for} = $_->params->{level};
        }
        return $_->cancel_bubble;
    };

    my $other_logger = Log::Dispatch->new(
        outputs => [
            [ File => (
                'filename'  => 'intercepted-error.log'
            ) ]
        ]
    );

    subscriber LogDispatch => sub {

        if ( $other_logger->would_log( $_->params->{level} ) ) {

            $other_logger->log( %{ $_->params } );

            # Let the caller have a way to check if we logged
            $_->params->{other_log_sent_for} = $_->params->{level};
        }
        return $_;
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
        }

=head1 DESCRIPTION

This code is inspired by L<Bread::Board> and even a few bits were stolen from
it.

The purpose of this module is to provide a publisher/subscriber interface for
passing messages. This subscriber interface has the ability for subscribers to
act as filters on the message. Each subscriber can return a modified copy of the
message.  The message is cloned because the same message object should be able
to be sent on multiple dispatch chains.

=head1 CLASS ATTRIBUTES

=head2 C<Publisher>

This is the singleton L<Publisher|Black::Board::Publisher> object. You can set this to
a different Publisher object but you should do this before you start declaring Topics or
be prepared to copy the previously registered Topics into the new object.

=head2 C<TopicClass>

=head2 C<PublisherClass>

=head1 FUNCTIONS

=head2 C<topic>

First argument is the topic name to create, any additional argument are passed
off to L</METHODS/subscriber> as new subscription callbacks.

If the topic name already exists in the singleton L</CLASS ATTRIBUTES/Publisher>:

=over 4

=item 1

If subscribers are specified, the subscribers will be subscribed to the

already existing topic.

=item 2

If no subscribers are specified this topic call is an apparent no-op but

does ensure the topic is created

=back

=head2 C<subscriber>

Create a new L<Black::Board::Subscription> object and adds it to the topic
specified.  First argument is a L<Black::Board::Topic> or the name of one
already registered.  The second argument should be a code reference. The code
reference is passed off to L<Black::Board::Subscriber> as the C<subscription>
callback.

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

