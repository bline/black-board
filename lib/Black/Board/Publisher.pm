use MooseX::Declare;

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


    method get_topic( TopicName $topic ) {
        return $self->first_topic( sub { $_->name eq $topic } );
    }


    method publish( TopicName|Topic :$topic, Message :$message ) {

        my $topic_copy = $topic;
        # turn TopicName into Topic
        $topic = $self->get_topic( $topic )
            unless blessed $topic;

        confess "Invalid topic $topic_copy"
            unless defined $topic;

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

1;

__END__
=pod

=head1 NAME

Black::Board::Publisher

=head1 VERSION

version 0.0001

=head1 ATTRIBUTES

=head2 C<topics>

Contains a L<TopicList|Black::Board::Types/TYPES/TopicList> registered to this
publisher. A TopicList is an array reference of
L<Topic|Black::Board::Types/TYPES/Topic> objects.

=head1 METHODS

=head2 C<has_topics>

Returns the number of topics registered to this publisher.

=head2 C<add_topic>

Registers the specified L<Black::Board::Topic> object to this publisher.

=head2 C<topic_list>

Returns a list of L<Black::Board::Topic> objects registered to this publisher.

=head2 C<first_topic>

Peform a L<first()|List::Util> operation on L<topics|/ATTRIBUTES/topics>.

=head2 C<get_topic>

Given a TopicName, returns a Topic object if found, undefined otherwise.

=head2 C<publish>

Takes a L<Black::Board::Types/TYPES/Topic> or L<Black::Board::Types/TYPES/TopicName> and a
L<Black::Board::Types/TYPES/Message>. The message is dispatched to the
subscribers of the topics. The final message returned by the subscriber is
returned.

=head1 AUTHOR

Scott Beck <scottbeck@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <scottbeck@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

