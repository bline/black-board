use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: exports types for L<Black::Board>


class Black::Board::Types {
    use Moose::Util::TypeConstraints;
    use MooseX::Types::Moose qw( Str ArrayRef HashRef CodeRef );
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

        CodeList
        NamedCodeList
    )];


    subtype CodeList,
        as ArrayRef[CodeRef];
    coerce CodeList,
        from CodeRef,
            via { [ $_[0] ] };
    subtype NamedCodeList,
        as HashRef[ArrayRef[CodeRef]];
    coerce NamedCodeList,
        from HashRef[ArrayRef|CodeRef],
            via {
                my $hr = shift;
                +{
                    map { $_ => [
                        ref( $hr->{$_} ) eq 'ARRAY'
                            ? @{ $hr->{$_} }
                            : $hr->{$_}
                    ] } keys %$hr
                }
            };


    class_type Publisher, { class => 'Black::Board::Publisher' };
    coerce Publisher,
        from HashRef,
            via { Black::Board->PublisherClass->new( %{ $_[0] } ) };


    class_type Message, { class => 'Black::Board::Message' };
    coerce Message,
        from HashRef,
            via { Black::Board::Message->new( %{ $_[0] } ) };


    subtype MessageList,
        as ArrayRef[Message];



    class_type Subscriber, { class => 'Black::Board::Subscriber' };


    subtype SubscriberList,
        as ArrayRef[Subscriber];


    subtype TopicName,
        as Str,
        where { /\A[\w:-]+\z/ },
        message { "topic names must match [\\w:-]+" };


    class_type Topic, { class => 'Black::Board::Topic' };
    coerce Topic,
        from TopicName,
            via { Black::Board->Publisher->get_topic( $_[0] ) };


    subtype TopicList,
        as ArrayRef[Topic];
    coerce TopicList,
        from HashRef[Topic],
            via { [ values %{ $_[0] } ] };

}

1;


__END__
=pod

=head1 NAME

Black::Board::Types - exports types for L<Black::Board>

=head1 VERSION

version 0.0001

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

=head2 C<CodeList>

An C<ArrayRef> of C<CodeRef> objects with coercion. Used in L<Black::Board> for
C<subscriber> and C<initializer> arguments to C<topic()>.

=head2 C<Publisher>

L<Black::Board::Publisher> class type.

=head2 C<Message>

L<Black::Board::Message> role type.

=head2 C<MessageList>

C<ArrayRef> of L</TYPES/Message> types.

=head2 C<Subscriber>

L<Black::Board::Subscriber> class type.

=head2 C<SubscriberList>

C<ArrayRef> of L</TYPES/Subscriber> types.

=head2 C<TopicName>

A C<Str> which matches C<[\w:-]+>.

=head2 C<Topic>

L<Black::Board::Topic> class type.

=head2 C<TopicList>

C<ArrayRef> of L</TYPES/Topic> types.

=head1 AUTHOR

Scott Beck <sabeck@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <sabeck@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

