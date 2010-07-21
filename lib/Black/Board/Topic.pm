use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: Topic module for L<Black::Board>, meshes L<Messages|Black::Board::Message> with L<Subscribers|Black::Board::Subscriber>


class Black::Board::Topic
    with Black::Board::Trait::Traversable
{
    use Method::Signatures::Simple name => 'imethod';
    use MooseX::Types::Moose qw( Str ArrayRef CodeRef );
    use Black::Board::Types qw(
        Message
        TopicName
        Subscriber
        SubscriberList
        Publisher
    );
    use Moose::Autobox;


    has 'name' => (
        is => 'ro',
        isa => TopicName,
        required => 1
    );


    has 'subscribers' => (
        is => 'rw',
        traits => [ 'Array' ],
        isa => SubscriberList,
        default => sub { [] },
        coerce => 1,
        handles => {
            has_subscribers     => 'count',
            register_subscriber => 'unshift',
            subscriber_list     => 'elements'
        }
    );

    # argument prototype check type
    before register_subscriber( Subscriber $subscriber ) {
    }


    has 'initializers' => (
        is => 'rw',
        traits => [ 'Array' ],
        isa => ArrayRef[CodeRef],
        default => sub { [] },
        handles => {
            has_initializers      => 'count',
            register_initializer  => 'push',
            initializer_list      => 'elements',
            dequeue_initializer   => 'pop',
        }
    );
    # argument prototype check type
    before register_initializer( CodeRef $initializer ) {
    }



    has 'message_class' => (
        is => 'rw',
        isa => Str,
        lazy_build => 1,
    );
    sub _build_message_class {
        my $class = 'Black::Board::Message';
        Class::MOP::load_class( $class )
            unless Class::MOP::is_class_loaded( $class );
        return $class;
    }


    imethod wants_message( $message ) {
        return 1;
    }


    imethod deliver( $subscriber, $message ) {

        # run onetime initialization code
        while ( @{ $self->{initializers} } ) { # optimized
            $self->dequeue_initializer->(
                topic     => $self,
                publisher => $self->parent,
            );
        }

        # soft failure
        return $message unless $self->wants_message( $message );

        local $message->{topic} = $self; # optimized

        return $subscriber->deliver( $message );
    }
}


1;


__END__
=pod

=head1 NAME

Black::Board::Topic - Topic module for L<Black::Board>, meshes L<Messages|Black::Board::Message> with L<Subscribers|Black::Board::Subscriber>

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    my $logger = new Log::Dispatch(
        outputs => [
            [ Screen => ( 'min_level' => 'debug' ) ]
        ]
    );

    topic LogDispatch => sub {
        $logger->log( %{ $_->params } );
        return $_->cancel_bubble;
    };

    subscriber LogDispatch => sub {
        return $_->clone_with_params(
            message => '[Prefix] ' . $_->params->{message}
        )
    };

    publish LogDispatch => 
        message => "Something that needs logging",
        level => "alert";

=head1 DESCRIPTION

A topic has a list of subscribers.  It also has a say in what kinds of messages
will be going to said subscribers.  A topic is registered to a specific
L<Publisher|Black::Board::Publisher>. The publisher takes care of finding which
topic to publish to and passes off the L<Message|Black::Board::Message> to the
individual L<Topic|Black::Board::Topic> objects.  If the message is modified by
the subscriber, a clone of the message with the modifications is expected to be
returned.

This is one of the pieces in the puzzle.

=head1 ATTRIBUTES

=head2 C<name>

Each topic must have a name and this attribute contains the name. The name is
used to identify the Topic for message dispatch and subscription.

=head2 C<subscribers>

This attribute holds an array of subscribers which have subscribed to this
topic.

=head2 C<initializers>

List of registered initializers, code that is ran the first
time a message is published to this topic.
Subclasses can not override this due to optimizations.

=head2 C<message_class>

This is the class of the message object this topic's subscribers expect to get.
This defaults to L<Black::Board::Message::Simple>, a message with a C<param()>
interface.

=head1 METHODS

=head2 C<wants_message>

This method is usually called by L</METHODS/deliver>. It takes one parameter,
the current L<Black::Board::Message> object. Returning false from this method
will cause L</METHODS/deliver> to skip the current Message. The default
implementation returns true.

This is a place for subclasses to override. The default method only returns
true.  You can override this in your custom topic to do some complex checking.
You can skip the current message by returning false or you can throw an
exception if things are really scary!

=head2 C<deliver>

This method is usually called by L<Black::Board::Publisher/METHODS/publish>. It
takes two positional arguments. The first is the L<Black::Board::Subscriber>
object to deliver to.  The second argument is the L<Black::Board::Message>
object which is being delivered.

This method returns the message passed in if a call to C<<Topic->wants_message(
Message )>> returns false. Otherwise this method returns it's call to C<<
Subscriber->deliver( Message ) >>. The C<Message> object has it's current topic
set to this C<Topic> instance.

=head1 SEE ALSO

=over 4

=item *

L<Black::Board::Publisher> - publishes Messages to Topics

=item *

L<Black::Board::Subscriber> - the object a Topic delivers a message to

=item *

L<Black::Board> - provides sugar syntax to do all this

=back

=head1 AUTHOR

Scott Beck <sabeck@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <sabeck@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

