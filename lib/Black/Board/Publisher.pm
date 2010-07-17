use MooseX::Declare;

class Black::Board::Publisher
    with Black::Board::Trait::Traversable
{
    use Black::Board::Types qw(
        TopicNameList
        TopicList
        Message
    );
    use Moose::Autobox;

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

=method C<find_topic>

Peform a grep operation on L<topics|/ATTRIBUTES/topics>.

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
            has_topics => 'count',
            add_topic  => 'push',
            topic_list => 'elements',
            find_topic => 'grep',
        }
    );

=method C<find_topics>

Finds and returns an Array of Topic objects given the TopicNameList specified.

=cut

    method find_topics( TopicNameList $topics ) {
        $self->find_topic(
            sub {
                my $topic = $_;
                $topics->grep(
                    sub {
                        my $topic_name = $_;
                        $topic->name eq $topic_name
                    }
                );
            }
        );
    }

=method C<publish>

Takes a L<Black::Board::Types/TYPES/TopicNameList> and a
L<Black::Board::Types/TYPES/Message>. The message is dispatched to the
subscribers of the topics. The final message returned by the subscriber is
returned.

=cut

    method publish( TopicNameList :$topics, Message :$message ) {

        # get the cross section of topics whos names match the array $topic_names
        $topics = $self->find_topics( $topics );

        # topics from last specified to first specified. this order was chosen
        # because it follows the order in which subscribers are dispatched. deeper
        # in the Black::Board tree can override the topics higher up
        for my $topic ( $topics->reverse->flatten ) {
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
        }

        # the final message returned is expected to have information about what
        # was done.
        return $message;
    }
}

1;
