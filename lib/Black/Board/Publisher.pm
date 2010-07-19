use strict;
use warnings;
use MooseX::Declare;

# ABSTRACT: Publisher object for L<Black::Board>, dispatches to Topic subscribers

class Black::Board::Publisher
    with Black::Board::Trait::Traversable
{

    use Scalar::Util qw( blessed reftype );
    use Black::Board::Types qw(
        TopicNameList
        TopicList
        Topic
        TopicName
        Message
    );
    use Moose::Autobox;

=head1 DESCRIPTION

This is the Publisher object for L<Black::Board>. It contains a list of
L<Topic|Black::Board::Topic> objects. The C<Publisher> object takes care of
this list of C<Topic> objects, it handles dispatching to them and provides
methods to add and remove topics.

=attr C<topics>

Contains a L<TopicList|Black::Board::Types/TYPES/TopicList> registered to this
publisher. A TopicList is an array reference of
L<Topic|Black::Board::Types/TYPES/Topic> objects.

=method C<has_topics>

Returns the number of topics registered to this publisher.

=method C<add_topic>

Registers the specified L<Black::Board::Topic> object to this publisher.

=method C<topic_list>

Returns a list of L<Black::Board::Topic> objects registered to this publisher.

=method C<first_topic>

Peform a L<first()|List::Util> operation on L<topics|/ATTRIBUTES/topics>.

=cut

    has 'topics' => (
        is      => 'rw',
        isa     => TopicList,
        traits  => [ 'Array' ],
        default => sub { [] },
        coerce  => 1,
        trigger => sub {
            my $self = shift;
            $_->parent( $self ) for @{ $self->topics };
        },
        handles => {
            has_topics  => 'count',
            add_topic   => 'push',
            topic_list  => 'elements',
            first_topic => 'first',
        }
    );

    before add_topic( Topic $topic ) {
        if ( $self->first_topic( sub { $_->name eq $topic->name } ) ) {
            confess "'" . $topic->name . "' has already been registered";
        }
    }

=method C<remove_topic>

Only argument is a L<Black::Board::Types/TYPES/TopicName>. Removes the given
TopicName from this publishers list of topics.

=cut

    method remove_topic( TopicName $topic_name ) {
        my $topics = $self->topics;
        for ( my $i = 0; $i < $topics->count; ++$i ) {
            if ( $topics->get( $i )->name eq $topic_name ) {
                $topics->delete( $i );
                last;
            }
        }
    }

=method C<get_topic>

Given a TopicName, returns a Topic object if found, undefined otherwise.

=cut

    method get_topic( TopicName $topic_name ) {
        return $self->first_topic( sub { $_->name eq $topic_name } );
    }

=method C<publish>

Takes a L<Black::Board::Types/TYPES/Topic> and a
L<Black::Board::Types/TYPES/Message>. The message is dispatched to the
subscribers of the topic. The final message returned by the subscriber is
returned.

=cut

    method publish( Topic :$topic, Message :$message ) {

        for my $subscriber ( $topic->subscriber_list->reverse->flatten ) {

            # if the subscriber wishes to change the message, they must
            # clone it. the return copy is what bubbles up. deliver() must
            # return the original message or a clone of it.
            $message = $topic->deliver(
                subscriber => $subscriber,
                publisher  => $self,
                message    => $message
            );

            # this boolean is set to false when cancel_bubble() is called.
            # cancel_bubble() is used by final-destination subscribers
            last unless $message->bubble;
        }

        # the final message returned is expected to have information about what
        # was done.
        return $message;
    }
}

=head1 SEE ALSO

=for :list
* L<Black::Board::Message> - objects being dispatched to L<Topics|Black::Board::Topic>.
* L<Black::Board::Topic> - topic objects contained and dispatched to by a Publisher
* L<Black::Board> - provides sugar syntax to a singleton Publisher

=cut

1;
