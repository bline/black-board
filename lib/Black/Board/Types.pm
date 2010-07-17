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
        TopicNameList
    )];

=head2 C<Publisher>

L<Black::Board::Publisher> class type.

=cut

    class_type Publisher, { class => 'Black::Board::Publisher' };
    coerce Publisher,
        from HashRef,
            via { Black::Board::Publisher->new( %{ $_[0] } ) };

=head2 C<Message>

L<Black::Board::Message> role type.

=cut

    role_type Message, { role => 'Black::Board::Message' };

=head2 C<MessageList>

C<ArrayRef> of L</TYPES/Message> types.

=cut

    subtype MessageList,
        as ArrayRef[Message];

=head2 C<MessageSimple>

L<Black::Board::Message::Simple> class type.

=cut

    class_type MessageSimple, { class => 'Black::Board::Message::Simple' };
    coerce MessageSimple,
        from HashRef,
            via { Black::Board::Message::Simple->new( %{ $_[0] } ) };

=head2 C<Subscriber>

L<Black::Board::Subscriber> class type.

=cut

    class_type Subscriber, { class => 'Black::Board::Subscriber' };

=head2 C<SubscriberList>

C<ArrayRef> of L</TYPES/Subscriber> types.

=cut

    subtype SubscriberList,
        as ArrayRef[Subscriber];

=head2 C<Topic>

L<Black::Board::Topic> class type.

=cut

    class_type Topic, { class => 'Black::Board::Topic' };

=head2 C<TopicList>

C<ArrayRef> of L</TYPES/Topic> types.

=cut

    subtype TopicList,
        as ArrayRef[Topic];
    coerce TopicList,
        from HashRef[Topic],
            via { [ values %{ $_[0] } ] };

=head2 C<TopicName>

A C<Str> which matches C<[\w:-]+>.

=cut

    subtype TopicName,
        as Str,
        where { /\A[\w:-]+\z/ },
        message { "topic names must match [\\w:-]+" };

=head2 C<TopicNameList>

An C<ArrayRef> of C<TopicName> types.

=cut

    subtype TopicNameList,
        as ArrayRef[TopicName];
    coerce TopicNameList,
        from TopicName,
            via { [ $_[0] ] };
    coerce TopicNameList,
        from TopicList,
            via { [ map { $_->name } @{ $_[0] } ] };
    coerce TopicNameList,
        from Topic,
            via { [  $_[0]->name  ] };
}

1;
