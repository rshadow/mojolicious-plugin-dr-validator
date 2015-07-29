#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 37;
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

note 'int';
{
    $t->app->routes->post("/test/int")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('int0')->int,       'int0 валидация';
        ok ! $v->has_error('int0'),         'int0 ошибки нет';
        is $v->param('int0'), 0,            'int0 значение 0';

        ok $v->required('int1')->int,       'int1 валидация';
        ok ! $v->has_error('int1'),         'int1 ошибки нет';
        is $v->param('int1'), 111,          'int1 значение число';

        ok $v->required('int2')->int,       'int2 валидация';
        ok ! $v->has_error('int2'),         'int2 ошибки нет';
        is $v->param('int2'), 222,          'int2 значение получено из строки';

        ok $v->required('int3')->int,       'int3 валидация';
        ok ! $v->has_error('int3'),         'int3 ошибки нет';
        is $v->param('int3'), 333,          'int3 значение получено из строки';

        ok $v->required('int4')->int,       'int4 валидация';
        ok $v->has_error('int4'),           'int4 ошибка';
        is $v->param('int4'), undef,        'int4 строка без чисел';

        ok $v->required('int5')->int,       'int5 валидация';
        ok $v->has_error('int5'),           'int5 ошибка';
        is $v->param('int5'), undef,        'int5 пустая строка';

        ok $v->required('int6')->int,       'int6 валидация';
        ok ! $v->has_error('int6'),         'int6 ошибки нет';
        is $v->param('int6'), 333,          'int6 цифры с пробелами';

        ok $v->required('int7')->int,       'int7 валидация';
        ok ! $v->has_error('int7'),         'int7 ошибки нет';
        is $v->param('int7'), -333,         'int7 отрицательное число';

        ok $v->required('int8')->int,       'int8 валидация';
        ok ! $v->has_error('int8'),         'int8 ошибки нет';
        is $v->param('int8'), 333,          'int8 положительное число';

        ok $v->required('int9')->int,       'int9 валидация';
        ok ! $v->has_error('int9'),         'int9 ошибки нет';
        is $v->param('int9'), 111,          'int9 дробь преобразована к целому';

        ok $v->required('int10')->int,      'int10 валидация';
        ok $v->has_error('int10'),          'int10 ошибка';
        is $v->param('int10'), undef,       'int10 :id';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/int", form => {

        int0    => 0,
        int1    => 111,
        int2    => '222aaa',
        int3    => 'bbb333bbb',
        int4    => 'ccc',
        int5    => '',
        int6    => ' 333 ',
        int7    => ' -333 ',
        int8    => ' +333 ',
        int9    => 111.222,
        int10   => ':id',
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

