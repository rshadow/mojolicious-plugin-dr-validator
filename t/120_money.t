#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 28;
use Encode qw(decode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::DR::Validator';
    use_ok 'DR::Money';
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

note 'money';
{
    $t->app->routes->post("/test/money")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('money0')->money,       'money0 валидация';
        ok ! $v->has_error('money0'),           'money0 ошибки нет';
        is $v->param('money0'), 0,              'money0 значение 0';
        isa_ok $v->param('money0'), 'DR::Money','money0 объект';

        ok $v->required('money1')->money,       'money1 валидация';
        ok ! $v->has_error('money1'),           'money1 ошибки нет';
        is $v->param('money1'), 111.22,         'money1 дробь до сотых';
        isa_ok $v->param('money1'), 'DR::Money','money1 объект';

        ok $v->required('money2')->money,       'money2 валидация';
        ok ! $v->has_error('money2'),           'money2 ошибки нет';
        is $v->param('money2'), 111.2,          'money2 дробь до десятых';
        isa_ok $v->param('money2'), 'DR::Money','money2 объект';

        ok $v->required('money3')->money,       'money3 валидация';
        ok ! $v->has_error('money3'),           'money3 ошибки нет';
        is $v->param('money3'), 111,            'money3 без дробной части';
        isa_ok $v->param('money3'), 'DR::Money','money3 объект';

        ok $v->required('money4')->money,       'money4 валидация';
        ok ! $v->has_error('money4'),           'money4 ошибки нет';
        is $v->param('money4'), 111,            'money4 дробная часть = 0';
        isa_ok $v->param('money4'), 'DR::Money','money4 объект';

        ok $v->required('money5')->money,       'money5 валидация';
        ok $v->has_error('money5'),             'money5 ошибка';
        is $v->param('money5'), undef,          'money5 длинная дробная часть';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/money", form => {

        # numeric не проверяем

        money0    => 0,
        money1    => 111.22,
        money2    => 111.2,
        money3    => 111.,
        money4    => 111.0,
        money5    => 111.222,
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

