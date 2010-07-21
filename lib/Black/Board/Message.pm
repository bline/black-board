use strict;
use warnings;
use MooseX::Declare;

#ABSTRACT: C<param> based Message for L<Bread::Board>

class Black::Board::Message
    with MooseX::Param
    with Black::Board::Trait::Traversable
{
    use Method::Signatures::Simple name => 'imethod';


    has 'bubble' => (
        is => 'rw',
        isa => 'Bool',
        default => 1,
    );


    has 'with_meta' => (
        is  => 'ro',
        isa => 'Object',
    );


    imethod cancel_bubble() {
        $self->bubble( 0 );
        return $self;
    }


    imethod merge_params( $params ) {
        $self->param( %$params );
        return $self;
    }

}


1;


__END__
=pod

=head1 NAME

Black::Board::Message - C<param> based Message for L<Bread::Board>

=head1 VERSION

version 0.0001

=head1 ATTRIBUTES

=head2 C<bubble>

L<Black::Board::Subscriber> uses this flag to know if it should continue
dispatching the current subscription message.

=head2 C<with_meta>

The meta object from the class the created this C<Message> object. Required.

=head1 METHODS

=head2 C<cancel_bubble>

This makes sense from the context of a L<Black::Board::Subscriber> subscription
callback. It allows you to cancel the current chain of subscriber dispatch.
This is usually done in end-point* subscribers. This object is returned with bubble
set to false.

* An example of an end-point is the subscriber in a C<LogDispatch> subscription
chain that dispatches to the log object. 

=head2 C<merge_params>

Merges C<HashRef> passed in with current C<<Message->params>>, the C<HashRef>
taking presidence.

Returns self.

=head1 SEE ALSO

=over 4

=item *

L<Black::Board::Publisher> - publishes Messages to L<Topics|Black::Board::Topic>

=item *

L<Black::Board::Topic> - delivers Messages to L<Subscribers|Black::Board::Subscriber>

=item *

L<Black::Board::Subscriber> - receives a Message

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

