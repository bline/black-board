use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: exports types for L<Black::Board>

=head1 SYNOPSIS

    use Black::Board::Types qw(
        Publisher

        Message
        MessageList

        Subscriber
        SubscriberList

        Topic
        TopicList


        TopicName
        TopicNameList
    );

=head1 DESCRIPTION

Exports the types used within L<Black::Board>.

=head1 TYPES

=cut

class Black::Board::Types {
    use Moose::Util::TypeConstraints;
    use MooseX::Types::Moose qw( Str ArrayRef HashRef );
    use MooseX::Types -declare => [qw(
        Publisher

        Message
        MessageList

        MessageSimple

        Subscriber
        SubscriberList

        Topic
        TopicList

        TopicName
    )];

=head2 C<Publisher>

L<Black::Board::Publisher> class type.

=cut

    class_type Publisher, { class => 'Black::Board::Publisher' };
    coerce Publisher,
        from HashRef,
            via { Black::Board->PublisherClass->new( %{ $_[0] } ) };

=head2 C<Message>

L<Black::Board::Message> role type.

=cut

    class_type Message, { class => 'Black::Board::Message' };
    coerce Message,
        from HashRef,
            via { Black::Board::Message->new( %{ $_[0] } ) };

=head2 C<MessageList>

C<ArrayRef> of L</TYPES/Message> types.

=cut

    subtype MessageList,
        as ArrayRef[Message];


=head2 C<Subscriber>

L<Black::Board::Subscriber> class type.

=cut

    class_type Subscriber, { class => 'Black::Board::Subscriber' };

=head2 C<SubscriberList>

C<ArrayRef> of L</TYPES/Subscriber> types.

=cut

    subtype SubscriberList,
        as ArrayRef[Subscriber];

=head2 C<TopicName>

A C<Str> which matches C<[\w:-]+>.

=cut

    subtype TopicName,
        as Str,
        where { /\A[\w:-]+\z/ },
        message { "topic names must match [\\w:-]+" };

=head2 C<Topic>

L<Black::Board::Topic> class type.

=cut

    class_type Topic, { class => 'Black::Board::Topic' };
    coerce Topic,
        from TopicName,
            via { Black::Board->Publisher->get_topic( $_[0] ) };

=head2 C<TopicList>

C<ArrayRef> of L</TYPES/Topic> types.

=cut

    subtype TopicList,
        as ArrayRef[Topic];
    coerce TopicList,
        from HashRef[Topic],
            via { [ values %{ $_[0] } ] };

}

1;

