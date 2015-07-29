#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 19;
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

note 'inn';
{
    $t->app->routes->post("/test/inn")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('inn0')->inn,               'inn0 валидация';
        ok $v->has_error('inn0'),                   'inn0 ошибка';
        is $v->param('inn0'), undef,                'inn0 пустая строка';

        ok $v->required('inn1')->inn,               'inn1 валидация';
        ok $v->has_error('inn1'),                   'inn1 ошибка';
        is $v->param('inn1'), undef,                'inn1 значение неверное';

        ok $v->required('inn2')->inn,               'inn2 валидация';
        ok ! $v->has_error('inn2'),                 'inn2 ошибки нет';
        is $v->param('inn2'), '7804337423',         'inn2 длинна 10';

        ok $v->required('inn3')->inn,               'inn3 валидация';
        ok ! $v->has_error('inn3'),                 'inn3 ошибки нет';
        is $v->param('inn3'), '110102185800',       'inn3 длинна 12';

        ok $v->required('inn4')->inn,               'inn4 валидация';
        ok $v->has_error('inn4'),                   'inn4 ошибка';
        is $v->param('inn4'), undef,                'inn4 значение неверное';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/inn", form => {
        inn0    => '',
        inn1    => 'aaa111bbb222 ccc333',
        inn2    => ' 7804337423 ',
        inn3    => ' 110102185800  ',
        inn4    => '1101021858002',
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

