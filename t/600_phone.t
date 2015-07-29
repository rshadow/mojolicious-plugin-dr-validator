#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 40;
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

note 'phone';
{
    $t->app->routes->post("/test/phone")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('phone1')->phone,           'phone1 валидация';
        ok ! $v->has_error('phone1'),               'phone1 ошибки нет';
        is $v->param('phone1'), '+71234567890',     'phone1 телефон';

        ok $v->required('phone2')->phone,           'phone2 валидация';
        ok ! $v->has_error('phone2'),               'phone2 ошибки нет';
        is $v->param('phone2'), '+71234567890',     'phone2 "+" добавлен';

        ok $v->required('phone3')->phone,           'phone3 валидация';
        ok $v->has_error('phone3'),                 'phone3 ошибка';
        is $v->param('phone3'), undef,              'phone3 слишком короткий';

        ok $v->required('phone4')->phone,           'phone4 валидация';
        ok $v->has_error('phone4'),                 'phone4 ошибка';
        is $v->param('phone4'), undef,              'phone4 пустая строка';

        ok $v->required('phone5')->phone,           'phone5 валидация';
        ok $v->has_error('phone5'),                 'phone5 ошибка';
        is $v->param('phone5'), undef,              'phone5 не телефон';

        ok $v->required('phone6')->phone,           'phone6 валидация';
        ok ! $v->has_error('phone6'),               'phone6 ошибки нет';
        is $v->param('phone6'), '+71234567890w1234','phone6 с добавочным';

        ok $v->required('phone7')->phone,           'phone7 валидация';
        ok ! $v->has_error('phone7'),               'phone7 ошибки нет';
        is $v->param('phone7'), '+71234567890',     'phone7 с разметкой';

        ok $v->required('phone8')->phone,           'phone8 валидация';
        ok ! $v->has_error('phone8'),               'phone8 ошибки нет';
        is $v->param('phone8'), '+71234567890w1234','phone8 с добавочным ","';

        ok $v->required('phone9')->phone,           'phone9 валидация';
        ok ! $v->has_error('phone9'),               'phone9 ошибки нет';
        is $v->param('phone9'), '+71234567890w1234','phone9 с добавочным "."';

        ok $v->required('phone10')->phone,              'phone10 валидация';
        ok ! $v->has_error('phone10'),                  'phone10 ошибки нет';
        is $v->param('phone10'), '+71234567890w1234',
            'phone10 с добавочным описанием';

        ok $v->required('phone11')->phone,          'phone11 валидация';
        ok $v->has_error('phone11'),                'phone11 ошибка';
        is $v->param('phone11'), undef,             'phone11 слишком длинный';

        ok $v->required('phone12')->phone,          'phone12 валидация';
        ok ! $v->has_error('phone12'),              'phone12 ошибки нет';
        is $v->param('phone12'), '+71234567890p12', 'phone12 с паузой';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/phone", form => {
        phone1      => '+71234567890',
        phone2      => '71234567890',
        phone3      => '4567890',
        phone4      => '',
        phone5      => 'asddf ',
        phone6      => '+71234567890w1234',
        phone7      => ' +7 (123) 456-78-90 ',
        phone8      => '+71234567890,1234',
        phone9      => '+71234567890.1234',
        phone10     => '+71234567890, доб. 1234',
        phone11     => '+712345678901234567891234567',
        phone12      => '+71234567890p12',
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

