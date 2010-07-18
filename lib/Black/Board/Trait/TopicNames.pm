use MooseX::Declare;
class Black::Board::Trait::TopicNames {
    use Black::Board::Types qw( TopicNameList );


    has 'topic_names' => (
        is      => 'rw',
        isa     => TopicNameList,
        traits  => [ 'Array' ],
        coerce  => 1,
        handles => {
            has_topics => 'count',
            add_topic  => 'push',
            topic_list => 'elements',
        }
    );
}

1;


__END__
=pod

=head1 NAME

Black::Board::Trait::TopicNames

=head1 VERSION

version 0.0001

=head1 ATTRIBUTES

=head2 topic_names

=head1 METHODS

=head2 has_topics

=head2 add_topic

=head2 topic_list

=head1 AUTHOR

Scott Beck <scottbeck@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <scottbeck@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

=over 4

=item *

L<Black::Board>

=back

=cut

