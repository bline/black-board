use MooseX::Declare;
class Black::Board::Trait::TopicNames {
    use Black::Board::Types qw( TopicNameList );

=attr topic_names

=method has_topics

=method add_topic

=method topic_list

=cut

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

