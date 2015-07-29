#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 22;
use Encode qw(decode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::DR::Validator';
}

{
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my ($self) = @_;
        $self->plugin('DR::I18n');
        $self->plugin('DR::Validator');
    }
    1;
}

my $t = Test::Mojo->new('MyApp');
ok $t, 'Test Mojo created';

note 'uuid';
{
    $t->app->routes->post("/test/uuid")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('uuid0')->uuid,                 'uuid0 валидация';
        ok $v->has_error('uuid0'),                      'uuid0 ошибка';
        is $v->param('uuid0'), undef,                   'uuid0 пустая строка';

        ok $v->required('uuid1')->uuid,                 'uuid1 валидация';
        ok ! $v->has_error('uuid1'),                    'uuid1 ошибки нет';
        is $v->param('uuid1'), '11122233344455566677788899900011',
                                                        'uuid1 значение';

        ok $v->required('uuid2')->uuid,                 'uuid2 валидация';
        ok ! $v->has_error('uuid2'),                    'uuid2 ошибки нет';
        is $v->param('uuid2'), '11122233344455566677788899900011',
                                                        'uuid2 значение';

        ok $v->required('uuid3')->uuid,         'uuid3 валидация';
        ok $v->has_error('uuid3'),              'uuid3 ошибка';
        is $v->param('uuid3'), undef,           'uuid3 невалидные символы';

        ok $v->required('uuid4')->uuid,         'uuid4 валидация';
        ok ! $v->has_error('uuid4'),            'uuid4 ошибки нет';
        is $v->param('uuid4'), '550e8400-e29b-41d4-a716-446655440000',
                                                'uuid4 значение';

        ok $v->required('uuid5')->uuid, 'uuid5 валидация';
        ok ! $v->has_error('uuid5'),    'uuid5 ошибки нет';
        is $v->param('uuid5'), '01234567890abcdefabcdef012345678',
                                        'uuid5 значение в нижнем регистре';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/uuid", form => {
        uuid0    => '',
        uuid1    => '11122233344455566677788899900011',
        uuid2    => ' 11122233344455566677788899900011 ',
        uuid3    => '1112223334445556667778889990001ZZ',
        uuid4    => '550e8400-e29b-41d4-a716-446655440000',
        uuid5    => '01234567890abcdefABCDEF012345678',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

