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


    method remove_topic( TopicName $topic_name ) {
        my $topics = $self->topics;
        for ( my $i = 0; $i < $topics->count; ++$i ) {
            if ( $topics->get( $i )->name eq $topic_name ) {
                $topics->delete( $i );
                last;
            }
        }
    }


    method get_topic( TopicName $topic_name ) {
        return $self->first_topic( sub { $_->name eq $topic } );
    }


    method publish( TopicName|Topic :$topic, Message :$message ) {

        # turn TopicName into Topic
        unless (blessed $topic ) {
            my $topic_copy = $topic;

            $topic = $self->get_topic( $topic );

            confess "Invalid topic $topic_copy"
                unless defined $topic;
        }

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

Black::Board::Publisher - Publisher object for L<Black::Board>, dispatches to Topic subscribers

=head1 VERSION

version 0.0001

=head1 DESCRIPTION

This is the Publisher object for L<Black::Board>. It contains a list of
L<Topic|Black::Board::Topic> objects. The C<Publisher> object takes care of
this list of C<Topic> objects, it handles dispatching to them and provides
methods to add and remove topics.

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

=head2 C<remove_topic>

Only argument is a L<Black::Board::Types/TYPES/TopicName>. Removes the given
TopicName from this publishers list of topics.

=head2 C<get_topic>

Given a TopicName, returns a Topic object if found, undefined otherwise.

=head2 C<publish>

Takes a L<Black::Board::Types/TYPES/Topic> or L<Black::Board::Types/TYPES/TopicName> and a
L<Black::Board::Types/TYPES/Message>. The message is dispatched to the
subscribers of the topics. The final message returned by the subscriber is
returned.

=head1 SEE ALSO

=over 4

=item *

L<Black::Board::Message> - objects being dispatched to L<Topics|Black::Board::Topic>.

=item *

L<Black::Board::Topic> - topic objects contained and dispatched to by a Publisher

=item *

L<Black::Board> - provides sugar syntax to a singleton Publisher

=back

=head1 AUTHOR

Scott Beck <scottbeck@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <scottbeck@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

